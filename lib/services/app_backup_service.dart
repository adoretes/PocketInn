import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'app_data_service.dart';
import 'chat_database_service.dart';
import 'font_service.dart';
import 'remote_backup_settings_service.dart';
import 'storage_service.dart';

enum RestoreStep {
  validating,
  cleaning,
  writingFiles,
  migrating,
  reloading,
}

class AppBackupService {
  AppBackupService._();

  static final AppBackupService instance = AppBackupService._();

  static const int _formatVersion = 1;
  static const String _manifestPath = 'manifest.json';
  static const String _preferencesPath = 'preferences.json';
  static const String _dataRoot = 'data';
  static const String _databaseRoot = 'database';
  static const String _fontsRoot = 'fonts';
  static const String remoteBackupFileName = 'pocketinn-latest.zip';
  static const int maxArchiveSizeBytes = 1024 * 1024 * 1024;
  static const int _maxArchiveEntries = 5000;
  static const int _maxArchiveEntrySizeBytes = 1024 * 1024 * 1024;
  static const int _maxArchiveUncompressedSizeBytes = 4 * 1024 * 1024 * 1024;

  Future<String?> exportBackup() async {
    final defaultName = 'pocketinn-backup-${_dateStamp()}.zip';
    final backupBytes = await buildBackupArchiveBytes();

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出备份',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (outputPath == null || outputPath.isEmpty) {
        return null;
      }

