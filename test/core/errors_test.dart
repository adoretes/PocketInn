import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/core/errors.dart';
import 'package:pocket_inn/core/error_handler.dart';

void main() {
  group('AppException 层级', () {
    test('AppException 子类正确保留 message 与原始错误', () {
      final original = StateError('boom');
      final exception = StorageException('保存失败', originalError: original);

      expect(exception.message, '保存失败');
      expect(exception.originalError, same(original));
      expect(exception.toString(), '保存失败');
    });

    test('AppException 带错误码时 toString 包含 code', () {
      const exception = ApiException(
        '鉴权失败',
        statusCode: 401,
        errorCode: 'AUTH_FAILED',
      );

      expect(exception.statusCode, 401);
      expect(exception.toString(), '鉴权失败 (code: AUTH_FAILED)');
    });

    test('CancelledException 与 TimeoutAppException 互不干扰', () {
      const cancelled = CancelledException('用户取消');
      const timeout = TimeoutAppException('请求超时');

      expect(cancelled, isA<AppException>());
      expect(timeout, isA<AppException>());
      expect(cancelled.message, '用户取消');
      expect(timeout.message, '请求超时');
    });
  });

  group('Result<T>', () {
    test('Success 携带值并判定为成功', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.value, 42);
      expect(result.valueOrNull, 42);
    });

    test('Failure 携带异常并判定为失败', () {
      final failure = Failure<int>(const StorageException('失败'));

      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.error, isA<StorageException>());
      expect(failure.valueOrNull, isNull);
    });

    test('value 在 Failure 上抛 StateError', () {
      const failure = Failure<int>(StorageException('失败'));

      expect(() => failure.value, throwsStateError);
    });

    test('error 在 Success 上抛 StateError', () {
      const success = Success<int>(42);

      expect(() => success.error, throwsStateError);
    });

    test('when 按分支返回不同结果', () {
      const success = Success<int>(10);
      const failure = Failure<int>(StorageException('失败'));

      expect(
        success.when(
          onSuccess: (v) => 'ok $v',
          onFailure: (e) => 'err ${e.message}',
        ),
        'ok 10',
      );
      expect(
        failure.when(
          onSuccess: (v) => 'ok $v',
          onFailure: (e) => 'err ${e.message}',
        ),
        'err 失败',
      );
    });
  });

  group('toAppException', () {
    test('已是 AppException 时原样返回', () {
      const original = StorageException('保存失败');
      final result = toAppException(original);

      expect(result, same(original));
    });

    test('TimeoutException 映射为 TimeoutAppException', () {
      final exception = toAppException(
        TimeoutException('请求超时', const Duration(seconds: 5)),
      );

      expect(exception, isA<TimeoutAppException>());
      expect(exception.message, '请求超时，请稍后重试');
    });

    test('HttpException 映射为 ApiException', () {
      final exception = toAppException(
        const HttpException('HTTP 500'),
        statusCode: 500,
        endpoint: 'https://example.com',
      );

      expect(exception, isA<ApiException>());
      final apiException = exception as ApiException;
      expect(apiException.statusCode, 500);
      expect(apiException.endpoint, 'https://example.com');
    });

    test('FormatException 映射为 ParseException', () {
      final exception = toAppException(const FormatException('bad json'));

      expect(exception, isA<ParseException>());
      expect(exception.message, 'bad json');
    });

    test('SocketException 映射为 NetworkException', () {
      final exception = toAppException(
        const SocketException('连接被拒'),
        fallbackMessage: '网络异常，请检查连接',
      );

      expect(exception, isA<NetworkException>());
      expect(exception.message, '网络异常，请检查连接');
    });

    test('未知异常归一化为 AppException', () {
      final exception = toAppException(
        StateError('unknown'),
        fallbackMessage: '发生未知错误',
      );

      expect(exception, isA<AppException>());
      expect(exception.message, '发生未知错误');
    });
  });
}
