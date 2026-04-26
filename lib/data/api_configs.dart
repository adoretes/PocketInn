import 'package:flutter/foundation.dart';

import '../models/api_config.dart';
import '../services/api_config_service.dart';

final ValueNotifier<List<ApiConfig>> apiConfigsNotifier =
    ValueNotifier<List<ApiConfig>>([]);

ApiConfig? get enabledApiConfig {
  for (final item in apiConfigsNotifier.value) {
    if (item.enabled) {
      return item;
    }
  }
  return null;
}

Future<void> initializeApiConfigs() async {
  final configs = await ApiConfigService.instance.loadAll();
  apiConfigsNotifier.value = List<ApiConfig>.unmodifiable(configs);
}

Future<void> updateApiConfigs(List<ApiConfig> configs) async {
  final nextConfigs = List<ApiConfig>.unmodifiable(
    configs.map((item) => item.copyWith()).toList(),
  );
  apiConfigsNotifier.value = nextConfigs;
  await ApiConfigService.instance.saveAll(nextConfigs);
}
