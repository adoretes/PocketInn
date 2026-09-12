import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/models/chat_variables.dart';
import 'package:pocket_inn/pages/chat/widgets/chat_side_panel.dart';

void main() {
  VariableState stateOf(Map<String, ChatVariable> variables) {
    return VariableState.fromVariables(variables);
  }

  ChatSidePanelContent buildContent({
    String? sessionTitle = '测试聊天',
    bool hasSession = true,
    bool isDraftSession = false,
    bool isLoading = false,
    String? errorText,
    VariableState? currentState,
    bool initDeclared = true,
    VariableState? draftState,
    int memoryCount = 0,
    Future<void> Function()? onRefresh,
    VoidCallback? onOpenMemoryManager,
    VoidCallback? onOpenVariablePage,
  }) {
    return ChatSidePanelContent(
      sessionTitle: sessionTitle,
      hasSession: hasSession,
      isDraftSession: isDraftSession,
      isLoading: isLoading,
      errorText: errorText,
      currentState: currentState ?? VariableState.empty(),
      initDeclared: initDeclared,
      draftState: draftState ?? VariableState.empty(),
      memoryCount: memoryCount,
      onRefresh: onRefresh ?? () async {},
      onOpenMemoryManager: onOpenMemoryManager ?? () {},
      onOpenVariablePage: onOpenVariablePage ?? () {},
    );
  }

  Future<void> pumpContent(
    WidgetTester tester,
    ChatSidePanelContent content, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, height: 640, child: content),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // 加载态里有无限动画的进度指示，pumpAndSettle 会超时。
      await tester.pump();
    }
  }

  ListTile memoryTile(WidgetTester tester) {
    return tester.widget<ListTile>(
      find.ancestor(
        of: find.text('长期记忆'),
        matching: find.byType(ListTile),
      ),
    );
  }

  IconButton buttonWithTooltip(WidgetTester tester, String tooltip) {
    return tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );
  }

  testWidgets('有变量时逐行显示名称、取值与类型/选项', (tester) async {
    await pumpContent(
      tester,
      buildContent(
        memoryCount: 3,
        currentState: stateOf({
          '好感度': const ChatVariable(
            name: '好感度',
            type: ChatVariableType.number,
            value: '12',
            metadata: ChatVariableMetadata(minValue: 0, maxValue: 100),
          ),
          '心情': const ChatVariable(
            name: '心情',
            type: ChatVariableType.enumType,
            value: '愉快',
            metadata: ChatVariableMetadata(enumOptions: ['愉快', '低落']),
          ),
        }),
      ),
    );

    expect(find.text('记忆与状态'), findsOneWidget);
    expect(find.text('测试聊天'), findsOneWidget);
    expect(find.text('3 条记忆'), findsOneWidget);
    expect(find.text('好感度'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('数值'), findsOneWidget);
    expect(find.textContaining('0.0 ~ 100.0'), findsOneWidget);
    expect(find.text('心情'), findsOneWidget);
    expect(find.text('愉快'), findsOneWidget);
    expect(find.textContaining('选项: 愉快/低落'), findsOneWidget);
  });

  testWidgets('空状态区分「未声明初始变量」与「暂无变化」', (tester) async {
    await pumpContent(
      tester,
      buildContent(initDeclared: false),
    );
    expect(find.textContaining('角色卡未声明初始状态变量'), findsOneWidget);

    await pumpContent(
      tester,
      buildContent(initDeclared: true),
    );
    expect(find.textContaining('暂无变量（初始变量尚未发生任何变化）'), findsOneWidget);
  });

  testWidgets('草稿会话显示初始变量预览并禁用会话内入口', (tester) async {
    var openedMemory = false;
    await pumpContent(
      tester,
      buildContent(
        isDraftSession: true,
        draftState: stateOf({
          '好感度': const ChatVariable(
            name: '好感度',
            type: ChatVariableType.number,
            value: '0',
          ),
        }),
        onOpenMemoryManager: () => openedMemory = true,
      ),
    );

    expect(find.textContaining('草稿会话'), findsOneWidget);
    expect(find.text('好感度'), findsOneWidget);
    expect(memoryTile(tester).onTap, isNull, reason: '草稿会话不要跳到空记忆树');
    // 禁用态点击不得触发回调。
    await tester.tap(find.text('长期记忆'));
    expect(openedMemory, isFalse);
    expect(find.text('正式开始聊天后可用'), findsOneWidget);
    expect(
      buttonWithTooltip(tester, '刷新').onPressed,
      isNull,
      reason: '草稿会话没有可刷新的会话数据',
    );
    expect(
      buttonWithTooltip(tester, '完整页 / 提取配置').onPressed,
      isNull,
    );
  });

  testWidgets('无会话时提示并禁用入口', (tester) async {
    await pumpContent(tester, buildContent(hasSession: false));

    expect(find.text('暂无会话'), findsOneWidget, reason: '长期记忆副标题');
    expect(find.textContaining('暂无会话：选择或新建一个聊天后显示状态变量'), findsOneWidget);
    expect(memoryTile(tester).onTap, isNull);
    expect(buttonWithTooltip(tester, '刷新').onPressed, isNull);
  });

  testWidgets('加载中显示进度指示', (tester) async {
    await pumpContent(tester, buildContent(isLoading: true), settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('加载失败显示错误与重试', (tester) async {
    var refreshed = 0;
    await pumpContent(
      tester,
      buildContent(errorText: '数据库繁忙', onRefresh: () async => refreshed++),
    );

    expect(find.textContaining('状态加载失败：数据库繁忙'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(refreshed, 1);
  });

  testWidgets('点击长期记忆 / 完整页 / 刷新触发对应回调', (tester) async {
    var openedMemory = 0;
    var openedVariable = 0;
    var refreshed = 0;
    await pumpContent(
      tester,
      buildContent(
        onOpenMemoryManager: () => openedMemory++,
        onOpenVariablePage: () => openedVariable++,
        onRefresh: () async => refreshed++,
      ),
    );

    await tester.tap(find.text('长期记忆'));
    await tester.tap(find.byTooltip('完整页 / 提取配置'));
    await tester.tap(find.byTooltip('刷新'));

    expect(openedMemory, 1);
    expect(openedVariable, 1);
    expect(refreshed, 1);
  });
}
