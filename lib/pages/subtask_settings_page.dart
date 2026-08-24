import 'package:flutter/material.dart';

import '../data/api_configs.dart';
import '../data/app_settings.dart';
import '../models/chat_memory.dart';
import '../services/chat_memory_service.dart';
import '../services/status_extraction_service.dart';
import '../widgets/settings_controls.dart';

/// 子任务设置页的分区。
enum SubTaskSettingsSection { memory, status, gal }

/// 子任务设置：长期记忆提取、状态变量提取、Gal 选项生成的集中配置页。
class SubTaskSettingsPage extends StatefulWidget {
  const SubTaskSettingsPage({super.key, this.initialSection});

  /// 打开页面时滚动定位到的分区（供记忆树/变量调试页深链）。null 时从顶部开始。
  final SubTaskSettingsSection? initialSection;

  @override
  State<SubTaskSettingsPage> createState() => _SubTaskSettingsPageState();
}

class _SubTaskSettingsPageState extends State<SubTaskSettingsPage> {
  final GlobalKey _memorySectionKey = GlobalKey();
  final GlobalKey _statusSectionKey = GlobalKey();
  final GlobalKey _galSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final section = widget.initialSection;
    if (section != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final key = switch (section) {
          SubTaskSettingsSection.memory => _memorySectionKey,
          SubTaskSettingsSection.status => _statusSectionKey,
          SubTaskSettingsSection.gal => _galSectionKey,
        };
        final context = key.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.05,
            duration: const Duration(milliseconds: 300),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('子任务设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<MemoryExtractionConfig>(
            valueListenable: memoryExtractionNotifier,
            builder: (context, memoryConfig, _) => KeyedSubtree(
              key: _memorySectionKey,
              child: _MemoryExtractionSection(memoryConfig: memoryConfig),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<StatusExtractionConfig>(
            valueListenable: statusExtractionNotifier,
            builder: (context, statusConfig, _) => KeyedSubtree(
              key: _statusSectionKey,
              child: _StatusExtractionSection(config: statusConfig),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<AppSettings>(
            valueListenable: appSettingsNotifier,
            builder: (context, settings, _) => KeyedSubtree(
              key: _galSectionKey,
              child: _GalChoiceSection(settings: settings),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分区卡片内相邻扁平行之间的细分隔线。
Widget _flatDivider(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
  );
}

class _MemoryExtractionSection extends StatelessWidget {
  const _MemoryExtractionSection({required this.memoryConfig});

  final MemoryExtractionConfig memoryConfig;

  @override
  Widget build(BuildContext context) {
    final apiConfigs = apiConfigsNotifier.value;

    return SettingsSectionCard(
      title: '长期记忆提取',
      subtitle: '自动提取对话中的关键信息，在后续对话中作为上下文参考',
      childGap: 12,
      child: Column(
        children: [
          SettingsSwitchTile(
            title: '启用长期记忆',
            subtitle: '系统自动提取和管理记忆点',
            value: memoryConfig.enabled,
            onChanged: (value) => updateMemoryExtractionConfig(enabled: value),
            flat: true,
          ),
          if (memoryConfig.enabled) ...[
            _flatDivider(context),
            SettingsSliderTile(
              title: '提取间隔',
              subtitle: '每 X 轮对话提取一次记忆',
              value: memoryConfig.interval.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              displayValue: (v) => '${v.toInt()} 轮',
              onChanged: (value) =>
                  updateMemoryExtractionConfig(interval: value.toInt()),
              flat: true,
            ),
            _flatDivider(context),
            SettingsSliderTile(
              title: '最近对话轮数',
              subtitle: '拼入提示词的最近 N 轮对话',
              value: memoryConfig.recentRounds.toDouble(),
              min: 0,
              max: 50,
              divisions: 50,
              displayValue: (v) => v.toInt() == 0 ? '无限制' : '${v.toInt()} 轮',
              onChanged: (value) =>
                  updateMemoryExtractionConfig(recentRounds: value.toInt()),
              flat: true,
            ),
            _flatDivider(context),
            SettingsSliderTile(
              title: '记忆节点数',
              subtitle: '拼入提示词的历史记忆节点数量',
              value: memoryConfig.recallCount.toDouble(),
              min: 0,
              max: 50,
              divisions: 50,
              displayValue: (v) => v.toInt() == 0 ? '无限制' : '${v.toInt()} 个',
              onChanged: (value) =>
                  updateMemoryExtractionConfig(recallCount: value.toInt()),
              flat: true,
            ),
            if (apiConfigs.any((c) => c.models.isNotEmpty)) ...[
              _flatDivider(context),
              ModelPickerTile(
                title: '记忆提取模型',
                modelId: memoryConfig.extractionModelId,
                onChanged: (id) =>
                    updateMemoryExtractionConfig(extractionModelId: id),
                flat: true,
              ),
            ],
            _flatDivider(context),
            PromptEditorTile(
              title: '记忆提取提示词',
              dialogTitle: '记忆提取提示词',
              prompt: memoryConfig.customExtractionPrompt,
              defaultPrompt: ChatMemoryService.memoryExtractionPrompt,
              onChanged: (value) => updateMemoryExtractionConfig(
                customExtractionPrompt: value,
              ),
              hintText: '输入 System Prompt，指导 AI 如何提取记忆...',
              minLines: 10,
              flat: true,
            ),
            _flatDivider(context),
            PromptEditorTile(
              title: '记忆注入提示词',
              dialogTitle: '记忆注入提示词',
              prompt: memoryConfig.customInjectionPrompt,
              defaultPrompt: '以下是角色记得的关于过去事件的信息：',
              onChanged: (value) => updateMemoryExtractionConfig(
                customInjectionPrompt: value,
              ),
              hintText: '输入记忆注入时使用的引导语...',
              minLines: 5,
              flat: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusExtractionSection extends StatelessWidget {
  const _StatusExtractionSection({required this.config});

  final StatusExtractionConfig config;

  @override
  Widget build(BuildContext context) {
    final apiConfigs = apiConfigsNotifier.value;

    return SettingsSectionCard(
      title: '状态变量提取',
      subtitle: '角色回复后自动分析剧情变化，写入状态变量差量（{{getstate}} 等宏）',
      childGap: 12,
      child: Column(
        children: [
          SettingsSwitchTile(
            title: '自动提取',
            subtitle: '角色回复完成后自动发起状态提取调用',
            value: config.enabled,
            onChanged: (value) => updateStatusExtractionConfig(enabled: value),
            flat: true,
          ),
          _flatDivider(context),
          SettingsSliderTile(
            title: '参与提取的最近消息数',
            subtitle: '拼入提取上下文的最近消息条数（不含最新回复本身）',
            value: config.recentMessages.toDouble(),
            min: kStatusExtractionRecentMessagesMin.toDouble(),
            max: kStatusExtractionRecentMessagesMax.toDouble(),
            divisions:
                kStatusExtractionRecentMessagesMax -
                kStatusExtractionRecentMessagesMin,
            displayValue: (v) => '${v.toInt()} 条',
            onChanged: (value) =>
                updateStatusExtractionConfig(recentMessages: value.toInt()),
            flat: true,
          ),
          if (apiConfigs.any((c) => c.models.isNotEmpty)) ...[
            _flatDivider(context),
            ModelPickerTile(
              title: '状态提取模型',
              modelId: config.extractionModelId,
              onChanged: (id) =>
                  updateStatusExtractionConfig(extractionModelId: id),
              flat: true,
            ),
          ],
          _flatDivider(context),
          PromptEditorTile(
            title: '状态提取提示词',
            dialogTitle: '状态提取提示词',
            prompt: config.customPrompt,
            defaultPrompt: kDefaultStatusExtractionPrompt,
            onChanged: (value) =>
                updateStatusExtractionConfig(customPrompt: value),
            hintText: '输入系统提示词，{{state}} 会替换为当前变量 JSON',
            minLines: 10,
            flat: true,
          ),
        ],
      ),
    );
  }
}

class _GalChoiceSection extends StatelessWidget {
  const _GalChoiceSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Gal 模式',
      subtitle: '视觉小说选项生成配置',
      childGap: 12,
      child: Column(
        children: [
          SettingsSwitchTile(
            title: '自动生成选项',
            subtitle: '角色回复后自动生成选项，关闭后仅可通过刷新按钮手动生成',
            value: settings.galChoiceAutoGenerate,
            onChanged: (value) =>
                updateAppSettings(galChoiceAutoGenerate: value),
            flat: true,
          ),
          _flatDivider(context),
          SettingsSliderTile(
            title: '选项数量',
            subtitle: '每次生成的玩家选项数量',
            value: settings.galChoiceCount.toDouble(),
            min: kGalChoiceCountMin.toDouble(),
            max: kGalChoiceCountMax.toDouble(),
            divisions: kGalChoiceCountMax - kGalChoiceCountMin,
            displayValue: (value) => '${value.toInt()} 个',
            onChanged: (value) =>
                updateAppSettings(galChoiceCount: value.toInt()),
            flat: true,
          ),
          _flatDivider(context),
          ModelPickerTile(
            title: '选项生成模型',
            modelId: settings.galChoiceApiModelId,
            onChanged: (id) => updateAppSettings(galChoiceApiModelId: id),
            flat: true,
          ),
          _flatDivider(context),
          PromptEditorTile(
            title: '选项生成提示词',
            dialogTitle: '选项生成提示词',
            prompt: settings.galChoicePrompt ?? '',
            defaultPrompt: kDefaultGalChoicePrompt,
            onChanged: (value) {
              final trimmed = value.trim();
              updateAppSettings(
                galChoicePrompt:
                    trimmed.isEmpty || trimmed == kDefaultGalChoicePrompt.trim()
                    ? null
                    : trimmed,
              );
            },
            hintText: '支持 {{user}}、{{char}}、{{count}} 占位符',
            minLines: 8,
            flat: true,
          ),
        ],
      ),
    );
  }
}