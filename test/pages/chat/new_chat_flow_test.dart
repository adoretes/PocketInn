import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_inn/pages/chat/widgets/new_chat_flow.dart';
import 'package:pocket_inn/services/character_service.dart';
import 'package:pocket_inn/services/storage_service.dart';

import '../../helpers/test_env.dart';

/// 「新建聊天」共享流程的草稿页构建契约。
///
/// 聊天页与侧边栏都依赖 [buildNewChatDraftPage]，这里验证它按角色卡生成
/// 开场白并带上角色、标题等草稿参数，避免入口改动后草稿内容走样。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await CharacterService.instance.initialize();
  });

  tearDownAll(() async {
    await CharacterService.instance.clearAllData();
    tearDownPathProviderMocks(tempDir);
  });

  setUp(() async {
    await CharacterService.instance.clearAllData();
  });

  test('buildNewChatDraftPage 为指定角色构建草稿页并生成开场白', () async {
    final base = CharacterService.instance.buildEmptyCard();
    final data = Map<String, dynamic>.from(base['data'] as Map);
    data['name'] = '爱丽丝';
    data['first_mes'] = '你好，{{user}}';
    final record = await CharacterService.instance.createFromCard(
      cardJson: {...base, 'data': data},
    );

    final chat = await buildNewChatDraftPage(record.toSummary());

    expect(chat, isNotNull);
    expect(chat!.sessionId, isNull, reason: '新建聊天应进入草稿而不是既有会话');
    expect(chat.draftCharacterId, record.id);
    expect(chat.draftTitle, '爱丽丝');
    expect(chat.draftOpeningAssistantMessages, contains('你好，默认用户'));
  });
}
