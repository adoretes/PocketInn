import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/data/api_configs.dart';
import 'package:pocket_inn/models/api_config.dart';
import 'package:pocket_inn/models/chat_memory.dart';
import 'package:pocket_inn/pages/chat/widgets/memory_tree_page.dart';
import 'package:pocket_inn/services/chat_database_service.dart';
import 'package:pocket_inn/services/chat_memory_service.dart';
import 'package:pocket_inn/services/storage_service.dart';

import '../../helpers/test_env.dart';

const _originalContent = '祖先记忆';
const _restoreTooltip = '恢复（撤销失效）';
const _invalidateTooltip = '停用（保存后可恢复）';
const _revertTooltip = '还原本节点改动（消除这次编辑）';

final _db = ChatDatabaseService.instance;
final _memoryService = ChatMemoryService.instance;

class _MemoryFixture {
  const _MemoryFixture({
    required this.sessionId,
    required this.rootId,
    required this.nodeId,
    required this.memoryId,
  });

  final String sessionId;
  final String rootId;
  final String nodeId;
  final String memoryId;
}

Finder _nodeDots() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_NodeDot',
);

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  String reason = '等待界面更新超时',
}) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.pump(const Duration(milliseconds: 40));
    if (condition()) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
  }
  fail(reason);
}

Future<_MemoryFixture> _createFixture({
  bool invalidated = false,
  bool inheritedInvalidated = false,
  bool localUpdate = false,
}) async {
  final session = await _db.createSession(
    characterId: 'memory-tree-test',
    openingAssistantMessages: ['祖先消息'],
  );
  final rootId = session.currentLeafMessageId!;
  final memory = await _memoryService.addMemory(
    sessionId: session.id,
    branchLeafId: rootId,
    content: _originalContent,
  );
  if (inheritedInvalidated) {
    await _memoryService.invalidateMemory(
      sessionId: session.id,
      atMessageId: rootId,
      memoryId: memory.id,
    );
  }
  final node = await _db.appendUserMessage(
    sessionId: session.id,
    parentMessageId: rootId,
    text: '当前消息',
  );
  if (localUpdate) {
    await _memoryService.updateMemory(
      sessionId: session.id,
      atMessageId: node.id,
      memoryId: memory.id,
      content: '本节点改写',
      importance: 4,
    );
  }
  if (inheritedInvalidated && !invalidated) {
    await _memoryService.restoreMemory(
      sessionId: session.id,
      atMessageId: node.id,
      memoryId: memory.id,
    );
  } else if (invalidated && !inheritedInvalidated) {
    await _memoryService.invalidateMemory(
      sessionId: session.id,
      atMessageId: node.id,
      memoryId: memory.id,
    );
  }
  return _MemoryFixture(
    sessionId: session.id,
    rootId: rootId,
    nodeId: node.id,
    memoryId: memory.id,
  );
}

Future<void> _pumpTree(
  WidgetTester tester,
  _MemoryFixture fixture, {
  String? leafId,
  int nodeCount = 2,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MemoryTreePage(
        sessionId: fixture.sessionId,
        activeLeafMessageId: leafId ?? fixture.nodeId,
      ),
    ),
  );
  await _pumpUntil(
    tester,
    () => _nodeDots().evaluate().length == nodeCount,
    reason: '记忆树未加载 $nodeCount 个消息节点',
  );
}

Future<void> _openActions(WidgetTester tester, int nodeIndex) async {
  await tester.tap(_nodeDots().at(nodeIndex));
  await _pumpUntil(tester, () => find.text('编辑记忆').evaluate().isNotEmpty);
}

Future<void> _openEditor(WidgetTester tester, {int nodeIndex = 1}) async {
  await _openActions(tester, nodeIndex);
  await tester.tap(find.text('编辑记忆'));
  await _pumpUntil(tester, () => find.byType(TextField).evaluate().isNotEmpty);
}

Future<void> _toggleState(WidgetTester tester) async {
  final restore = find.byTooltip(_restoreTooltip);
  await tester.tap(
    restore.evaluate().isNotEmpty
        ? restore
        : find.byTooltip(_invalidateTooltip),
  );
  await tester.pump();
}

Future<void> _saveEditor(WidgetTester tester) async {
  await tester.tap(find.text('保存'));
  await _pumpUntil(tester, () => find.byType(TextField).evaluate().isEmpty);
}

Future<ResolvedMemory> _resolvedAt(
  WidgetTester tester,
  _MemoryFixture fixture,
) async => (await tester.runAsync(
  () => _memoryService.resolveMemoriesAtMessage(
    sessionId: fixture.sessionId,
    messageId: fixture.nodeId,
    includeInvalidated: true,
  ),
))!.single;

Future<List<MemoryDiff>> _localDiffs(
  WidgetTester tester,
  _MemoryFixture fixture,
) async => (await tester.runAsync(
  () => _db.loadAllSessionMemoryDiffs(fixture.sessionId),
))!.where((diff) => diff.branchLeafId == fixture.nodeId).toList();

