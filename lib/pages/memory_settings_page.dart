import 'package:flutter/material.dart';

import '../models/chat_memory.dart';
import '../services/chat_memory_service.dart';
import 'general_settings_page.dart';

class MemorySettingsPage extends StatelessWidget {
  const MemorySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('长期记忆配置')),
      body: ValueListenableBuilder<MemoryExtractionConfig>(
        valueListenable: memoryExtractionNotifier,
        builder: (context, memoryConfig, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MemorySettingsCard(memoryConfig: memoryConfig),
            ],
          );
        },
      ),
    );
  }
}
