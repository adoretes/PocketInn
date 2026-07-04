import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/app_settings_service.dart';
import '../../../services/font_service.dart';

class ThemeFontFamilyConfigTile extends StatefulWidget {
  const ThemeFontFamilyConfigTile({
    super.key,
    required this.fontFamily,
    required this.onChanged,
  });

  final String? fontFamily;
  final ValueChanged<String?> onChanged;

  @override
  State<ThemeFontFamilyConfigTile> createState() =>
      _ThemeFontFamilyConfigTileState();
}

class _ThemeFontFamilyConfigTileState extends State<ThemeFontFamilyConfigTile> {
  late final TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.fontFamily ?? '');
  }

  @override
  void didUpdateWidget(covariant ThemeFontFamilyConfigTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontFamily != widget.fontFamily) {
      _controller.text = widget.fontFamily ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commitFontFamily() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      widget.onChanged(null);
    } else {
      widget.onChanged(trimmed);
    }
  }

  Future<void> _pickFontFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final filePath = result.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    setState(() => _loading = true);

    try {
      final fileName = result.files.single.name;
      final dotIndex = fileName.lastIndexOf('.');
      final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;

      await FontService.instance.removeCustomFont();
      final destPath = await FontService.instance.installFontFile(
        filePath,
        baseName,
      );

      if (destPath != null) {
        await AppSettingsService.instance.saveCustomFontFilePath(destPath);
        widget.onChanged(baseName);
        _controller.text = baseName;
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _clearFont() async {
    await FontService.instance.removeCustomFont();
    _controller.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFont = widget.fontFamily != null && widget.fontFamily!.isNotEmpty;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '自定义字体',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '输入字体族名称，或加载 .ttf/.otf 字体文件',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '字体族名称',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged(null);
                        },
                      )
                    : null,
              ),
              onEditingComplete: _commitFontFamily,
              onSubmitted: (_) => _commitFontFamily(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _loading ? null : _pickFontFile,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_open, size: 18),
                  label: Text(_loading ? '加载中...' : '加载字体文件'),
                ),
                if (hasFont) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearFont,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('清除'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
