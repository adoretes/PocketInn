import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/data/api_configs.dart';
import 'package:pocket_inn/models/api_config.dart';
import 'package:pocket_inn/models/chat_memory.dart';
import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/chat_memory_service.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_env.dart';

const _requestTimeout = Duration(seconds: 5);
const _userName = '测试用户';
const _characterName = '测试角色';

/// Each reply can hold one real loopback request until the test changes state.
/// Unexpected extra requests receive an immediate empty result, so a missing
/// extraction lock fails an assertion instead of deadlocking a two-request gate.
class _Reply {
  _Reply(this.ops, {required bool hold}) {
    if (!hold) release();
  }

  final List<Map<String, dynamic>> ops;
  final arrived = Completer<void>();
  final _released = Completer<void>();

  void release() {
    if (!_released.isCompleted) _released.complete();
  }

  Future<void> waitForRequest() => arrived.future.timeout(_requestTimeout);
}

class _CompletionServer {
  _CompletionServer._(this.server);

  final HttpServer server;
  final requests = <Map<String, dynamic>>[];
  final _replies = <_Reply>[];
  bool _closed = false;

  static Future<_CompletionServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _CompletionServer._(server);
    server.listen(fixture._handle);
    return fixture;
  }

  _Reply reply({List<Map<String, dynamic>> ops = const [], bool hold = false}) {
    final plan = _Reply(ops, hold: hold);
    _replies.add(plan);
    return plan;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final payload = jsonDecode(await utf8.decoder.bind(request).join());
      final requestIndex = requests.length;
      requests.add(Map<String, dynamic>.from(payload as Map));
      final plan = requestIndex < _replies.length
          ? _replies[requestIndex]
          : _Reply(const [], hold: false);
      plan.arrived.complete();
      await plan._released.future;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': jsonEncode({'ops': plan.ops}),
              },
              'finish_reason': 'stop',
            },
          ],
        }),
      );
      await request.response.close();
    } on Object {
      if (!_closed) rethrow;
    }
  }

  String logAt(int index) {
    final messages = requests[index]['messages'] as List<dynamic>;
    return (messages.last as Map<String, dynamic>)['content'] as String;
  }

  Future<void> close() async {
    _closed = true;
    for (final plan in _replies) {
      plan.release();
    }
    await server.close(force: true);
  }
}

class _History {
  _History(this.sessionId, this.messages);

  final String sessionId;
  final List<ChatMessage> messages;

  List<String> get ids => messages.map((message) => message.id!).toList();
  String get anchor => messages.last.id!;
}

String _expectedLog(Iterable<ChatMessage> messages) => messages
    .map(
      (message) =>
          '${message.isMe ? _userName : _characterName}: ${message.text}',
    )
    .join('\n');

