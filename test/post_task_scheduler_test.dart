import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/services/post_task_scheduler.dart';

void main() {
  final scheduler = PostTaskScheduler.instance;

  setUp(scheduler.resetForTest);

  test('同类型任务串行执行', () async {
    final log = <String>[];
    final gate = Completer<void>();

    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:a',
      run: (ensureFresh) async {
        log.add('A:start');
        await gate.future;
        log.add('A:end');
      },
    );
    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:b',
      run: (ensureFresh) async {
        log.add('B:start');
      },
    );
    await pumpEventQueue();
    expect(log, ['A:start'], reason: '后到的同类型任务应等待前一个完成');

    gate.complete();
    await pumpEventQueue();
    expect(log, ['A:start', 'A:end', 'B:start']);
  });

  test('全局并发上限为 2，不同任务类型可并行', () async {
    final log = <String>[];
    final gate1 = Completer<void>();
    final gate2 = Completer<void>();

    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:a',
      run: (_) async {
        log.add('A:start');
        await gate1.future;
        log.add('A:end');
      },
    );
    scheduler.schedule(
      kind: PostTaskKind.memoryExtraction,
      sessionId: 's1',
      anchorKey: 'memory:a',
      run: (_) async {
        log.add('B:start');
        await gate2.future;
        log.add('B:end');
      },
    );
    scheduler.schedule(
      kind: PostTaskKind.galChoices,
      sessionId: 's1',
      anchorKey: 'gal:a',
      run: (_) async {
        log.add('C:start');
      },
    );
    await pumpEventQueue();
    expect(log, ['A:start', 'B:start'], reason: '第三个任务应被并发上限拦住');

    gate1.complete();
    await pumpEventQueue();
    expect(log, ['A:start', 'B:start', 'A:end', 'C:start']);

    gate2.complete();
    await pumpEventQueue();
    expect(log, contains('B:end'));
  });

  test('同锚点排队任务被新任务替代，旧任务不再执行', () async {
    final log = <String>[];
    final gate = Completer<void>();

    // 占位任务：占住 status 通道，让后续任务进入排队。
    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:block',
      run: (_) async {
        log.add('block:start');
        await gate.future;
        log.add('block:end');
      },
    );
    await pumpEventQueue();

    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:a',
      run: (_) async {
        log.add('old:run');
      },
      onSkipped: () => log.add('old:skipped'),
    );
    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:a',
      run: (_) async {
        log.add('new:run');
      },
      onSkipped: () => log.add('new:skipped'),
    );

    gate.complete();
    await pumpEventQueue();
    expect(log, contains('old:skipped'));
    expect(log, contains('new:run'));
    expect(log, isNot(contains('old:run')));
    expect(log, isNot(contains('new:skipped')));
  });

  test('运行中任务被同锚点新任务替代时，提交被 ensureFresh 拦截', () async {
    final log = <String>[];
    var firstCommitted = false;
    final gate = Completer<void>();

    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:a',
      run: (ensureFresh) async {
        log.add('first:fetch');
        await gate.future;
        try {
          await ensureFresh();
          firstCommitted = true;
          log.add('first:commit');
        } on PostTaskStaleException {
          log.add('first:stale');
          rethrow;
        }
      },
    );
    await pumpEventQueue();
    expect(log, ['first:fetch']);

    // 运行中调度同锚点新任务：旧任务被标记 superseded。
    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:a',
      run: (_) async {
        log.add('second:run');
      },
      onSkipped: () => log.add('second:skipped'),
    );

    gate.complete();
    await pumpEventQueue();
    expect(firstCommitted, isFalse);
    expect(log, ['first:fetch', 'first:stale', 'second:run']);
    expect(log, isNot(contains('second:skipped')));
  });

  test('isStale 返回 true 时任务被丢弃并回调 onSkipped', () async {
    final log = <String>[];

    scheduler.schedule(
      kind: PostTaskKind.memoryExtraction,
      sessionId: 's1',
      anchorKey: 'memory:a',
      isStale: () async => true,
      run: (_) async {
        log.add('run');
      },
      onSkipped: () => log.add('skipped'),
    );
    await pumpEventQueue();
    expect(log, ['skipped']);
  });

  test('ensureFresh 触发 isStale 时不提交并丢弃任务', () async {
    final log = <String>[];
    var stale = false;

    scheduler.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: 's1',
      anchorKey: 'status:a',
      isStale: () async => stale,
      run: (ensureFresh) async {
        await ensureFresh();
        log.add('fetch:done');
        stale = true; // 模拟任务执行期间消息被编辑
        try {
          await ensureFresh();
          log.add('commit:done');
        } on PostTaskStaleException {
          log.add('commit:blocked');
          rethrow;
        }
      },
      onSkipped: () => log.add('skipped'),
    );
    await pumpEventQueue();
    expect(log, ['fetch:done', 'commit:blocked', 'skipped']);
  });
}