      await File(outputPath).writeAsBytes(backupBytes, flush: true);
      return outputPath;
    }

    return FilePicker.platform.saveFile(
      dialogTitle: '导出备份',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: backupBytes,
    );
  }

  Future<bool> restoreBackupFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: '恢复备份',
    );
    if (result == null || result.files.isEmpty) {
      return false;
    }

    final filePath = result.files.first.path;
    if (filePath == null || filePath.isEmpty) {
      return false;
    }

    await restoreBackupArchive(filePath);
    return true;
  }

  Future<void> restoreBackupArchive(
    String archivePath, {
    void Function(RestoreStep step)? onStep,
  }) async {
    final archiveFile = File(archivePath);
    if (await archiveFile.length() > maxArchiveSizeBytes) {
      throw const FormatException('备份文件过大，最大支持 1 GB');
    }
    final stream = InputFileStream(archivePath);
    try {
      final archive = ZipDecoder().decodeStream(stream);
      await _restoreBackupArchive(archive, onStep: onStep);
    } finally {
      stream.closeSync();
    }
  }

  Future<void> restoreBackupArchiveBytes(
    Uint8List bytes, {
    void Function(RestoreStep step)? onStep,
  }) async {
    if (bytes.length > maxArchiveSizeBytes) {
      throw const FormatException('备份文件过大，最大支持 1 GB');
    }
    final archive = ZipDecoder().decodeBytes(bytes);
    await _restoreBackupArchive(archive, onStep: onStep);
  }

  Future<void> _restoreBackupArchive(
    Archive archive, {
    void Function(RestoreStep step)? onStep,
  }) async {
    onStep?.call(RestoreStep.validating);
    _validateArchive(archive);
    final manifest = _readJsonFileFromArchive(
      archive,
      _manifestPath,
      errorMessage: '备份缺少 manifest.json',
    );
    final version = manifest['formatVersion'] as int?;
    if (version != _formatVersion) {
      throw FormatException('不支持的备份版本: ${version ?? 'unknown'}');
    }

    final preferences = _readJsonFileFromArchive(
      archive,
      _preferencesPath,
      errorMessage: '备份缺少 preferences.json',
    );

    // 远程备份连接信息属于设备本地设置，不随备份覆盖。
    final remoteBackupSettings = await RemoteBackupSettingsService.instance
        .load();
    preferences.remove(RemoteBackupSettingsService.settingsKey);

    onStep?.call(RestoreStep.cleaning);
    await ChatDatabaseService.instance.deleteDatabaseFiles();
    await StorageService.instance.clearAllData();

    onStep?.call(RestoreStep.writingFiles);
    final dataDir = StorageService.instance.dataDir;
    for (final file in archive.files) {
      if (!file.isFile) {
        continue;
      }
      final archivePath = p.posix.normalize(file.name);
      if (archivePath == _manifestPath || archivePath == _preferencesPath) {
        continue;
      }

      if (p.posix.isWithin(_dataRoot, archivePath)) {
        final relativePath = p.posix.relative(archivePath, from: _dataRoot);
        final targetFile = File(p.join(dataDir, relativePath));
        await targetFile.parent.create(recursive: true);
        _writeArchiveFile(file, targetFile);
        continue;
      }

      if (p.posix.isWithin(_databaseRoot, archivePath)) {
        final relativePath = p.posix.relative(archivePath, from: _databaseRoot);
        final targetFile = File(p.join(dataDir, relativePath));
        await targetFile.parent.create(recursive: true);
        _writeArchiveFile(file, targetFile);
        continue;
      }

      if (p.posix.isWithin(_fontsRoot, archivePath)) {
        final relativePath = p.posix.relative(archivePath, from: _fontsRoot);
        final fontsDir = await FontService.instance.fontsDir;
        final targetFile = File(p.join(fontsDir, relativePath));
        await targetFile.parent.create(recursive: true);
        _writeArchiveFile(file, targetFile);
      }
    }

    onStep?.call(RestoreStep.migrating);
    await _migrateRestoredData(dataDir);
    _migrateRestoredPreferences(preferences);
    await StorageService.instance.importPreferences(preferences);
    await RemoteBackupSettingsService.instance.save(remoteBackupSettings);

    onStep?.call(RestoreStep.reloading);
    await AppDataService.instance.reloadAppState();
  }

  Future<Uint8List> buildBackupArchiveBytes() async {
    final archive = Archive();
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'formatVersion': _formatVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'format': 'zip',
      }),
    );
    archive.add(
      ArchiveFile(_manifestPath, manifestBytes.length, manifestBytes),
    );

    final preferences = StorageService.instance.exportPreferences()
      ..remove(RemoteBackupSettingsService.settingsKey);
    final preferencesBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(preferences),
    );
    archive.add(
      ArchiveFile(_preferencesPath, preferencesBytes.length, preferencesBytes),
    );

    await _addDataFilesToArchive(archive);
    await _addFontFilesToArchive(archive);
    return ZipEncoder().encodeBytes(archive);
  }

  Future<void> _addDataFilesToArchive(Archive archive) async {
    final dataDir = StorageService.instance.dataDir;
    final root = Directory(dataDir);
    if (await root.exists()) {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }
        final relativePath = p.posix.normalize(
          p.relative(entity.path, from: dataDir).replaceAll('\\', '/'),
        );
        final bytes = await entity.readAsBytes();
        archive.add(
          ArchiveFile('$_dataRoot/$relativePath', bytes.length, bytes),
        );
      }
    }
  }

  Future<void> _addFontFilesToArchive(Archive archive) async {
    final fontsDir = await FontService.instance.fontsDir;
    final root = Directory(fontsDir);
    if (await root.exists()) {
      await for (final entity in root.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }
        final bytes = await entity.readAsBytes();
        archive.add(
          ArchiveFile(
            '$_fontsRoot/${p.basename(entity.path)}',
            bytes.length,
            bytes,
          ),
        );
      }
    }
  }

  String _dateStamp() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}$month$day';
  }

  /// 恢复后迁移旧版角色卡中的绝对路径为相对路径
  Future<void> _migrateRestoredData(String dataDir) async {
    await _migrateCharacterIndex(dataDir);
    await _migrateCharacterCards(dataDir);
  }

  Future<void> _migrateCharacterIndex(String dataDir) async {
    final file = File(p.join(dataDir, 'characters_index.json'));
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! Map<String, dynamic>) return;
      final characters = data['characters'] as List<dynamic>?;
      if (characters == null) return;

      var changed = false;
      for (final item in characters) {
        if (item is! Map<String, dynamic>) continue;
        final rel = _relativizePath(item, 'thumbnailPath', dataDir);
        if (rel) changed = true;
      }
      if (changed) {
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(data),
        );
      }
    } on Object catch (error, stack) {
      // 迁移失败不应中断恢复主流程，仅记录日志便于事后排查。
      debugPrint(
        'app_backup_service: _migrateCharacterIndex failed: '
        '$error\n$stack',
      );
    }
  }

  Future<void> _migrateCharacterCards(String dataDir) async {
    final dir = Directory(p.join(dataDir, 'characters', 'data'));
    if (!await dir.exists()) return;

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final content = await entity.readAsString();
        final data = jsonDecode(content);
        if (data is! Map<String, dynamic>) continue;

        var changed = false;
        if (_relativizePath(data, 'originalImagePath', dataDir)) changed = true;
        if (_relativizePath(data, 'thumbnailPath', dataDir)) changed = true;
        if (changed) {
          await entity.writeAsString(
            const JsonEncoder.withIndent('  ').convert(data),
          );
        }
      } on Object catch (error, stack) {
        // 单个角色卡迁移失败不应影响其他卡片，仅记录日志。
        debugPrint(
          'app_backup_service: _migrateCharacterCards failed for '
          '${entity.path}: $error\n$stack',
        );
      }
    }
  }

  /// 将 Map 中指定 key 的路径从绝对路径转为相对路径
  /// 旧格式：/data/user/0/.../pocket_inn_data/characters/images/xxx.png
  /// 新格式：characters/images/xxx.png
  bool _relativizePath(Map<String, dynamic> data, String key, String dataDir) {
    final path = data[key] as String?;
    if (path == null || path.isEmpty) return false;

    final idx = path.indexOf('/pocket_inn_data/');
    if (idx < 0) return false;

    final relative = path.substring(idx + '/pocket_inn_data/'.length);
    if (relative == path) return false;

    data[key] = relative;
    return true;
  }

  /// 恢复时对旧版 preferences 做数据迁移
  static const String _keyCustomFontFilePath = 'app_custom_font_file_path';

  void _migrateRestoredPreferences(Map<String, dynamic> preferences) {
    final fontPath = preferences[_keyCustomFontFilePath] as String?;
    if (fontPath != null && fontPath.isNotEmpty) {
      final fileName = p.basename(fontPath.replaceAll('\\', '/'));
      if (fileName != fontPath) {
        preferences[_keyCustomFontFilePath] = fileName;
      }
    }
  }

  Map<String, dynamic> _readJsonFileFromArchive(
    Archive archive,
    String path, {
    required String errorMessage,
  }) {
    final file = archive.findFile(path);
    if (file == null || !file.isFile) {
      throw FormatException(errorMessage);
    }
    final decoded = jsonDecode(utf8.decode(_archiveFileBytes(file)));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份文件格式不正确');
    }
    return decoded;
  }

  List<int> _archiveFileBytes(ArchiveFile file) {
    return file.readBytes() ?? const <int>[];
  }

  void _writeArchiveFile(ArchiveFile file, File targetFile) {
    final output = OutputFileStream(targetFile.path);
    try {
      file.writeContent(output);
    } finally {
      output.closeSync();
    }
  }

  void _validateArchive(Archive archive) {
    if (archive.files.length > _maxArchiveEntries) {
      throw const FormatException('备份包含过多文件');
    }

    var totalSize = 0;
    for (final file in archive.files) {
      if (file.isSymbolicLink) {
        throw const FormatException('备份不能包含符号链接');
      }
      if (!file.isFile) {
        continue;
      }
      final path = p.posix.normalize(file.name);
      if (path.startsWith('/') || path == '..' || path.startsWith('../')) {
        throw const FormatException('备份包含非法文件路径');
      }
      if (file.size < 0 || file.size > _maxArchiveEntrySizeBytes) {
        throw const FormatException('备份包含过大的文件');
      }
      totalSize += file.size;
      if (totalSize > _maxArchiveUncompressedSizeBytes) {
        throw const FormatException('备份解压后的内容过大');
      }
    }
  }
}
