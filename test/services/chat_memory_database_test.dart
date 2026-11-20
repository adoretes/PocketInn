import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/chat_memory.dart';
import 'package:pocket_inn/services/chat_database_service.dart';

import '../helpers/test_env.dart';

typedef _Fixture = ({
  String sessionId,
  String rootId,
  String userId,
  String leafId,
  String siblingId,
  MemoryNode memory,
  MemoryNode otherMemory,
});

final _baseTime = DateTime(2026, 1, 1);

MemoryNode _memory({
  required String id,
  required String sessionId,
  required String branchLeafId,
  int seconds = 0,
}) => MemoryNode(
  id: id,
  sessionId: sessionId,
  branchLeafId: branchLeafId,
  content: id,
  createdAt: _baseTime.add(Duration(seconds: seconds)),
  updatedAt: _baseTime.add(Duration(seconds: seconds)),
);

MemoryDiff _diff(
  _Fixture fixture, {
  required String id,
  String? atMessageId,
  String? targetMemoryId,
  int seconds = 0,
}) => MemoryDiff(
  id: id,
  sessionId: fixture.sessionId,
  branchLeafId: atMessageId ?? fixture.leafId,
  targetMemoryId: targetMemoryId ?? fixture.memory.id,
  kind: MemoryDiffKind.update,
  content: id,
  isUserEdited: true,
  createdAt: _baseTime.add(Duration(seconds: seconds)),
);

MemoryExtractionRun _run(
  _Fixture fixture, {
  required String id,
  MemoryExtractionStatus status = MemoryExtractionStatus.applied,
}) => MemoryExtractionRun(
  id: id,
  sessionId: fixture.sessionId,
  branchLeafId: fixture.leafId,
  processedMessageIds: [fixture.userId, fixture.leafId],
  status: status,
  addedCount: status == MemoryExtractionStatus.applied ? 1 : 0,
  createdAt: _baseTime,
);

MemorySnapshotEntry _originOf(MemoryNode memory) => (
  content: memory.content,
  importance: memory.importance,
  type: memory.type,
  isPinned: memory.isPinned,
);

