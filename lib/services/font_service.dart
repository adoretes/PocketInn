import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app_settings_service.dart';

class FontService {
  FontService._();

  static final FontService instance = FontService._();

  static const String _fontsDirName = 'custom_fonts';

  Future<String> get fontsDir async {
    final dir = await getApplicationSupportDirectory();
    final fontsDir = Directory('${dir.path}/$_fontsDirName');
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }
    return fontsDir.path;
  }

  Future<void> initializeCustomFont() async {
    final fontFamily = AppSettingsService.instance.getCustomFontFamily();
    final filePath = AppSettingsService.instance.getCustomFontFilePath();
    if (fontFamily == null ||
        fontFamily.isEmpty ||
        filePath == null ||
        filePath.isEmpty) {
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final loader = FontLoader(fontFamily);
    final bytes = await file.readAsBytes();
    final future = Future<ByteData>.value(ByteData.view(bytes.buffer));
    loader.addFont(future);
    await loader.load();
  }

  Future<String?> installFontFile(String sourcePath, String fontFamily) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    final fontsPath = await fontsDir;
    final extension = sourcePath.split('.').last;
    final destPath = '$fontsPath/${fontFamily.hashCode}.$extension';
    await sourceFile.copy(destPath);

    final loader = FontLoader(fontFamily);
    final bytes = await File(destPath).readAsBytes();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await loader.load();

    return destPath;
  }

  Future<void> removeCustomFont() async {
    final filePath = AppSettingsService.instance.getCustomFontFilePath();
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await AppSettingsService.instance.saveCustomFontFilePath(null);
  }
}
