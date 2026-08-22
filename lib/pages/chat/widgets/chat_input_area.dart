import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../data/app_settings.dart';
import '../../../data/mock_user_settings.dart';
import '../../../models/world_book.dart';
import '../../../services/regex_rule_group_service.dart';

class ChatInputArea extends StatelessWidget {
  const ChatInputArea({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.inputTapRegionGroupId,
    required this.sessionKey,
    required this.isSendEnabled,
    required this.isSending,
    required this.hasBackground,
    required this.settings,
    required this.worldBooks,
    required this.selectedWorldBookIds,
    required this.regexRuleGroups,
    required this.selectedRegexRuleGroupIds,
    required this.currentUserSetting,
    required this.onUserSettingsPressed,
    required this.onWorldBookPressed,
    required this.onRegexRuleGroupPressed,
    required this.onPresetPressed,
    required this.galModeEnabled,
    required this.onGalModeToggle,
    required this.onSendPressed,
    required this.onStopGeneratingPressed,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final Object inputTapRegionGroupId;
  final Key? sessionKey;
  final bool isSendEnabled;
  final bool isSending;
  final bool hasBackground;
  final AppSettings settings;
  final List<WorldBook> worldBooks;
  final Set<String> selectedWorldBookIds;
  final List<RegexRuleGroupSummary> regexRuleGroups;
  final Set<String> selectedRegexRuleGroupIds;
  final UserSetting? currentUserSetting;
  final ValueChanged<BuildContext> onUserSettingsPressed;
  final ValueChanged<BuildContext> onWorldBookPressed;
  final ValueChanged<BuildContext> onRegexRuleGroupPressed;
  final ValueChanged<BuildContext> onPresetPressed;
  final bool galModeEnabled;
  final VoidCallback onGalModeToggle;
  final VoidCallback onSendPressed;
  final VoidCallback onStopGeneratingPressed;

  Widget _wrapTapRegion(Widget child) {
    return TextFieldTapRegion(groupId: inputTapRegionGroupId, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasWorldBooks = worldBooks.isNotEmpty;
    final selectedWorldBooks = worldBooks
        .where((item) => selectedWorldBookIds.contains(item.id))
        .toList();
    final worldBookColor = selectedWorldBooks.isNotEmpty
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final hasRegexRuleGroups = regexRuleGroups.isNotEmpty;
    final selectedRegexRuleGroupCount = regexRuleGroups
        .where((item) => selectedRegexRuleGroupIds.contains(item.id))
        .length;
    final regexRuleGroupColor = selectedRegexRuleGroupCount > 0
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final galModeColor = galModeEnabled
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final useGlassEffect = hasBackground && settings.inputGlassEffect;
    final sendButtonBackgroundColor = isSending
        ? colorScheme.errorContainer
        : isSendEnabled
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final sendButtonForegroundColor = isSending
        ? colorScheme.onErrorContainer
        : isSendEnabled
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    Widget inputContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            key: sessionKey,
            controller: textController,
            focusNode: focusNode,
            groupId: inputTapRegionGroupId,
            maxLines: 5,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '输入消息',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
          child: Row(
            children: [
              Builder(
                builder: (context) => ValueListenableBuilder<List<UserSetting>>(
                  valueListenable: userSettingsNotifier,
                  builder: (context, userSettings, _) {
                    if (userSettings.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final selectedSetting = currentUserSetting;
                    if (selectedSetting == null) {
                      return const SizedBox.shrink();
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: TextButton.icon(
                        onPressed: () => onUserSettingsPressed(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(40, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selectedSetting.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedSetting.avatarText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          selectedSetting.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu_book_rounded,
                    size: 22,
                    color: worldBookColor,
                  ),
                  onPressed: hasWorldBooks
                      ? () => onWorldBookPressed(context)
                      : null,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  tooltip: '世界书',
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.find_replace_rounded,
                    size: 22,
                    color: regexRuleGroupColor,
                  ),
                  onPressed: hasRegexRuleGroups
                      ? () => onRegexRuleGroupPressed(context)
                      : null,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  tooltip: '正则替换',
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.tune, size: 24),
                  onPressed: () => onPresetPressed(context),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  tooltip: '预设',
                ),
              ),
              IconButton(
                icon: Icon(
                  galModeEnabled
                      ? Icons.auto_stories
                      : Icons.auto_stories_outlined,
                  size: 22,
                  color: galModeColor,
                ),
                onPressed: onGalModeToggle,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                tooltip: galModeEnabled ? '退出 gal 模式' : 'gal 模式',
              ),
              const Spacer(),
              IconButton(
                onPressed: isSending
                    ? onStopGeneratingPressed
                    : (isSendEnabled ? onSendPressed : null),
                icon: Icon(
                  isSending ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  size: 15,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(30, 30),
                  fixedSize: const Size(30, 30),
                  backgroundColor: sendButtonBackgroundColor,
                  disabledBackgroundColor: sendButtonBackgroundColor,
                  foregroundColor: sendButtonForegroundColor,
                  disabledForegroundColor: sendButtonForegroundColor.withValues(
                    alpha: 0.62,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                tooltip: isSending ? '终止生成' : '发送',
              ),
            ],
          ),
        ),
      ],
    );
    inputContent = _wrapTapRegion(inputContent);

    if (useGlassEffect) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colorScheme.surface.withValues(alpha: 0.4),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: inputContent,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: inputContent,
    );
  }
}
