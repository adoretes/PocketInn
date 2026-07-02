/// 应用统一异常层级。
///
/// 所有业务层抛出的异常应继承自 [AppException]，调用方可以按需捕获具体子类
/// 或统一交给 [handleAppException] 处理。原本由 `dart:io`、`dart:convert`
/// 等抛出的原生异常（如 [HttpException]、[FormatException]）保留不动，
/// 仅在边界处转换为对应子类。
sealed class AppException implements Exception {
  const AppException(this.message, {this.errorCode, this.originalError});

  /// 面向用户的错误描述。
  final String message;

  /// 可选的错误码，用于标识具体业务错误。
  final String? errorCode;

  /// 原始异常对象，便于日志记录与调试。
  final Object? originalError;

  @override
  String toString() {
    final code = errorCode;
    if (code == null) {
      return message;
    }
    return '$message (code: $code)';
  }
}

/// API 调用相关的异常。
class ApiException extends AppException {
  const ApiException(
    super.message, {
    this.statusCode,
    this.endpoint,
    super.errorCode,
    super.originalError,
  });

  /// HTTP 状态码（如 401、404、500 等），未知时为 null。
  final int? statusCode;

  /// 出错的 API 端点 URL。
  final String? endpoint;
}

/// 网络层异常（DNS 解析失败、连接被拒等）。
class NetworkException extends AppException {
  const NetworkException(super.message, {super.errorCode, super.originalError});
}

/// 请求超时异常。
class TimeoutAppException extends AppException {
  const TimeoutAppException(
    super.message, {
    super.errorCode,
    super.originalError,
  });
}

/// TLS 握手失败异常。
class TlsHandshakeException extends AppException {
  const TlsHandshakeException(
    super.message, {
    super.errorCode,
    super.originalError,
  });
}

/// JSON/响应体解析失败异常。
class ParseException extends AppException {
  const ParseException(super.message, {super.errorCode, super.originalError});
}

/// 本地存储相关异常。
class StorageException extends AppException {
  const StorageException(super.message, {super.errorCode, super.originalError});
}

/// 用户主动取消导致的异常（如终止流式请求）。
class CancelledException extends AppException {
  const CancelledException(
    super.message, {
    super.errorCode,
    super.originalError,
  });
}

/// 未知异常兜底类。
///
/// 用于 [toAppException] 无法识别的异常，避免直接实例化抽象基类。
class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.errorCode,
    super.originalError,
  });
}

/// 表达成功或失败结果的密封类。
///
/// 仅在需要区分成功/失败且不抛异常的场景使用（如 UI 层调用）。
sealed class Result<T> {
  const Result();

  /// 是否成功。
  bool get isSuccess => this is Success<T>;

  /// 是否失败。
  bool get isFailure => this is Failure<T>;

  /// 成功时的值，调用前应先检查 [isSuccess]。
  T get value {
    final self = this;
    if (self is Success<T>) {
      return self.value;
    }
    throw StateError('Result is not a Success: $this');
  }

  /// 失败时的异常，调用前应先检查 [isFailure]。
  AppException get error {
    final self = this;
    if (self is Failure<T>) {
      return self.error;
    }
    throw StateError('Result is not a Failure: $this');
  }

  /// 成功时的值，失败时返回 null。
  T? get valueOrNull {
    final self = this;
    return self is Success<T> ? self.value : null;
  }

  /// 成功时执行 [onSuccess]，失败时执行 [onFailure]。
  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>(:final error) => onFailure(error),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);

  @override
  final T value;

  @override
  String toString() => 'Success($value)';
}

class Failure<T> extends Result<T> {
  const Failure(this.error);

  @override
  final AppException error;

  @override
  String toString() => 'Failure($error)';
}
