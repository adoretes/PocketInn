import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'errors.dart';

/// 统一处理 [AppException]，弹出 [ScaffoldMessenger] SnackBar。
///
/// 调用方需在拥有 [BuildContext]（且已挂载）的层级使用，例如：
///
/// ```dart
/// try {
///   await someServiceCall();
/// } on AppException catch (error) {
///   handleAppException(context, error);
/// }
/// ```
void handleAppException(BuildContext context, AppException error) {
  if (!context.mounted) {
    debugPrint('handleAppException: context unmounted, drop: $error');
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    debugPrint('handleAppException: no messenger, drop: $error');
    return;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(error.message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}

/// 将任意 [Object]（异常或错误）转换为面向用户的 [AppException]。
///
/// 已是 [AppException] 的原样返回；常见的网络/超时/格式异常映射为对应子类，
/// 其余未知异常归一化为 [AppException] 基类。
AppException toAppException(
  Object error, {
  String? fallbackMessage,
  int? statusCode,
  String? endpoint,
}) {
  if (error is AppException) {
    return error;
  }
  if (error is TimeoutException) {
    return TimeoutAppException(
      fallbackMessage ?? '请求超时，请稍后重试',
      originalError: error,
    );
  }
  if (error is HttpException) {
    return ApiException(
      error.message,
      statusCode: statusCode,
      endpoint: endpoint,
      originalError: error,
    );
  }
  if (error is FormatException) {
    return ParseException(
      error.message.isEmpty ? (fallbackMessage ?? '数据解析失败') : error.message,
      originalError: error,
    );
  }
  if (error is HandshakeException) {
    return TlsHandshakeException(
      fallbackMessage ?? 'TLS 握手失败，请检查 HTTPS 证书或代理设置',
      originalError: error,
    );
  }
  if (error is SocketException) {
    return NetworkException(
      fallbackMessage ?? '网络异常: ${error.message}',
      originalError: error,
    );
  }
  return UnknownException(
    fallbackMessage ?? error.toString(),
    originalError: error,
  );
}

/// 注册全局错误捕获：[FlutterError.onError] 与 [PlatformDispatcher.onError]。
///
/// 在 `main()` 入口早期调用，将未捕获的 Flutter 框架错误与 Dart 隔离区
/// 异步错误统一通过 [debugPrint] 输出。未来可替换为正式 logger。
void registerGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError.onError: ${details.exceptionAsString()}');
    details.toString().split('\n').forEach(debugPrint);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('PlatformDispatcher.onError: $error\n$stack');
    return true;
  };
}

/// 构建友好的错误页 Widget，用于 [ErrorWidget.builder]。
///
/// 仅在 debug 模式下保留原始错误堆栈，release 模式只显示通用提示。
Widget buildAppErrorWidget(FlutterErrorDetails details) {
  final message = kDebugMode ? details.exceptionAsString() : '应用发生未知错误，请重启后再试';
  return Material(
    color: const Color(0xFF1A1A1A),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}
