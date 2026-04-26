import 'package:flutter/foundation.dart';

import '../services/preset_service.dart';

final ValueNotifier<String?> selectedPresetIdNotifier = ValueNotifier<String?>(
  null,
);

Future<void> initializeSelectedPreset() async {
  selectedPresetIdNotifier.value = PresetService.instance.selectedPresetId;
}

Future<void> setSelectedPreset(String id) async {
  await PresetService.instance.setSelectedPresetId(id);
  selectedPresetIdNotifier.value = PresetService.instance.selectedPresetId;
}
