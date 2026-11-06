import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/pages/chat/streaming_message_snapshot.dart';
import 'package:pocket_inn/pages/chat/widgets/gal_message_view.dart';
import 'package:pocket_inn/pages/chat/widgets/message_view_params.dart';
import 'package:pocket_inn/services/regex_rule_group_service.dart';
import 'package:pocket_inn/services/storage_service.dart';

import '../../helpers/test_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await RegexRuleGroupService.instance.initialize();
  });

  tearDownAll(() {
    tearDownPathProviderMocks(tempDir);
  });

  final message = const ChatMessage(id: 'a1', text: '她抬头看向你。', isMe: false);

  MessageViewParams buildParams() {
    return MessageViewParams(
      visibleMessages: [message],
      streamingMessageListenable: ValueNotifier(StreamingMessageSnapshot.empty),
      inputTapRegionGroupId: Object(),
      isSending: false,
      isImpersonating: false,
      regeneratingUserMessageId: null,
      isDraftSession: false,
      activeCharacter: null,
      currentUserSetting: null,
      hasBackground: false,
      backgroundAreaSize: null,
      backgroundAreaTop: 0,
      sessionId: 's1',
      selectedRegexRuleGroupIds: const {},
      onCopyMessage: (_) {},
      onEditMessage: (_) {},
      onEditDraftOpeningMessage: () {},
      onDeleteMessage: (_) {},
      onRegenerateFromUserMessage: (_) {},
      onRegenerateMessage: (_) {},
      onContinueMessage: (_) {},
      onImpersonate: () {},
      onSwitchMessageVariant: (_, _) {},
    );
  }

  Widget buildView({
    required List<String> picked,
    required List<String> filled,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GalMessageView(
          params: buildParams(),
          updatesListenable: ValueNotifier<int>(0),
          visibleMessagesProvider: () => [message],
          browsingIndex: null,
          onBrowsingIndexChanged: (_) {},
          galChoices: const ['推开房门'],
          isGeneratingGalChoices: false,
          galChoicesMessageId: 'a1',
          galChoicesError: false,
          onPickGalChoice: picked.add,
          onFillGalChoice: filled.add,
          onRefreshGalChoices: () {},
        ),
      ),
    );
  }

  testWidgets('点击 gal 选项发送，长按选项仅填入不发送', (tester) async {
    final picked = <String>[];
    final filled = <String>[];

    await tester.pumpWidget(buildView(picked: picked, filled: filled));
    await tester.pumpAndSettle();

    final choice = find.text('推开房门');
    expect(choice, findsOneWidget);

    // 长按：走填入回调，不触发发送。
    await tester.longPress(choice);
    await tester.pump();
    expect(filled, ['推开房门']);
    expect(picked, isEmpty);

    // 点击：仍走原有发送回调。
    await tester.tap(choice);
    await tester.pump();
    expect(picked, ['推开房门']);
  });
}
