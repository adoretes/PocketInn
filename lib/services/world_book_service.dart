import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/world_book.dart';
import 'storage_service.dart';

/// 世界书服务
///
/// 负责世界书的持久化储存、导入导出和管理
class WorldBookService {
  WorldBookService._();

  static final WorldBookService instance = WorldBookService._();

  // 索引文件名
  static const String _indexFilename = 'world_books_index.json';

  // 世界书存储目录
  static const String _worldBooksDir = 'world_books';

  // 数据版本
  static const int _dataVersion = 1;

  late String _worldBooksPath;
  bool _initialized = false;

  /// 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;

    final storage = StorageService.instance;
    final dataDir = storage.dataDir;
    _worldBooksPath = '$dataDir/$_worldBooksDir';

    // 确保世界书目录存在
    final dir = Directory(_worldBooksPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _initialized = true;
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'WorldBookService 未初始化，请先调用 WorldBookService.instance.initialize()',
      );
    }
  }

  /// 加载所有世界书的索引信息
  Future<List<WorldBookIndexInfo>> loadAllIndexInfo() async {
    _checkInitialized();

    final storage = StorageService.instance;
    final data = await storage.readJsonMap(_indexFilename);

    if (data == null) {
      return [];
    }

    final version = data['version'] as int? ?? 1;
    if (version != _dataVersion) {
      // 未来可以在这里处理数据迁移
      return [];
    }

    final booksList = data['books'] as List<dynamic>?;
    if (booksList == null || booksList.isEmpty) {
      return [];
    }

    return booksList
        .map(
          (json) => WorldBookIndexInfo.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// 保存索引信息
  Future<void> _saveIndexInfo(List<WorldBookIndexInfo> infos) async {
    final storage = StorageService.instance;

    final data = {
      'version': _dataVersion,
      'books': infos.map((info) => info.toJson()).toList(),
    };

    await storage.writeJsonMap(_indexFilename, data);
  }

  /// 加载所有世界书（完整数据）
  Future<List<WorldBook>> loadAll() async {
    _checkInitialized();

    final infos = await loadAllIndexInfo();
    final books = <WorldBook>[];

    for (final info in infos) {
      final book = await loadById(info.id);
      if (book != null) {
        books.add(book);
      }
    }

    return books;
  }

  /// 根据 ID 加载世界书
  Future<WorldBook?> loadById(String id) async {
    _checkInitialized();

    final file = File('$_worldBooksPath/$id.json');
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return WorldBook.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 保存世界书
  Future<void> save(WorldBook book) async {
    _checkInitialized();

    // 保存完整数据到单独文件
    final file = File('$_worldBooksPath/${book.id}.json');
    final content = const JsonEncoder.withIndent('  ').convert(book.toJson());
    await file.writeAsString(content);

    // 更新索引
    final infos = await loadAllIndexInfo();
    final index = infos.indexWhere((info) => info.id == book.id);
    final newInfo = book.toIndexInfo();

    if (index >= 0) {
      infos[index] = newInfo;
    } else {
      infos.add(newInfo);
    }

    await _saveIndexInfo(infos);
  }

  /// 删除世界书
  Future<void> delete(String id) async {
    _checkInitialized();

    // 删除数据文件
    final file = File('$_worldBooksPath/$id.json');
    if (await file.exists()) {
      await file.delete();
    }

    // 更新索引
    final infos = await loadAllIndexInfo();
    infos.removeWhere((info) => info.id == id);
    await _saveIndexInfo(infos);
  }

  Future<void> clearAllData() async {
    _checkInitialized();

    await StorageService.instance.deleteJsonFile(_indexFilename);

    final dir = Directory(_worldBooksPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  /// 创建新的世界书
  Future<WorldBook> create({
    required String name,
    String description = '',
    int colorValue = 0xFF4B6CB7,
  }) async {
    final book = WorldBook(
      id: generateId(),
      name: name,
      description: description,
      colorValue: colorValue,
      entries: [],
      updatedAt: DateTime.now(),
    );

    await save(book);
    return book;
  }

  /// 生成唯一 ID
  String generateId() {
    return 'wb-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 生成条目唯一 ID
  String generateEntryId() {
    return 'entry-${DateTime.now().millisecondsSinceEpoch}';
  }

  // ==================== 导入导出功能 ====================

  /// 从文件导入世界书
  ///
  /// 返回导入的世界书，如果用户取消则返回 null
  Future<WorldBook?> importFromFile() async {
    _checkInitialized();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '选择世界书文件',
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final filePath = result.files.first.path;
    if (filePath == null) {
      return null;
    }

    try {
      final file = File(filePath);
      final content = await file.readAsString();

      // 从文件路径提取文件名（不含扩展名）作为世界书名称
      final fileName = result.files.first.name;
      final bookName = fileName.endsWith('.json')
          ? fileName.substring(0, fileName.length - 5)
          : fileName;

      // 尝试解析为 SillyTavern 格式
      final book = WorldBook.fromSillyTavernJson(content, name: bookName);

      // 生成新 ID 并保存
      final newBook = book.copyWith(
        id: generateId(),
        updatedAt: DateTime.now(),
      );

      await save(newBook);
      return newBook;
    } on FormatException catch (e) {
      throw ImportException('解析失败: ${e.message}');
    } catch (e) {
      throw ImportException('导入失败: $e');
    }
  }

  /// 从 JSON 字符串导入世界书
  Future<WorldBook> importFromJson(String jsonContent, {String? name}) async {
    _checkInitialized();

    try {
      final book = WorldBook.fromSillyTavernJson(jsonContent, name: name);

      final newBook = book.copyWith(
        id: generateId(),
        updatedAt: DateTime.now(),
      );

      await save(newBook);
      return newBook;
    } on FormatException catch (e) {
      throw ImportException('解析失败: ${e.message}');
    } catch (e) {
      throw ImportException('导入失败: $e');
    }
  }

  /// 导出世界书到文件
  ///
  /// 返回导出的文件路径，如果用户取消则返回 null
  Future<String?> exportToFile(WorldBook book) async {
    _checkInitialized();

    final defaultName = '${book.name}.json';
    final content = const JsonEncoder.withIndent(
      '    ',
    ).convert(book.toSillyTavernJson());

    String? outputPath;

    // 使用 saveFile 对话框
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出世界书',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        return null;
      }

      outputPath = result;
      final file = File(outputPath);
      await file.writeAsString(content);
    } else {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出世界书',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(content)),
      );
    }

    return outputPath;
  }

  /// 导出世界书为 JSON 字符串
  String exportToJson(WorldBook book) {
    return const JsonEncoder.withIndent(
      '    ',
    ).convert(book.toSillyTavernJson());
  }

  // ==================== 条目管理 ====================

  /// 添加条目到世界书
  Future<WorldBook> addEntry(String bookId, WorldBookEntry entry) async {
    final book = await loadById(bookId);
    if (book == null) {
      throw StateError('世界书不存在: $bookId');
    }

    final newEntries = [...book.entries, entry];
    final updatedBook = book.copyWith(
      entries: newEntries,
      updatedAt: DateTime.now(),
    );

    await save(updatedBook);
    return updatedBook;
  }

  /// 更新条目
  Future<WorldBook> updateEntry(String bookId, WorldBookEntry entry) async {
    final book = await loadById(bookId);
    if (book == null) {
      throw StateError('世界书不存在: $bookId');
    }

    final newEntries = book.entries.map((e) {
      return e.id == entry.id ? entry : e;
    }).toList();

    final updatedBook = book.copyWith(
      entries: newEntries,
      updatedAt: DateTime.now(),
    );

    await save(updatedBook);
    return updatedBook;
  }

  /// 删除条目
  Future<WorldBook> deleteEntry(String bookId, String entryId) async {
    final book = await loadById(bookId);
    if (book == null) {
      throw StateError('世界书不存在: $bookId');
    }

    final newEntries = book.entries.where((e) => e.id != entryId).toList();
    final updatedBook = book.copyWith(
      entries: newEntries,
      updatedAt: DateTime.now(),
    );

    await save(updatedBook);
    return updatedBook;
  }

  /// 创建新条目
  WorldBookEntry createEntry({
    List<String> key = const [],
    List<String> keysecondary = const [],
    String content = '',
    String comment = '',
    bool constant = false,
    bool selective = false,
    int selectiveLogic = 0,
    int order = 100,
    int position = 0,
    int depth = 4,
    int sticky = 0,
    int cooldown = 0,
    int delay = 0,
    bool isEnabled = true,
  }) {
    return WorldBookEntry(
      id: generateEntryId(),
      key: key,
      keysecondary: keysecondary,
      content: content,
      comment: comment,
      constant: constant,
      selective: selective,
      selectiveLogic: selectiveLogic,
      order: order,
      position: position,
      depth: depth,
      sticky: sticky,
      cooldown: cooldown,
      delay: delay,
      isEnabled: isEnabled,
      extensions: {},
    );
  }
}

/// 导入异常
class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => 'ImportException: $message';
}