void main() {
  final db = ChatDatabaseService.instance;
  final memory = ChatMemoryService.instance;
  late Directory dataDirectory;
  late _CompletionServer api;
  late HttpOverrides? originalHttpOverrides;
  var runSequence = 0;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    originalHttpOverrides = HttpOverrides.current;
    // The test binding otherwise intercepts HttpClient instead of using loopback.
    HttpOverrides.global = null;
    dataDirectory = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await db.initialize();
    expect(db.databasePath, startsWith(dataDirectory.path));
  });

  tearDownAll(() async {
    await db.deleteDatabaseFiles();
    tearDownPathProviderMocks(dataDirectory);
    HttpOverrides.global = originalHttpOverrides;
  });

  setUp(() async {
    await db.clearAllData();
    memory.clearResolveCache();
    memoryExtractionNotifier.value = const MemoryExtractionConfig(
      enabled: true,
      interval: 20,
    );
    api = await _CompletionServer.start();
    apiConfigsNotifier.value = [
      ApiConfig(
        id: 'memory-extraction-fixture',
        name: '本地记忆测试接口',
        baseUrl: 'http://127.0.0.1:${api.server.port}/v1',
        apiKey: 'test-only',
        models: const [ApiModel(id: 'fixture-model', modelId: 'fixture-model')],
      ),
    ];
    selectedApiModelIdNotifier.value = 'fixture-model';
  });

  tearDown(() async {
    await api.close();
    apiConfigsNotifier.value = [];
    selectedApiModelIdNotifier.value = null;
  });

  Future<void> appendRound(_History history, int round) async {
    final user = await db.appendUserMessage(
      sessionId: history.sessionId,
      parentMessageId: history.messages.isEmpty ? null : history.anchor,
      text: '用户消息-$round',
    );
    final assistant = await db.appendAssistantMessage(
      sessionId: history.sessionId,
      parentMessageId: user.id,
      text: '角色回复-$round',
    );
    history.messages.addAll([
      ChatMessage(id: user.id, text: user.text, isMe: true),
      ChatMessage(id: assistant.id, text: assistant.text, isMe: false),
    ]);
  }

  Future<_History> history(int rounds) async {
    final session = await db.createSession(
      characterId: 'memory-extraction-character',
      openingAssistantMessages: [],
    );
    final fixture = _History(session.id, []);
    for (var round = 1; round <= rounds; round++) {
      await appendRound(fixture, round);
    }
    return fixture;
  }

  Future<bool> extract(_History fixture) => memory.tryExtractAndSave(
    sessionId: fixture.sessionId,
    branchLeafId: fixture.anchor,
    messages: fixture.messages,
    characterName: _characterName,
    userName: _userName,
  );

  Future<bool> retry(_History fixture) => memory.retryExtraction(
    sessionId: fixture.sessionId,
    anchorMessageId: fixture.anchor,
  );

  Future<void> seedRun(
    _History fixture, {
    required List<String> ids,
    MemoryExtractionStatus status = MemoryExtractionStatus.failed,
    String? anchor,
    DateTime? createdAt,
  }) => db.upsertExtractionRun(
    MemoryExtractionRun(
      id: 'fixture-run-${runSequence++}',
      sessionId: fixture.sessionId,
      branchLeafId: anchor ?? fixture.anchor,
      processedMessageIds: ids,
      status: status,
      characterName: _characterName,
      userName: _userName,
      createdAt: createdAt ?? DateTime.now(),
    ),
  );

  Future<MemoryExtractionRun> runAtAnchor(_History fixture) async =>
      (await db.loadAllSessionExtractionRuns(
        fixture.sessionId,
      )).singleWhere((run) => run.branchLeafId == fixture.anchor);

  Future<MemoryNode> addOrigin(_History fixture, {String content = '原始内容'}) =>
      memory.addMemory(
        sessionId: fixture.sessionId,
        branchLeafId: fixture.messages[1].id!,
        content: content,
        type: MemoryType.fact,
      );

  Future<ResolvedMemory> resolved(
    _History fixture,
    String memoryId, {
    String? at,
  }) async => (await memory.resolveMemoriesAtMessage(
    sessionId: fixture.sessionId,
    messageId: at ?? fixture.anchor,
    includeInvalidated: true,
  )).singleWhere((item) => item.id == memoryId);

  List<Map<String, dynamic>> addResult(String content) => [
    {'op': 'add', 'content': content, 'importance': 4, 'type': 'event'},
  ];

  test('extractMemories 原样发送固定批次，不受当前提取间隔截断', () async {
    final fixture = await history(5);
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 1,
    );
    api.reply();

    final result = await memory.extractMemories(
      messages: fixture.messages,
      characterName: _characterName,
      userName: _userName,
    );

    expect(result, jsonEncode({'ops': []}));
    expect(api.requests, hasLength(1));
    expect(api.logAt(0), _expectedLog(fixture.messages));
    expect(await db.loadAllSessionExtractionRuns(fixture.sessionId), isEmpty);
  });

  test('失败的五轮批次在间隔改为一轮及请求中再次修改后仍完整重试', () async {
    final fixture = await history(5);
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 5,
    );
    await seedRun(fixture, ids: fixture.ids);
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 1,
    );
    final reply = api.reply(hold: true);
    final pending = retry(fixture);
    try {
      await reply.waitForRequest();
      memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
        interval: 3,
      );
    } finally {
      reply.release();
    }

    expect(await pending, isFalse, reason: '空操作完成提取但没有新增记忆');
    expect(api.logAt(0), _expectedLog(fixture.messages));
    final run = await runAtAnchor(fixture);
    expect(run.status, MemoryExtractionStatus.empty);
    expect(run.processedMessageIds, orderedEquals(fixture.ids));
  });

  test('请求期间间隔从一变三，水位只包含实际发送的 pending 批次', () async {
    final fixture = await history(4);
    await seedRun(
      fixture,
      ids: fixture.ids.take(6).toList(),
      anchor: fixture.messages[5].id!,
      status: MemoryExtractionStatus.applied,
    );
    final pendingMessages = fixture.messages.skip(6).toList();
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 1,
    );
    final reply = api.reply(ops: addResult('新增批次记忆'), hold: true);
    final pending = extract(fixture);
    try {
      await reply.waitForRequest();
      memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
        interval: 3,
      );
    } finally {
      reply.release();
    }

    expect(await pending, isTrue);
    expect(api.logAt(0), _expectedLog(pendingMessages));
    final sentIds = pendingMessages.map((message) => message.id!).toList();
    expect(
      (await runAtAnchor(fixture)).processedMessageIds,
      orderedEquals(sentIds),
    );
    final saved = (await db.loadAllSessionMemories(fixture.sessionId)).single;
    expect(saved.sourceMessageIds, orderedEquals(sentIds));
  });

  test('同次调用按二轮批次补齐六轮积压，新增一轮不会由旧积压触发', () async {
    final fixture = await history(6);
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 2,
    );
    for (var batch = 0; batch < 3; batch++) {
      api.reply();
    }

    expect(await extract(fixture), isFalse);
    expect(api.requests, hasLength(3));
    final runs = await db.loadAllSessionExtractionRuns(fixture.sessionId);
    expect(runs, hasLength(3));
    final byAnchor = {for (final run in runs) run.branchLeafId: run};
    final allProcessedIds = <String>[];
    for (var batch = 0; batch < 3; batch++) {
      final messages = fixture.messages.sublist(batch * 4, (batch + 1) * 4);
      final ids = messages.map((message) => message.id!).toList();
      expect(api.logAt(batch), _expectedLog(messages));
      final run = byAnchor[messages.last.id!]!;
      expect(run.status, MemoryExtractionStatus.empty);
      expect(run.processedMessageIds, orderedEquals(ids));
      allProcessedIds.addAll(run.processedMessageIds);
    }
    expect(allProcessedIds, orderedEquals(fixture.ids));
    expect(allProcessedIds.toSet(), hasLength(allProcessedIds.length));
    expect(
      ChatMemoryService.countNewAssistantMessages(
        allMessages: fixture.messages,
        runs: runs,
      ),
      0,
    );

    await appendRound(fixture, 7);
    final pendingCount = ChatMemoryService.countNewAssistantMessages(
      allMessages: fixture.messages,
      runs: runs,
    );
    expect(pendingCount, 1);
    expect(pendingCount, lessThan(memoryExtractionNotifier.value.interval));
    expect(api.requests, hasLength(3));
  });

  test('首个二轮批次失败即停止，新锚点仅续处理剩余消息且首批仍可显式重试', () async {
    final fixture = await history(5);
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 2,
    );
    api.reply(
      ops: [
        {'op': 'update', 'id': '首批不存在的目标', 'importance': 5},
      ],
    );

    expect(await extract(fixture), isFalse);
    expect(api.requests, hasLength(1));
    final firstBatch = fixture.messages.take(4).toList();
    final firstAnchor = firstBatch.last.id!;
    expect(api.logAt(0), _expectedLog(firstBatch));
    final failedRuns = await db.loadAllSessionExtractionRuns(fixture.sessionId);
    final failed = failedRuns.single;
    expect(failed.branchLeafId, firstAnchor);
    expect(failed.status, MemoryExtractionStatus.failed);
    expect(
      failed.processedMessageIds,
      orderedEquals(firstBatch.map((message) => message.id!)),
    );
    expect(await db.loadAllSessionMemories(fixture.sessionId), isEmpty);

    await appendRound(fixture, 6);
    api.reply(ops: addResult('续处理第三四轮'));
    api.reply(ops: addResult('续处理第五六轮'));
    expect(await extract(fixture), isTrue);
    expect(api.requests, hasLength(3));
    final continuedRuns = await db.loadAllSessionExtractionRuns(
      fixture.sessionId,
    );
    expect(continuedRuns, hasLength(3));
    expect(
      continuedRuns.singleWhere((run) => run.branchLeafId == firstAnchor),
      failed,
    );
    for (var batch = 1; batch < 3; batch++) {
      final messages = fixture.messages.sublist(batch * 4, (batch + 1) * 4);
      expect(api.logAt(batch), _expectedLog(messages));
      final run = continuedRuns.singleWhere(
        (item) => item.branchLeafId == messages.last.id,
      );
      expect(run.status, MemoryExtractionStatus.applied);
      expect(
        run.processedMessageIds,
        orderedEquals(messages.map((message) => message.id!)),
      );
    }

    api.reply(ops: addResult('显式重试首批成功'));
    expect(
      await memory.retryExtraction(
        sessionId: fixture.sessionId,
        anchorMessageId: firstAnchor,
      ),
      isTrue,
    );
    expect(api.requests, hasLength(4));
    expect(api.logAt(3), _expectedLog(firstBatch));
    final retried = (await db.loadAllSessionExtractionRuns(
      fixture.sessionId,
    )).singleWhere((run) => run.branchLeafId == firstAnchor);
    expect(retried.status, MemoryExtractionStatus.applied);
    expect(
      retried.processedMessageIds,
      orderedEquals(failed.processedMessageIds),
    );
    expect(retried.createdAt, failed.createdAt);
    final retriedMemory = (await db.loadAllSessionMemories(
      fixture.sessionId,
    )).singleWhere((item) => item.content == '显式重试首批成功');
    expect(retriedMemory.branchLeafId, firstAnchor);
    expect(
      retriedMemory.sourceMessageIds,
      orderedEquals(failed.processedMessageIds),
    );
  });

  test('首次自动提取在途新增未来节点来源，提交后未来节点仍待提取', () async {
    final fixture = await history(1);
    final firstAnchor = fixture.anchor;
    final firstMessages = List<ChatMessage>.of(fixture.messages);
    final firstReply = api.reply(ops: addResult('首次自动提取结果'), hold: true);
    final firstExtraction = extract(fixture);
    late MemoryNode futureSource;
    try {
      await firstReply.waitForRequest();
      await appendRound(fixture, 2);
      futureSource = await memory.addMemory(
        sessionId: fixture.sessionId,
        branchLeafId: fixture.anchor,
        content: '请求发出之后添加的未来来源',
        sourceMessageIds: [fixture.anchor],
      );
    } finally {
      firstReply.release();
    }

    expect(await firstExtraction, isTrue);
    expect(api.requests, hasLength(1));
    expect(api.logAt(0), _expectedLog(firstMessages));
    final firstRuns = await db.loadAllSessionExtractionRuns(fixture.sessionId);
    final firstRun = firstRuns.single;
    expect(firstRun.branchLeafId, firstAnchor);
    expect(firstRun.createdAt.isBefore(futureSource.createdAt), isTrue);
    expect(
      firstRun.processedMessageIds,
      orderedEquals(firstMessages.map((message) => message.id!)),
    );
    expect(
      ChatMemoryService.countNewAssistantMessages(
        allMessages: fixture.messages,
        runs: firstRuns,
        memories: await db.loadAllSessionMemories(fixture.sessionId),
      ),
      1,
    );

    api.reply(ops: addResult('未来节点自动提取结果'));
    expect(await extract(fixture), isTrue);
    expect(api.requests, hasLength(2));
    final futureMessages = fixture.messages.skip(2).toList();
    expect(api.logAt(1), _expectedLog(futureMessages));
    expect(
      (await runAtAnchor(fixture)).processedMessageIds,
      orderedEquals(futureMessages.map((message) => message.id!)),
    );
  });

  test('旧批次的 input 宏及运行记录只使用本批最后用户文本', () async {
    final fixture = await history(6);
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 2,
      customExtractionPrompt: '本批输入BEGIN{{input}}END',
    );
    for (var batch = 0; batch < 3; batch++) {
      api.reply();
    }
    final latestInput = fixture.messages[10].text;

    expect(
      await memory.tryExtractAndSave(
        sessionId: fixture.sessionId,
        branchLeafId: fixture.anchor,
        messages: fixture.messages,
        characterName: _characterName,
        userName: _userName,
        currentInput: latestInput,
      ),
      isFalse,
    );
    expect(api.requests, hasLength(3));
    final runs = await db.loadAllSessionExtractionRuns(fixture.sessionId);
    expect(runs, hasLength(3));
    for (var batch = 0; batch < 3; batch++) {
      final messages = fixture.messages.sublist(batch * 4, (batch + 1) * 4);
      final batchInput = messages[messages.length - 2].text;
      final requestMessages = api.requests[batch]['messages'] as List<dynamic>;
      final system =
          (requestMessages.first as Map<String, dynamic>)['content'] as String;
      expect(system, contains('本批输入BEGIN${batchInput}END'));
      if (batch < 2) {
        expect(system, isNot(contains(latestInput)));
      }
      final run = runs.singleWhere(
        (item) => item.branchLeafId == messages.last.id,
      );
      expect(run.currentInput, batchInput);
      expect(api.logAt(batch), _expectedLog(messages));
    }
  });

  test('请求中修改间隔不改变后续二轮批次，逐批锚定且不读取未来记忆', () async {
    final fixture = await history(6);
    memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
      interval: 2,
    );
    final target = await addOrigin(fixture, content: '最初已知的事实');
    const futureContent = '第六轮才能知道的未来事实';
    await memory.addMemory(
      sessionId: fixture.sessionId,
      branchLeafId: fixture.anchor,
      content: futureContent,
    );
    final firstReply = api.reply(ops: addResult('第一批新增事实'), hold: true);
    api.reply(
      ops: [
        {'op': 'update', 'id': target.id, 'importance': 4},
        ...addResult('第二批新增事实'),
      ],
    );
    api.reply(ops: addResult('第三批新增事实'));
    final pending = extract(fixture);
    try {
      await firstReply.waitForRequest();
      memoryExtractionNotifier.value = memoryExtractionNotifier.value.copyWith(
        interval: 1,
      );
      expect(api.requests, hasLength(1));
    } finally {
      firstReply.release();
    }

    expect(await pending, isTrue);
    expect(api.requests, hasLength(3));
    final runs = await db.loadAllSessionExtractionRuns(fixture.sessionId);
    expect(runs, hasLength(3));
    final byAnchor = {for (final run in runs) run.branchLeafId: run};
    final memories = await db.loadAllSessionMemories(fixture.sessionId);
    final batchContents = ['第一批新增事实', '第二批新增事实', '第三批新增事实'];
    for (var batch = 0; batch < 3; batch++) {
      final messages = fixture.messages.sublist(batch * 4, (batch + 1) * 4);
      final ids = messages.map((message) => message.id!).toList();
      final anchor = messages.last.id!;
      expect(api.logAt(batch), _expectedLog(messages));
      expect(byAnchor[anchor]!.processedMessageIds, orderedEquals(ids));
      expect(byAnchor[anchor]!.status, MemoryExtractionStatus.applied);
      final saved = memories.singleWhere(
        (item) => item.content == batchContents[batch],
      );
      expect(saved.branchLeafId, anchor);
      expect(saved.sourceMessageIds, orderedEquals(ids));
    }
    String systemAt(int index) {
      final messages = api.requests[index]['messages'] as List<dynamic>;
      return (messages.first as Map<String, dynamic>)['content'] as String;
    }

    expect(systemAt(0), isNot(contains(futureContent)));
    expect(systemAt(1), isNot(contains(futureContent)));
    expect(systemAt(2), contains(futureContent));
    expect(systemAt(1), contains('第一批新增事实'));
    expect(systemAt(2), contains('第二批新增事实'));
    final modelDiff = (await db.loadAllSessionMemoryDiffs(
      fixture.sessionId,
    )).singleWhere((diff) => diff.targetMemoryId == target.id);
    expect(modelDiff.branchLeafId, fixture.messages[7].id);
    expect(
      (await resolved(
        fixture,
        target.id,
        at: fixture.messages[3].id,
      )).importance,
      3,
    );
    expect(
      (await resolved(
        fixture,
        target.id,
        at: fixture.messages[7].id,
      )).importance,
      4,
    );
  });

  test('retry 保留初始 createdAt，后续节点手动来源不会被误认作 legacy 水位', () async {
    final fixture = await history(1);
    final firstAnchor = fixture.anchor;
    final firstMessages = List<ChatMessage>.of(fixture.messages);
    final firstCreatedAt = DateTime.utc(2020, 1, 1);
    await seedRun(fixture, ids: fixture.ids, createdAt: firstCreatedAt);
    final originalRun = await runAtAnchor(fixture);
    await appendRound(fixture, 2);
    final laterSource = await memory.addMemory(
      sessionId: fixture.sessionId,
      branchLeafId: fixture.anchor,
      content: '首次失败运行之后才添加的手动记忆',
      sourceMessageIds: [fixture.anchor],
    );
    expect(laterSource.createdAt.isAfter(firstCreatedAt), isTrue);
    api.reply();
    api.reply(ops: addResult('后续节点仍需自动提取'));

    expect(
      await memory.retryExtraction(
        sessionId: fixture.sessionId,
        anchorMessageId: firstAnchor,
      ),
      isFalse,
    );
    final retried = (await db.loadAllSessionExtractionRuns(
      fixture.sessionId,
    )).singleWhere((run) => run.branchLeafId == firstAnchor);
    expect(retried.status, MemoryExtractionStatus.empty);
    expect(retried.createdAt, firstCreatedAt);
    expect(retried.id, isNot(originalRun.id));
    expect(api.logAt(0), _expectedLog(firstMessages));
    expect(
      ChatMemoryService.countNewAssistantMessages(
        allMessages: fixture.messages,
        runs: [retried],
        memories: await db.loadAllSessionMemories(fixture.sessionId),
      ),
      1,
    );

    expect(await extract(fixture), isTrue);
    expect(api.requests, hasLength(2));
    final laterBatch = fixture.messages.skip(2).toList();
    expect(api.logAt(1), _expectedLog(laterBatch));
    expect(
      (await runAtAnchor(fixture)).processedMessageIds,
      orderedEquals(laterBatch.map((message) => message.id!)),
    );
    final saved = (await db.loadAllSessionMemories(
      fixture.sessionId,
    )).singleWhere((item) => item.content == '后续节点仍需自动提取');
    expect(saved.branchLeafId, fixture.anchor);
  });

  test('旧 failed 记录只重试倒退点前的原窗口，legacy 尾巴继续提供旧水位', () async {
    final fixture = await history(6);
    final legacyIds = fixture.ids.take(8).toList();
    final window = fixture.messages.skip(8).toList();
    final windowIds = window.map((message) => message.id!).toList();
    final legacyMemory = await memory.addMemory(
      sessionId: fixture.sessionId,
      branchLeafId: fixture.messages[7].id!,
      content: '旧运行前已存在的来源记忆',
      sourceMessageIds: legacyIds,
    );
    final firstCreatedAt = legacyMemory.createdAt.add(
      const Duration(microseconds: 1),
    );
    await seedRun(
      fixture,
      ids: [...windowIds, ...legacyIds],
      createdAt: firstCreatedAt,
    );
    api.reply(ops: addResult('只从原窗口重试得到的记忆'));

    expect(await retry(fixture), isTrue);
    expect(api.requests, hasLength(1));
    expect(api.logAt(0), _expectedLog(window));
    final retried = await runAtAnchor(fixture);
    expect(retried.processedMessageIds, orderedEquals(windowIds));
    expect(retried.createdAt, firstCreatedAt);
    final memories = await db.loadAllSessionMemories(fixture.sessionId);
    final saved = memories.singleWhere(
      (item) => item.content == '只从原窗口重试得到的记忆',
    );
    expect(saved.sourceMessageIds, orderedEquals(windowIds));
    expect(
      ChatMemoryService.countNewAssistantMessages(
        allMessages: fixture.messages,
        runs: [retried],
        memories: memories,
      ),
      0,
    );
  });

  test('legacy 来源只用于兼容旧水位，不伪装成本次已发送的消息', () async {
    final fixture = await history(6);
    final legacyIds = fixture.ids.take(8).toList();
    await memory.addMemory(
      sessionId: fixture.sessionId,
      branchLeafId: fixture.messages[7].id!,
      content: '旧版本已提取记忆',
      sourceMessageIds: legacyIds,
    );
    final pendingMessages = fixture.messages.skip(8).toList();
    api.reply(ops: addResult('本次新增记忆'));

    expect(await extract(fixture), isTrue);
    expect(api.logAt(0), _expectedLog(pendingMessages));
    final expectedIds = pendingMessages.map((message) => message.id!).toList();
    final run = await runAtAnchor(fixture);
    expect(run.processedMessageIds, orderedEquals(expectedIds));
    final memories = await db.loadAllSessionMemories(fixture.sessionId);
    final added = memories.singleWhere((item) => item.content == '本次新增记忆');
    expect(added.sourceMessageIds, orderedEquals(expectedIds));
    expect(
      ChatMemoryService.countNewAssistantMessages(
        allMessages: fixture.messages,
        runs: [run],
        memories: memories,
      ),
      0,
      reason: '出现新运行记录后，legacy 来源仍然是已经处理过的历史',
    );

    await appendRound(fixture, 7);
    expect(
      ChatMemoryService.countNewAssistantMessages(
        allMessages: fixture.messages,
        runs: [run],
        memories: memories,
      ),
      1,
    );
  });

  test('同锚点并发 retry 立即拒绝第二次请求且仅落库一次', () async {
    final fixture = await history(2);
    await seedRun(fixture, ids: fixture.ids);
    final reply = api.reply(ops: addResult('唯一重试记忆'), hold: true);
    final first = retry(fixture);
    bool? secondResult;
    int? requestsWhileFirstPending;
    try {
      await reply.waitForRequest();
      secondResult = await retry(fixture).timeout(_requestTimeout);
      requestsWhileFirstPending = api.requests.length;
    } finally {
      reply.release();
    }

    expect(await first, isTrue);
    expect(secondResult, isFalse);
    expect(requestsWhileFirstPending, 1);
    expect(api.requests, hasLength(1));
    final saved = await db.loadAllSessionMemories(fixture.sessionId);
    expect(saved.single.content, '唯一重试记忆');
    expect((await runAtAnchor(fixture)).addedCount, 1);
  });

  test('同锚点并发自动提取立即拒绝第二次请求', () async {
    final fixture = await history(2);
    final reply = api.reply(ops: addResult('唯一自动记忆'), hold: true);
    final first = extract(fixture);
    bool? secondResult;
    int? requestsWhileFirstPending;
    try {
      await reply.waitForRequest();
      secondResult = await extract(fixture).timeout(_requestTimeout);
      requestsWhileFirstPending = api.requests.length;
    } finally {
      reply.release();
    }

    expect(await first, isTrue);
    expect(secondResult, isFalse);
    expect(requestsWhileFirstPending, 1);
    expect(api.requests, hasLength(1));
    expect(await db.loadAllSessionMemories(fixture.sessionId), hasLength(1));
  });

  test('进行中的 retry 与同锚点自动提取共享排他约束', () async {
    final fixture = await history(3);
    await seedRun(fixture, ids: fixture.ids.skip(4).toList());
    final reply = api.reply(ops: addResult('重试保留结果'), hold: true);
    final first = retry(fixture);
    bool? automaticResult;
    int? requestsWhileFirstPending;
    try {
      await reply.waitForRequest();
      automaticResult = await extract(fixture).timeout(_requestTimeout);
      requestsWhileFirstPending = api.requests.length;
    } finally {
      reply.release();
    }

    expect(await first, isTrue);
    expect(automaticResult, isFalse);
    expect(requestsWhileFirstPending, 1);
    expect(api.requests, hasLength(1));
    expect(await db.loadAllSessionMemories(fixture.sessionId), hasLength(1));
  });

  for (final initialStatus in [
    MemoryExtractionStatus.applied,
    MemoryExtractionStatus.empty,
  ]) {
    test('${initialStatus.name} 锚点再次 retry 或自动提取都不发请求', () async {
      final fixture = await history(2);
      api.reply(
        ops: initialStatus == MemoryExtractionStatus.applied
            ? addResult('已经成功的记忆')
            : const [],
      );
      expect(
        await extract(fixture),
        initialStatus == MemoryExtractionStatus.applied,
      );
      final initialRun = await runAtAnchor(fixture);
      expect(initialRun.status, initialStatus);
      final memoryCount = (await db.loadAllSessionMemories(
        fixture.sessionId,
      )).length;

      expect(await retry(fixture), isFalse);
      expect(await extract(fixture), isFalse);
      expect(api.requests, hasLength(1));
      expect(
        (await db.loadAllSessionMemories(fixture.sessionId)).length,
        memoryCount,
      );
      expect(await runAtAnchor(fixture), initialRun);
    });
  }

  test('有效 JSON 的提取操作失败后仍可显式重试成功', () async {
    final fixture = await history(2);
    api.reply(
      ops: [
        {'op': 'update', 'id': '不存在的记忆', 'importance': 5},
      ],
    );
    api.reply(ops: addResult('重试成功记忆'));

    expect(await extract(fixture), isFalse);
    final failed = await runAtAnchor(fixture);
    expect(failed.status, MemoryExtractionStatus.failed);
    expect(failed.processedMessageIds, orderedEquals(fixture.ids));
    expect(await db.loadAllSessionMemories(fixture.sessionId), isEmpty);

    expect(await retry(fixture), isTrue);
    expect(api.requests, hasLength(2));
    expect(api.logAt(1), api.logAt(0));
    final run = await runAtAnchor(fixture);
    expect(run.status, MemoryExtractionStatus.applied);
    expect(run.processedMessageIds, orderedEquals(fixture.ids));
    expect(
      (await db.loadAllSessionMemories(fixture.sessionId)).single.content,
      '重试成功记忆',
    );
  });

  test('在途手改内容类型常驻使提取冲突回滚，保留编辑且允许显式重试', () async {
    final fixture = await history(3);
    final origin = await addOrigin(fixture);
    final reply = api.reply(
      ops: [
        ...addResult('冲突事务中不能写入的新记忆'),
        {'op': 'update', 'id': origin.id, 'importance': 4},
      ],
      hold: true,
    );
    final pending = extract(fixture);
    try {
      await reply.waitForRequest();
      await memory.applyMemoryEdits(
        sessionId: fixture.sessionId,
        atMessageId: fixture.anchor,
        commands: [
          MemoryEditCommand(
            kind: MemoryEditKind.update,
            targetMemoryId: origin.id,
            content: '用户保存的内容',
            importance: 5,
            type: MemoryType.setting,
            isPinned: true,
          ),
        ],
      );
    } finally {
      reply.release();
    }

    expect(await pending, isFalse);
    final afterConflict = await resolved(fixture, origin.id);
    expect(afterConflict.content, '用户保存的内容');
    expect(afterConflict.importance, 5);
    expect(afterConflict.type, MemoryType.setting);
    expect(afterConflict.isPinned, isTrue);
    expect(afterConflict.invalidated, isFalse);
    expect(await db.loadAllSessionMemories(fixture.sessionId), hasLength(1));
    final failed = await runAtAnchor(fixture);
    expect(failed.status, MemoryExtractionStatus.failed);
    expect(failed.errorMessage, isNotEmpty);
    expect(failed.processedMessageIds, orderedEquals(fixture.ids));

    api.reply(
      ops: [
        {'op': 'update', 'id': origin.id, 'importance': 4},
      ],
    );
    expect(await retry(fixture), isTrue);
    expect(api.requests, hasLength(2));
    final retried = await resolved(fixture, origin.id);
    expect(retried.content, '用户保存的内容');
    expect(retried.importance, 4);
    expect(retried.type, MemoryType.setting);
    expect(retried.isPinned, isTrue);
    expect((await runAtAnchor(fixture)).status, MemoryExtractionStatus.applied);
  });

  for (final atAncestor in [false, true]) {
    for (final edit in ['invalidate', 'restore', 'clearEdits']) {
      test('在途${atAncestor ? '祖先' : '同锚点'} $edit 改变路径差量时拒绝提交', () async {
        final fixture = await history(3);
        final origin = await addOrigin(fixture);
        final editAt = atAncestor ? fixture.messages[3].id! : fixture.anchor;
        if (edit == 'clearEdits') {
          await memory.updateMemory(
            sessionId: fixture.sessionId,
            atMessageId: editAt,
            memoryId: origin.id,
            content: '请求前已有的分支改动',
            importance: 3,
          );
        }
        final reply = api.reply(
          ops: [
            {'op': 'update', 'id': origin.id, 'importance': 4},
          ],
          hold: true,
        );
        final pending = extract(fixture);
        try {
          await reply.waitForRequest();
          if (edit == 'clearEdits') {
            await memory.clearMemoryEditsAtNode(
              sessionId: fixture.sessionId,
              atMessageId: editAt,
              memoryId: origin.id,
            );
          } else {
            await memory.invalidateMemory(
              sessionId: fixture.sessionId,
              atMessageId: editAt,
              memoryId: origin.id,
            );
            if (edit == 'restore') {
              // Returning to the same visible state still changes the diff IDs;
              // the extraction must notice the intervening user operations.
              await memory.restoreMemory(
                sessionId: fixture.sessionId,
                atMessageId: editAt,
                memoryId: origin.id,
              );
            }
          }
        } finally {
          reply.release();
        }

        expect(await pending, isFalse);
        final after = await resolved(fixture, origin.id);
        expect(after.content, '原始内容');
        expect(after.importance, 3);
        expect(after.invalidated, edit == 'invalidate');
        expect(
          (await runAtAnchor(fixture)).status,
          MemoryExtractionStatus.failed,
        );
        expect(
          (await db.loadAllSessionMemoryDiffs(
            fixture.sessionId,
          )).every((diff) => diff.isUserEdited),
          isTrue,
          reason: '冲突的模型差量不得提交',
        );
      });
    }
  }

  test('在途修改兄弟分支上的同一记忆不误报当前路径冲突', () async {
    final fixture = await history(3);
    final origin = await addOrigin(fixture);
    final siblingUser = await db.appendUserMessage(
      sessionId: fixture.sessionId,
      parentMessageId: fixture.messages[1].id!,
      text: '兄弟分支用户消息',
    );
    final sibling = await db.appendAssistantMessage(
      sessionId: fixture.sessionId,
      parentMessageId: siblingUser.id,
      text: '兄弟分支回复',
    );
    final reply = api.reply(
      ops: [
        {'op': 'update', 'id': origin.id, 'importance': 4},
      ],
      hold: true,
    );
    final pending = extract(fixture);
    try {
      await reply.waitForRequest();
      await memory.updateMemory(
        sessionId: fixture.sessionId,
        atMessageId: sibling.id,
        memoryId: origin.id,
        content: '仅兄弟分支修改',
        importance: 5,
        isPinned: true,
      );
    } finally {
      reply.release();
    }

    expect(await pending, isTrue);
    final current = await resolved(fixture, origin.id);
    expect(current.content, '原始内容');
    expect(current.importance, 4);
    expect(current.isPinned, isFalse);
    final siblingState = await resolved(fixture, origin.id, at: sibling.id);
    expect(siblingState.content, '仅兄弟分支修改');
    expect(siblingState.importance, 5);
    expect(siblingState.isPinned, isTrue);
    expect((await runAtAnchor(fixture)).status, MemoryExtractionStatus.applied);
  });

  test('在途修改同路径无关记忆不误报目标冲突', () async {
    final fixture = await history(3);
    final target = await addOrigin(fixture);
    final unrelated = await addOrigin(fixture, content: '无关记忆原值');
    final reply = api.reply(
      ops: [
        {'op': 'update', 'id': target.id, 'importance': 4},
      ],
      hold: true,
    );
    final pending = extract(fixture);
    try {
      await reply.waitForRequest();
      await memory.updateMemory(
        sessionId: fixture.sessionId,
        atMessageId: fixture.anchor,
        memoryId: unrelated.id,
        content: '用户修改的无关记忆',
        importance: 5,
        type: MemoryType.preference,
        isPinned: true,
      );
    } finally {
      reply.release();
    }

    expect(await pending, isTrue);
    final targetState = await resolved(fixture, target.id);
    expect(targetState.content, '原始内容');
    expect(targetState.importance, 4);
    final unrelatedState = await resolved(fixture, unrelated.id);
    expect(unrelatedState.content, '用户修改的无关记忆');
    expect(unrelatedState.type, MemoryType.preference);
    expect(unrelatedState.isPinned, isTrue);
    expect((await runAtAnchor(fixture)).status, MemoryExtractionStatus.applied);
  });
}