TextButton _textButton(WidgetTester tester, String label) =>
    tester.widget<TextButton>(find.widgetWithText(TextButton, label));

Future<void> _dismissActions(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 10));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await _pumpUntil(
    tester,
    () =>
        find.widgetWithText(TextButton, '编辑记忆').evaluate().isEmpty &&
        _nodeDots().evaluate().isNotEmpty,
  );
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDirectory;
  late HttpOverrides? originalHttpOverrides;

  setUpAll(() async {
    tempDirectory = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await _db.initialize();
    expect(_db.databasePath, startsWith(tempDirectory.path));
    originalHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
  });

  tearDownAll(() async {
    HttpOverrides.global = originalHttpOverrides;
    await _db.deleteDatabaseFiles();
    tearDownPathProviderMocks(tempDirectory);
  });

  setUp(() async {
    await _db.clearAllData();
    _memoryService.clearResolveCache();
    memoryExtractionNotifier.value = const MemoryExtractionConfig();
    apiConfigsNotifier.value = [];
    selectedApiModelIdNotifier.value = null;
  });

  group('记忆编辑器的最终失效状态', () {
    for (final toggleCount in [2, 4, 3]) {
      testWidgets('失效继承记忆切换 $toggleCount 次后遵循最终状态', (tester) async {
        final fixture = (await tester.runAsync(
          () => _createFixture(invalidated: true),
        ))!;
        await _pumpTree(tester, fixture);
        await _openEditor(tester);

        for (var i = 0; i < toggleCount; i++) {
          await _toggleState(tester);
        }
        final expectedInvalidated = toggleCount.isEven;
        expect(
          find.byTooltip(
            expectedInvalidated ? _restoreTooltip : _invalidateTooltip,
          ),
          findsOneWidget,
        );
        await _saveEditor(tester);

        expect(
          (await _resolvedAt(tester, fixture)).invalidated,
          expectedInvalidated,
        );
        final diffs = await _localDiffs(tester, fixture);
        expect(
          diffs.map((diff) => diff.kind),
          expectedInvalidated
              ? [MemoryDiffKind.invalidate]
              : [MemoryDiffKind.invalidate, MemoryDiffKind.restore],
        );
        await _disposeTree(tester);
      });
    }

    for (final toggleCount in [1, 2]) {
      testWidgets('有效继承记忆切换 $toggleCount 次后只保存最终状态差异', (tester) async {
        final fixture = (await tester.runAsync(_createFixture))!;
        await _pumpTree(tester, fixture);
        await _openEditor(tester);

        for (var i = 0; i < toggleCount; i++) {
          await _toggleState(tester);
        }
        await _saveEditor(tester);

        expect(
          (await _resolvedAt(tester, fixture)).invalidated,
          toggleCount.isOdd,
        );
        expect(
          (await _localDiffs(tester, fixture)).map((diff) => diff.kind),
          toggleCount.isOdd ? [MemoryDiffKind.invalidate] : isEmpty,
        );
        await _disposeTree(tester);
      });
    }

    testWidgets('修改失效记忆后明确停用，内容更新但仍保持失效', (tester) async {
      final fixture = (await tester.runAsync(
        () => _createFixture(invalidated: true),
      ))!;
      await _pumpTree(tester, fixture);
      await _openEditor(tester);

      await _toggleState(tester);
      await tester.enterText(find.byType(TextField), '修改后的失效记忆');
      await _toggleState(tester);
      expect(find.byTooltip(_restoreTooltip), findsOneWidget);
      await _saveEditor(tester);

      final memory = await _resolvedAt(tester, fixture);
      expect(memory.content, '修改后的失效记忆');
      expect(memory.invalidated, isTrue);
      expect((await _localDiffs(tester, fixture)).map((diff) => diff.kind), [
        MemoryDiffKind.invalidate,
        MemoryDiffKind.update,
      ]);
      await _disposeTree(tester);
    });

    testWidgets('还原本节点更新和失效差量后回到有效祖先状态', (tester) async {
      final fixture = (await tester.runAsync(
        () => _createFixture(invalidated: true, localUpdate: true),
      ))!;
      await _pumpTree(tester, fixture);
      await _openEditor(tester);

      await tester.tap(find.byTooltip(_revertTooltip));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        _originalContent,
      );
      expect(find.byTooltip(_invalidateTooltip), findsOneWidget);
      await _saveEditor(tester);

      final memory = await _resolvedAt(tester, fixture);
      expect(memory.content, _originalContent);
      expect(memory.invalidated, isFalse);
      expect(await _localDiffs(tester, fixture), isEmpty);
      await _disposeTree(tester);
    });

    testWidgets('还原后编辑并反复切换，按继承的失效状态保存', (tester) async {
      final fixture = (await tester.runAsync(
        () => _createFixture(inheritedInvalidated: true, localUpdate: true),
      ))!;
      await _pumpTree(tester, fixture);
      await _openEditor(tester);

      await tester.tap(find.byTooltip(_revertTooltip));
      await tester.pump();
      expect(find.byTooltip(_restoreTooltip), findsOneWidget);
      await tester.enterText(find.byType(TextField), '还原后重新修改');
      await _toggleState(tester);
      await _toggleState(tester);
      await _saveEditor(tester);

      final memory = await _resolvedAt(tester, fixture);
      expect(memory.content, '还原后重新修改');
      expect(memory.invalidated, isTrue);
      expect((await _localDiffs(tester, fixture)).map((diff) => diff.kind), [
        MemoryDiffKind.update,
      ]);
      await _disposeTree(tester);
    });

    testWidgets('来源节点仍可确认并彻底删除原始记忆及其差量', (tester) async {
      final fixture = (await tester.runAsync(
        () => _createFixture(localUpdate: true),
      ))!;
      await _pumpTree(tester, fixture);
      await _openEditor(tester, nodeIndex: 0);

      await tester.tap(find.byTooltip('彻底删除（影响所有后代）'));
      await tester.pumpAndSettle();
      expect(find.text('彻底删除原始记忆'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pumpAndSettle();
      await _saveEditor(tester);

      expect(
        await tester.runAsync(() => _db.loadMemoryById(fixture.memoryId)),
        isNull,
      );
      expect(
        await tester.runAsync(
          () => _db.loadAllSessionMemoryDiffs(fixture.sessionId),
        ),
        isEmpty,
      );
      await _disposeTree(tester);
    });
  });

  testWidgets('重试按消息防重入，其他节点可重试且结束后实时恢复按钮', (tester) async {
    late HttpServer server;
    final requests = <HttpRequest>[];
    final fixture = (await tester.runAsync(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await request.drain<void>();
        requests.add(request);
      });
      final fixture = await _createFixture();
      final assistant = await _db.appendAssistantMessage(
        sessionId: fixture.sessionId,
        parentMessageId: fixture.nodeId,
        text: '当前助手消息',
      );
      for (final anchorId in [fixture.rootId, assistant.id]) {
        await _db.upsertExtractionRun(
          MemoryExtractionRun(
            id: 'failed-$anchorId',
            sessionId: fixture.sessionId,
            branchLeafId: anchorId,
            processedMessageIds: [anchorId],
            status: MemoryExtractionStatus.failed,
            createdAt: DateTime.now(),
          ),
        );
      }
      apiConfigsNotifier.value = [
        ApiConfig(
          id: 'local-memory-ui',
          name: '本地测试接口',
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'test-only',
          models: const [ApiModel(id: 'local-model', modelId: 'local-model')],
        ),
      ];
      selectedApiModelIdNotifier.value = 'local-model';
      return _MemoryFixture(
        sessionId: fixture.sessionId,
        rootId: fixture.rootId,
        nodeId: assistant.id,
        memoryId: fixture.memoryId,
      );
    }))!;
    addTearDown(() => server.close(force: true));
    await _pumpTree(tester, fixture, nodeCount: 3);
    await _openActions(tester, 2);

    // 同一帧内重复触发旧回调，也不能再次发请求或多弹出一层页面。
    final retry = _textButton(tester, '重试').onPressed!;
    retry();
    retry();
    await _pumpUntil(tester, () => requests.isNotEmpty);
    expect(requests, hasLength(1));
    expect(find.byType(MemoryTreePage), findsOneWidget);
    await _openActions(tester, 2);
    expect(_textButton(tester, '重试中…').onPressed, isNull);
    for (final label in ['编辑记忆', '切换', '删除']) {
      expect(_textButton(tester, label).onPressed, isNotNull);
    }

    await _dismissActions(tester);
    await _openActions(tester, 0);
    expect(find.text('祖先消息'), findsOneWidget);
    expect(_textButton(tester, '重试').onPressed, isNotNull);
    await tester.tap(find.widgetWithText(TextButton, '重试'));
    await _pumpUntil(tester, () => requests.length == 2);

    await _openActions(tester, 2);
    expect(_textButton(tester, '重试中…').onPressed, isNull);
    await tester.runAsync(() async {
      requests.first.response.statusCode = HttpStatus.internalServerError;
      requests.first.response.write('test failure');
      await requests.first.response.close();
    });
    await _pumpUntil(
      tester,
      () => find.widgetWithText(TextButton, '重试').evaluate().isNotEmpty,
    );
    expect(_textButton(tester, '重试').onPressed, isNotNull);
    expect(requests, hasLength(2));

    await _dismissActions(tester);
    await _openActions(tester, 0);
    expect(_textButton(tester, '重试中…').onPressed, isNull);
    await tester.runAsync(() async {
      requests.last.response.headers.contentType = ContentType.json;
      requests.last.response.write(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': '{"ops":[]}'},
            },
          ],
        }),
      );
      await requests.last.response.close();
    });
    await _pumpUntil(
      tester,
      () => find.widgetWithText(TextButton, '重试').evaluate().isNotEmpty,
    );
    expect(_textButton(tester, '重试').onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });
}
