import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'app_data_service.dart';
import 'chat_database_service.dart';
import 'storage_service.dart';

class AppBackupService {
  AppBackupService._();

  static final AppBackupService instance = AppBackupService._();

  static const int _formatVersion = 1;
  static const String _manifestPath = 'manifest.json';
  static const String _preferencesPath = 'preferences.json';
  static const String _dataRoot = 'data';
  static const String _databaseRoot = 'database';

  Future<String?> exportBackup() async {
    final defaultName = 'pocketinn-backup-${_dateStamp()}.zip';
    final backupBytes = await _buildBackupArchiveBytes();

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

  Future<void> restoreBackupArchive(String archivePath) async {
    final archive = ZipDecoder().decodeStream(InputFileStream(archivePath));
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

    await ChatDatabaseService.instance.deleteDatabaseFiles();
    await StorageService.instance.clearAllData();

    final dataDir = StorageService.instance.dataDir;
    final appDir = Directory(dataDir).parent.path;
    for (final file in archive.files) {
      if (!file.isFile) {
        continue;
      }
      final archivePath = p.posix.normalize(file.name);
      if (archivePath == _manifestPath || archivePath == _preferencesPath) {
        continue;
      }

      final bytes = _archiveFileBytes(file);
      if (p.posix.isWithin(_dataRoot, archivePath)) {
        final relativePath = p.posix.relative(archivePath, from: _dataRoot);
        final targetFile = File(p.join(dataDir, relativePath));
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(bytes, flush: true);
        continue;
      }

      if (p.posix.isWithin(_databaseRoot, archivePath)) {
        final relativePath = p.posix.relative(archivePath, from: _databaseRoot);
        final targetFile = File(p.join(appDir, relativePath));
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(bytes, flush: true);
      }
    }

    await StorageService.instance.importPreferences(preferences);
    await AppDataService.instance.reloadAppState();
  }

  Future<Uint8List> _buildBackupArchiveBytes() async {
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

    final preferencesBytes = utf8.encode(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(StorageService.instance.exportPreferences()),
    );
    archive.add(
      ArchiveFile(_preferencesPath, preferencesBytes.length, preferencesBytes),
    );

    await _addDataFilesToArchive(archive);
    await _addDatabaseFilesToArchive(archive);
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

  Future<void> _addDatabaseFilesToArchive(Archive archive) async {
    final dbPath = ChatDatabaseService.instance.databasePath;
    if (dbPath != null && dbPath.isNotEmpty) {
      for (final path in [dbPath, '$dbPath-wal', '$dbPath-shm']) {
        final dbFile = File(path);
        if (!await dbFile.exists()) {
          continue;
        }
        final bytes = await dbFile.readAsBytes();
        archive.add(
          ArchiveFile(
            '$_databaseRoot/${p.basename(path)}',
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
}
