import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// 测试用 path_provider mock：把应用目录指向独立临时目录。
///
/// 返回该目录；测试结束时用 [tearDownPathProviderMocks] 清理
/// （同一文件内的多个用例共用一次 setup/teardown 即可）。
Directory setUpPathProviderMocks() {
  final tempDir = Directory.systemTemp.createTempSync('pocket_inn_test_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
        return tempDir.path;
      });
  return tempDir;
}

/// 移除 path_provider mock 并尽量删除临时目录。
void tearDownPathProviderMocks(Directory tempDir) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, null);
  if (tempDir.existsSync()) {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows 下文件句柄可能延迟释放，临时目录留给系统清理即可。
    }
  }
}
