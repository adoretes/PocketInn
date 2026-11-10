import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/errors.dart';

/// 一次「检查更新」的结果。
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    this.releaseName,
    this.releaseNotes,
    this.releaseUrl,
    this.publishedAt,
  });

  /// 当前应用版本（不含构建号）。
  final String currentVersion;

  /// 远程最新版本（已去掉 `v` 前缀与构建元数据）。
  final String latestVersion;

  /// 是否存在比当前更新的版本。
  final bool hasUpdate;

  /// Release 名称，例如 `PocketInn 1.7.2 (abc1234)`。
  final String? releaseName;

  /// Release 说明（Markdown 原文）。
  final String? releaseNotes;

  /// Release 页面地址，用于跳转下载。
  final String? releaseUrl;

  /// Release 发布时间。
  final DateTime? publishedAt;
}

/// 更新检查服务：查询 GitHub Releases 的最新版本并与当前版本比较。
///
/// 应用目前通过 GitHub Releases 分发，因此以 `releases/latest` 作为
/// 版本信息来源。仅做「手动检查」，不涉及自动下载或静默更新。
class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  static const String _owner = 'adoretes';
  static const String _repo = 'PocketInn';

  static const Duration _requestTimeout = Duration(seconds: 15);

  Uri get latestReleaseUri =>
      Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');

  /// 查询最新 Release 并与 [currentVersion] 比较。
  ///
  /// 网络或解析失败时抛出 [UpdateCheckException]。
  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
  }) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client
          .getUrl(latestReleaseUri)
          .timeout(_requestTimeout);
      // GitHub API 要求携带 User-Agent，并建议声明 API 版本。
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'PocketInn');
      request.headers.set('X-GitHub-Api-Version', '2022-11-28');

      final response = await request.close().timeout(_requestTimeout);
      final rawBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);

      if (response.statusCode != HttpStatus.ok) {
        if (response.statusCode == HttpStatus.notFound) {
          throw const UpdateCheckException('暂无已发布的版本信息');
        }
        throw UpdateCheckException(
          '检查更新失败（HTTP ${response.statusCode}）',
          errorCode: 'http_${response.statusCode}',
        );
      }

      final decoded = jsonDecode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        throw const UpdateCheckException('更新信息格式异常');
      }

      final rawTag = (decoded['tag_name'] as String?)?.trim() ?? '';
      final latestVersion = normalizeVersion(rawTag);
      if (latestVersion.isEmpty) {
        throw const UpdateCheckException('未能从发布信息中读取版本号');
      }

      final current = normalizeVersion(currentVersion);
      final releaseUrl = (decoded['html_url'] as String?)?.trim();
      final publishedRaw = (decoded['published_at'] as String?)?.trim();

      return UpdateCheckResult(
        currentVersion: current,
        latestVersion: latestVersion,
        hasUpdate: compareVersions(latestVersion, current) > 0,
        releaseName: (decoded['name'] as String?)?.trim(),
        releaseNotes: (decoded['body'] as String?)?.trim(),
        releaseUrl: (releaseUrl != null && releaseUrl.isNotEmpty)
            ? releaseUrl
            : null,
        publishedAt: (publishedRaw != null && publishedRaw.isNotEmpty)
            ? DateTime.tryParse(publishedRaw)
            : null,
      );
    } on UpdateCheckException {
      rethrow;
    } on TimeoutException catch (error) {
      throw UpdateCheckException('检查更新超时，请检查网络后重试', originalError: error);
    } on SocketException catch (error) {
      throw UpdateCheckException(
        '网络连接失败：${error.message}',
        originalError: error,
      );
    } on HandshakeException catch (error) {
      throw UpdateCheckException(
        'TLS 握手失败，请检查 HTTPS 证书或代理设置',
        originalError: error,
      );
    } on FormatException catch (error) {
      throw UpdateCheckException('更新信息解析失败', originalError: error);
    } on HttpException catch (error) {
      throw UpdateCheckException(
        '检查更新失败：${error.message}',
        originalError: error,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// 去掉版本号前缀 `v` 与构建元数据（`+` 之后的部分），返回纯版本号。
  static String normalizeVersion(String raw) {
    var value = raw.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    final plusIndex = value.indexOf('+');
    if (plusIndex >= 0) {
      value = value.substring(0, plusIndex);
    }
    return value.trim();
  }

  /// 比较两个语义化版本号，返回负数 / 0 / 正数表示 [a] 小于 / 等于 / 大于 [b]。
  ///
  /// 逐段比较数字部分；数字相同的情况下，带预发布标识（`-` 之后）的版本
  /// 视为小于正式版本。
  static int compareVersions(String a, String b) {
    final parsedA = _parseVersion(a);
    final parsedB = _parseVersion(b);

    final length = parsedA.numbers.length > parsedB.numbers.length
        ? parsedA.numbers.length
        : parsedB.numbers.length;

    for (var i = 0; i < length; i++) {
      final left = i < parsedA.numbers.length ? parsedA.numbers[i] : 0;
      final right = i < parsedB.numbers.length ? parsedB.numbers[i] : 0;
      if (left != right) {
        return left < right ? -1 : 1;
      }
    }

    final preA = parsedA.preRelease;
    final preB = parsedB.preRelease;
    if (preA == null && preB == null) {
      return 0;
    }
    // 正式版本大于同号的预发布版本。
    if (preA == null) {
      return 1;
    }
    if (preB == null) {
      return -1;
    }
    return preA.compareTo(preB);
  }

  static _ParsedVersion _parseVersion(String raw) {
    var value = normalizeVersion(raw);

    String? preRelease;
    final dashIndex = value.indexOf('-');
    if (dashIndex >= 0) {
      preRelease = value.substring(dashIndex + 1).trim();
      value = value.substring(0, dashIndex);
    }

    final numbers = <int>[];
    for (final part in value.split('.')) {
      final digits = part.replaceAll(RegExp(r'[^0-9]'), '');
      numbers.add(digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0));
    }

    return _ParsedVersion(numbers, preRelease);
  }
}

class _ParsedVersion {
  const _ParsedVersion(this.numbers, this.preRelease);

  final List<int> numbers;
  final String? preRelease;
}