void main() {
  final db = ChatDatabaseService.instance;
  late Directory temporaryData;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temporaryData = setUpPathProviderMocks();
    await db.initialize();
  });

  tearDownAll(() async {
    await db.deleteDatabaseFiles();
    tearDownPathProviderMocks(temporaryData);
  });

  setUp(() async {
    await db.clearAllData();
  });

  Future<_Fixture> fixture() async {
    final session = await db.createSession(
      characterId: 'memory-database-test',
      openingAssistantMessages: ['root'],
    );
    final rootId = session.currentLeafMessageId!;
    final user = await db.appendUserMessage(
      sessionId: session.id,
      parentMessageId: rootId,
      text: 'user',
    );
    final leaf = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: 'leaf',
    );
    final sibling = await db.appendAssistantMessage(
      sessionId: session.id,
      parentMessageId: user.id,
      text: 'sibling',
    );
    final memory = _memory(
      id: 'origin',
      sessionId: session.id,
      branchLeafId: rootId,
    );
    final otherMemory = _memory(
      id: 'other-origin',
      sessionId: session.id,
      branchLeafId: rootId,
      seconds: 1,
    );
    await db.insertMemoriesInTx([memory, otherMemory]);
    return (
      sessionId: session.id,
      rootId: rootId,
      userId: user.id,
      leafId: leaf.id,
      siblingId: sibling.id,
      memory: memory,
      otherMemory: otherMemory,
    );
  }

  Future<MemoryExtractionSnapshot> snapshot(_Fixture f) =>
      db.loadMemoryExtractionSnapshot(
        sessionId: f.sessionId,
        pathMessageIds: [f.rootId, f.userId, f.leafId],
      );

  Future<void> expectUnwritten(
    _Fixture f, {
    required List<String> diffIds,
  }) async {
    expect(
      (await db.loadAllSessionMemories(f.sessionId)).map((m) => m.id).toSet(),
      {f.memory.id, f.otherMemory.id},
    );
    expect(
      (await db.loadAllSessionMemoryDiffs(
        f.sessionId,
      )).map((d) => d.id).toSet(),
      diffIds.toSet(),
    );
    expect(await db.loadAllSessionExtractionRuns(f.sessionId), isEmpty);
  }

  Future<void> submitWithSnapshot(
    _Fixture f,
    MemoryExtractionSnapshot before,
  ) => db.applyMemoryExtractionTx(
    newMemories: [
      _memory(id: 'auto-add', sessionId: f.sessionId, branchLeafId: f.leafId),
    ],
    diffs: [_diff(f, id: 'auto-update')],
    run: _run(f, id: 'auto-run'),
    expectedSnapshot: {f.memory.id: _originOf(f.memory)},
    branchSnapshot: before,
  );

  test('MemoryExtractionSnapshot defensively copies all lists', () async {
    final f = await fixture();
    final memories = [f.memory];
    final diffs = [_diff(f, id: 'copied-diff')];
    final path = [f.rootId, f.userId, f.leafId];
    final frozen = MemoryExtractionSnapshot(
      memories: memories,
      diffs: diffs,
      pathMessageIds: path,
    );
    memories.clear();
    diffs.clear();
    path.clear();

    expect(frozen.memories.single, f.memory);
    expect(frozen.diffs.single.id, 'copied-diff');
    expect(frozen.pathMessageIds, [f.rootId, f.userId, f.leafId]);
    expect(() => frozen.memories.clear(), throwsUnsupportedError);
    expect(() => frozen.diffs.clear(), throwsUnsupportedError);
    expect(() => frozen.pathMessageIds.clear(), throwsUnsupportedError);
  });

  test(
    'snapshot preserves session/path filtering and global order across chunks',
    () async {
      final f = await fixture();
      final otherSession = await db.createSession(
        characterId: 'other-session',
        openingAssistantMessages: ['other-root'],
      );
      await db.insertMemoriesInTx([
        _memory(
          id: 'new-root',
          sessionId: f.sessionId,
          branchLeafId: f.rootId,
          seconds: 3,
        ),
        _memory(
          id: 'new-leaf',
          sessionId: f.sessionId,
          branchLeafId: f.leafId,
          seconds: 2,
        ),
        _memory(
          id: 'sibling-memory',
          sessionId: f.sessionId,
          branchLeafId: f.siblingId,
          seconds: 5,
        ),
        _memory(
          id: 'other-session-memory',
          sessionId: otherSession.id,
          branchLeafId: otherSession.currentLeafMessageId!,
          seconds: 6,
        ),
      ]);
      await db.insertMemoryDiff(
        _diff(f, id: 'late-root-diff', atMessageId: f.rootId, seconds: 4),
      );
      await db.insertMemoryDiff(_diff(f, id: 'early-leaf-diff', seconds: 2));
      await db.insertMemoryDiff(
        _diff(f, id: 'sibling-diff', atMessageId: f.siblingId),
      );
      final path = [
        f.rootId,
        ...List.generate(500, (i) => 'missing-$i'),
        f.userId,
        f.leafId,
        otherSession.currentLeafMessageId!,
      ];
      final loaded = await db.loadMemoryExtractionSnapshot(
        sessionId: f.sessionId,
        pathMessageIds: path,
      );
      expect(loaded.pathMessageIds, path);
      expect(loaded.memories.map((m) => m.id), [
        'new-root',
        'new-leaf',
        'other-origin',
        'origin',
      ]);
      expect(loaded.diffs.map((d) => d.id), [
        'early-leaf-diff',
        'late-root-diff',
      ]);
      expect(await db.loadBranchMemories(f.sessionId, path), loaded.memories);
      expect(await db.loadBranchMemoryDiffs(f.sessionId, path), loaded.diffs);
    },
  );

  test(
    'a new manual diff on the extraction path conflicts without partial writes',
    () async {
      final f = await fixture();
      final before = await snapshot(f);
      await db.insertMemoryDiff(_diff(f, id: 'manual-edit'));
      final notifications = db.memoryChangeNotifier.value;

      await expectLater(
        submitWithSnapshot(f, before),
        throwsA(isA<MemoryExtractionConflict>()),
      );
      await expectUnwritten(f, diffIds: ['manual-edit']);
      expect(db.memoryChangeNotifier.value, notifications);
    },
  );

  test(
    'clearing a captured path diff conflicts without partial writes',
    () async {
      final f = await fixture();
      await db.insertMemoryDiff(_diff(f, id: 'cleared-edit'));
      final before = await snapshot(f);
      await db.deleteMemoryDiffsAtNode(
        sessionId: f.sessionId,
        branchLeafId: f.leafId,
        targetMemoryId: f.memory.id,
      );
      final notifications = db.memoryChangeNotifier.value;

      await expectLater(
        submitWithSnapshot(f, before),
        throwsA(isA<MemoryExtractionConflict>()),
      );
      await expectUnwritten(f, diffIds: []);
      expect(db.memoryChangeNotifier.value, notifications);
    },
  );

  test('sibling and unrelated target edits do not conflict', () async {
    final f = await fixture();
    final before = await snapshot(f);
    await db.insertMemoryDiff(
      _diff(f, id: 'sibling-edit', atMessageId: f.siblingId),
    );
    await db.insertMemoryDiff(
      _diff(f, id: 'unrelated-edit', targetMemoryId: f.otherMemory.id),
    );

    await submitWithSnapshot(f, before);

    expect(await db.loadMemoryById('auto-add'), isNotNull);
    expect(
      (await db.loadAllSessionMemoryDiffs(
        f.sessionId,
      )).map((d) => d.id).toSet(),
      {'sibling-edit', 'unrelated-edit', 'auto-update'},
    );
    expect(
      (await db.loadAllSessionExtractionRuns(f.sessionId)).single.id,
      'auto-run',
    );
  });

  for (final status in MemoryExtractionStatus.values) {
    test(
      'duplicate $status result cannot add memory or replace a successful run',
      () async {
        final f = await fixture();
        final committed = _run(f, id: 'committed');
        await db.applyMemoryExtractionTx(
          newMemories: [
            _memory(
              id: 'first-add',
              sessionId: f.sessionId,
              branchLeafId: f.leafId,
            ),
          ],
          diffs: [],
          run: committed,
          expectedSnapshot: {},
        );
        final notifications = db.memoryChangeNotifier.value;

        await expectLater(
          db.applyMemoryExtractionTx(
            newMemories: [
              _memory(
                id: 'late-add',
                sessionId: f.sessionId,
                branchLeafId: f.leafId,
              ),
            ],
            diffs: [_diff(f, id: 'late-diff')],
            run: _run(f, id: 'late-run', status: status),
            expectedSnapshot: {},
          ),
          throwsA(isA<MemoryExtractionSuperseded>()),
        );

        expect(await db.loadMemoryById('first-add'), isNotNull);
        expect(await db.loadMemoryById('late-add'), isNull);
        expect(await db.loadAllSessionMemoryDiffs(f.sessionId), isEmpty);
        expect(
          (await db.loadAllSessionExtractionRuns(f.sessionId)).single,
          committed,
        );
        expect(db.memoryChangeNotifier.value, notifications);
      },
    );
  }

  test(
    'expected failed run may be replaced with a successful result',
    () async {
      final f = await fixture();
      await db.upsertExtractionRun(
        _run(f, id: 'failed-run', status: MemoryExtractionStatus.failed),
      );
      await db.applyMemoryExtractionTx(
        newMemories: [
          _memory(
            id: 'retry-add',
            sessionId: f.sessionId,
            branchLeafId: f.leafId,
          ),
        ],
        diffs: [],
        run: _run(f, id: 'retry-success'),
        expectedSnapshot: {},
        expectedRunId: 'failed-run',
      );
      final committed = (await db.loadAllSessionExtractionRuns(
        f.sessionId,
      )).single;
      expect(committed.id, 'retry-success');
      expect(committed.status, MemoryExtractionStatus.applied);
      expect(await db.loadMemoryById('retry-add'), isNotNull);

      await expectLater(
        db.applyMemoryExtractionTx(
          newMemories: [
            _memory(
              id: 'stale-retry-add',
              sessionId: f.sessionId,
              branchLeafId: f.leafId,
            ),
          ],
          diffs: [],
          run: _run(
            f,
            id: 'stale-retry',
            status: MemoryExtractionStatus.failed,
          ),
          expectedSnapshot: {},
          expectedRunId: 'failed-run',
        ),
        throwsA(isA<MemoryExtractionSuperseded>()),
      );
      expect(await db.loadMemoryById('stale-retry-add'), isNull);
      expect(
        (await db.loadAllSessionExtractionRuns(f.sessionId)).single,
        committed,
      );
    },
  );

  for (final status in MemoryExtractionStatus.values) {
    test(
      'retry requires both matching id and failed status (existing $status)',
      () async {
        final f = await fixture();
        final existing = _run(f, id: 'existing', status: status);
        await db.upsertExtractionRun(existing);
        await expectLater(
          db.applyMemoryExtractionTx(
            newMemories: [],
            diffs: [],
            run: _run(f, id: 'unexpected'),
            expectedSnapshot: {},
            expectedRunId: status == MemoryExtractionStatus.failed
                ? 'wrong-id'
                : 'existing',
          ),
          throwsA(isA<MemoryExtractionSuperseded>()),
        );
        expect(
          (await db.loadAllSessionExtractionRuns(f.sessionId)).single,
          existing,
        );
      },
    );
  }

  test('retry cannot recreate a missing expected failed run', () async {
    final f = await fixture();
    await expectLater(
      db.applyMemoryExtractionTx(
        newMemories: [],
        diffs: [],
        run: _run(f, id: 'unexpected'),
        expectedSnapshot: {},
        expectedRunId: 'deleted-failure',
      ),
      throwsA(isA<MemoryExtractionSuperseded>()),
    );
    await expectUnwritten(f, diffIds: []);
  });

  for (final retry in [false, true]) {
    test(
      'concurrent ${retry ? 'retry' : 'first'} submissions commit exactly once',
      () async {
        final f = await fixture();
        if (retry) {
          await db.upsertExtractionRun(
            _run(f, id: 'failed-run', status: MemoryExtractionStatus.failed),
          );
        }
        Future<bool> submit(String id) async {
          try {
            await db.applyMemoryExtractionTx(
              newMemories: [
                _memory(id: id, sessionId: f.sessionId, branchLeafId: f.leafId),
              ],
              diffs: [],
              run: _run(f, id: 'run-$id'),
              expectedSnapshot: {},
              expectedRunId: retry ? 'failed-run' : null,
            );
            return true;
          } on MemoryExtractionSuperseded {
            return false;
          }
        }

        final outcomes = await Future.wait([submit('first'), submit('second')]);
        expect(outcomes.where((committed) => committed), hasLength(1));
        final rows = await db.loadAllSessionMemories(f.sessionId);
        final added = rows
            .where((m) => m.id == 'first' || m.id == 'second')
            .toList();
        expect(added, hasLength(1));
        final committed = (await db.loadAllSessionExtractionRuns(
          f.sessionId,
        )).single;
        expect(committed.id, 'run-${added.single.id}');
        expect(committed.status, MemoryExtractionStatus.applied);
      },
    );
  }
}
