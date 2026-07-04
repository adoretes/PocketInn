import 'package:flutter/material.dart';

import '../../../data/app_settings.dart';

int safePaletteIndex(int index) {
  if (index < 0) {
    return 0;
  }
  if (index >= customThemePalette.length) {
    return customThemePalette.length - 1;
  }
  return index;
}

Color paletteColorAt(int index) {
  return customThemePalette[safePaletteIndex(index)];
}

int defaultBodyTextColorPaletteIndex(Brightness brightness) {
  return brightness == Brightness.dark ? 29 : 30;
}

const List<int> orderedPaletteIndices = <int>[
  0,
  13,
  14,
  4,
  11,
  9,
  12,
  8,
  22,
  3,
  20,
  21,
  10,
  23,
  24,
  5,
  16,
  26,
  6,
  17,
  15,
  1,
  18,
  19,
  7,
  25,
  27,
  2,
  28,
  29,
  30,
  31,
];

class PalettePickerButton extends StatelessWidget {
  const PalettePickerButton({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.swatchSize,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double swatchSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = paletteColorAt(selectedIndex);

    Future<void> openPalettePicker() async {
      final next = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          final sheetColorScheme = Theme.of(sheetContext).colorScheme;
          return PalettePickerSheet(
            selectedIndex: selectedIndex,
            colorScheme: sheetColorScheme,
          );
        },
      );
      if (next != null && next != selectedIndex) {
        onChanged(next);
      }
    }

    return Semantics(
      button: true,
      label: '选择颜色',
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: openPalettePicker,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: swatchSize,
                  height: swatchSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedColor,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DualPalettePickerButton extends StatelessWidget {
  const DualPalettePickerButton({
    super.key,
    required this.lightIndex,
    required this.darkIndex,
    required this.onChanged,
    required this.swatchSize,
    required this.lightBackground,
    required this.darkBackground,
  });

  final int lightIndex;
  final int darkIndex;
  final void Function(int lightIndex, int darkIndex) onChanged;
  final double swatchSize;
  final Color lightBackground;
  final Color darkBackground;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lightColor = paletteColorAt(lightIndex);
    final darkColor = paletteColorAt(darkIndex);

    Future<void> openDualPicker({required bool initialDark}) async {
      final result = await showModalBottomSheet<PaletteDualSelection>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          final sheetColorScheme = Theme.of(sheetContext).colorScheme;
          return DualPalettePickerSheet(
            lightIndex: lightIndex,
            darkIndex: darkIndex,
            colorScheme: sheetColorScheme,
            lightBackground: lightBackground,
            darkBackground: darkBackground,
            initialDark: initialDark,
          );
        },
      );
      if (result != null &&
          (result.lightIndex != lightIndex || result.darkIndex != darkIndex)) {
        onChanged(result.lightIndex, result.darkIndex);
      }
    }

    final dotSize = swatchSize * 0.85;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHalf(
            color: lightColor,
            background: lightBackground,
            onTap: () => openDualPicker(initialDark: false),
            colorScheme: colorScheme,
            dotSize: dotSize,
            isLeft: true,
          ),
          Container(
            width: 1,
            height: dotSize + 12,
            color: colorScheme.outlineVariant,
          ),
          _buildHalf(
            color: darkColor,
            background: darkBackground,
            onTap: () => openDualPicker(initialDark: true),
            colorScheme: colorScheme,
            dotSize: dotSize,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildHalf({
    required Color color,
    required Color background,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required double dotSize,
    required bool isLeft,
  }) {
    return Semantics(
      button: true,
      label: isLeft ? '选择浅色颜色' : '选择深色颜色',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(isLeft ? 20 : 0),
            right: Radius.circular(isLeft ? 0 : 20),
          ),
          child: Container(
            padding: isLeft
                ? const EdgeInsets.only(left: 5, right: 10, top: 6, bottom: 6)
                : const EdgeInsets.only(left: 10, right: 5, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(isLeft ? 20 : 0),
                right: Radius.circular(isLeft ? 0 : 20),
              ),
            ),
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaletteDualSelection {
  const PaletteDualSelection({
    required this.lightIndex,
    required this.darkIndex,
  });
  final int lightIndex;
  final int darkIndex;
}

class PalettePickerSheet extends StatelessWidget {
  const PalettePickerSheet({
    super.key,
    required this.selectedIndex,
    required this.colorScheme,
  });

  final int selectedIndex;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '选择颜色',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: paletteColorAt(selectedIndex),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ColorPaletteWrap(
              selectedIndex: selectedIndex,
              onChanged: (index) => Navigator.of(context).pop(index),
              activeBorderColor: colorScheme.primary,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class DualPalettePickerSheet extends StatefulWidget {
  const DualPalettePickerSheet({
    super.key,
    required this.lightIndex,
    required this.darkIndex,
    required this.colorScheme,
    required this.lightBackground,
    required this.darkBackground,
    this.initialDark = false,
  });

  final int lightIndex;
  final int darkIndex;
  final ColorScheme colorScheme;
  final Color lightBackground;
  final Color darkBackground;
  final bool initialDark;

  @override
  State<DualPalettePickerSheet> createState() => _DualPalettePickerSheetState();
}

class _DualPalettePickerSheetState extends State<DualPalettePickerSheet> {
  late int _lightIndex;
  late int _darkIndex;
  late bool _activeIsDark;

  @override
  void initState() {
    super.initState();
    _lightIndex = widget.lightIndex;
    _darkIndex = widget.darkIndex;
    _activeIsDark = widget.initialDark;
  }

  int get _activeIndex => _activeIsDark ? _darkIndex : _lightIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '选择颜色',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                _buildModeSwitcher(),
              ],
            ),
            const SizedBox(height: 18),
            ColorPaletteWrap(
              selectedIndex: _activeIndex,
              onChanged: (index) {
                setState(() {
                  if (_activeIsDark) {
                    _darkIndex = index;
                  } else {
                    _lightIndex = index;
                  }
                });
              },
              activeBorderColor: colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  PaletteDualSelection(
                    lightIndex: _lightIndex,
                    darkIndex: _darkIndex,
                  ),
                ),
                child: const Text('确认'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSwatch(
          label: '浅色',
          background: widget.lightBackground,
          color: paletteColorAt(_lightIndex),
          active: !_activeIsDark,
          onTap: () => setState(() => _activeIsDark = false),
        ),
        const SizedBox(width: 8),
        _buildSwatch(
          label: '深色',
          background: widget.darkBackground,
          color: paletteColorAt(_darkIndex),
          active: _activeIsDark,
          onTap: () => setState(() => _activeIsDark = true),
        ),
      ],
    );
  }

  Widget _buildSwatch({
    required String label,
    required Color background,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    final colorScheme = widget.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: background,
          border: Border.all(
            color: active ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorPaletteWrap extends StatelessWidget {
  const ColorPaletteWrap({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.activeBorderColor,
    required this.size,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color activeBorderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paletteIndices = orderedPaletteIndices
        .where((index) => index >= 0 && index < customThemePalette.length)
        .toList(growable: false);

    return GridView.count(
      crossAxisCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List<Widget>.generate(paletteIndices.length, (displayIndex) {
        final index = paletteIndices[displayIndex];
        final color = paletteColorAt(index);
        final selected = selectedIndex == index;
        final iconColor =
            ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;

        return InkWell(
          onTap: () => onChanged(index),
          borderRadius: BorderRadius.circular(size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected
                    ? activeBorderColor
                    : colorScheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: activeBorderColor.withValues(alpha: 0.24),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: size * 0.58, color: iconColor)
                : null,
          ),
        );
      }),
    );
  }
}
