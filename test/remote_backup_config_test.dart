import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/remote_backup_config.dart';
import 'package:pocket_inn/services/remote_backup_service.dart';

void main() {
  group('远端备份配置', () {
    test('普通配置序列化不包含敏感凭据', () {
      const settings = RemoteBackupSettings(
        webdav: WebDavBackupConfig(
          url: 'https://dav.example.com/files/user',
          remotePath: 'PocketInn',
          username: 'alice',
          password: 'password',
        ),
        s3: S3BackupConfig(
          endpoint: 'https://s3.example.com',
          region: 'us-east-1',
          bucket: 'backups',
          remotePath: 'PocketInn',
          accessKey: 'access',
          secretKey: 'secret',
          usePathStyle: true,
        ),
        selectedType: RemoteBackupType.s3,
        isExpanded: true,
      );

      final json = settings.toJson().toString();

      expect(json, contains('https://dav.example.com/files/user'));
      expect(json, contains('https://s3.example.com'));
      expect(json, isNot(contains('alice')));
      expect(json, isNot(contains('password')));
      expect(json, isNot(contains('secret')));
      expect(json, contains('selectedType: s3'));
      expect(json, contains('isExpanded: true'));
    });

    test('从 JSON 恢复连接参数并使用默认值', () {
      final settings = RemoteBackupSettings.fromJson({
        'webdav': {'url': 'https://dav.example.com', 'remotePath': 'backups'},
        's3': {'bucket': 'bucket', 'usePathStyle': true},
        'selectedType': 's3',
        'isExpanded': true,
      });

      expect(settings.webdav.url, 'https://dav.example.com');
      expect(settings.webdav.remotePath, 'backups');
      expect(settings.s3.bucket, 'bucket');
      expect(settings.s3.region, 'us-east-1');
      expect(settings.s3.usePathStyle, isTrue);
      expect(settings.selectedType, RemoteBackupType.s3);
      expect(settings.isExpanded, isTrue);
    });

    test('旧版仅配置 S3 时自动选中 S3', () {
      final settings = RemoteBackupSettings.fromJson({
        's3': {'bucket': 'bucket'},
      });

      expect(settings.selectedType, RemoteBackupType.s3);
    });

    test('已保存的类型优先于配置推断', () {
      final settings = RemoteBackupSettings.fromJson({
        'webdav': {'url': 'https://dav.example.com'},
        's3': {'bucket': 'bucket'},
        'selectedType': 's3',
      });

      expect(settings.selectedType, RemoteBackupType.s3);
    });
  });

  test('S3 SigV4 授权头包含稳定的凭据范围和签名字段', () {
    final config = const S3BackupConfig(
      endpoint: 'https://examplebucket.s3.amazonaws.com',
      region: 'us-east-1',
      bucket: 'examplebucket',
      accessKey: 'AKIAIOSFODNN7EXAMPLE',
      secretKey: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
    );
    final authorization = RemoteBackupService.instance
        .buildS3AuthorizationForTesting(
          config: config,
          method: 'GET',
          uri: Uri.parse('https://examplebucket.s3.amazonaws.com/test.txt'),
          timestamp: DateTime.utc(2013, 5, 24),
        );

    expect(
      authorization,
      startsWith(
        'AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/'
        '20130524/us-east-1/s3/aws4_request',
      ),
    );
    expect(
      authorization,
      contains('SignedHeaders=host;x-amz-content-sha256;x-amz-date'),
    );
    expect(authorization, matches(RegExp(r'Signature=[0-9a-f]{64}$')));
  });

  test('S3 canonical URI 严格编码 SigV4 保留字符', () {
    final canonicalUri = RemoteBackupService.instance.canonicalUriForTesting(
      Uri.parse("https://s3.example.com/backup/O'Reilly!()*/中文"),
    );

    expect(canonicalUri, '/backup/O%27Reilly%21%28%29%2A/%E4%B8%AD%E6%96%87');
  });

  test('HTTPS 含点 Bucket 自动使用 path-style 地址', () {
    final uri = RemoteBackupService.instance.s3ObjectUriForTesting(
      const S3BackupConfig(
        endpoint: 'https://s3.us-east-1.amazonaws.com',
        region: 'us-east-1',
        bucket: 'my.backups',
        remotePath: 'PocketInn',
        accessKey: 'access',
        secretKey: 'secret',
      ),
      'pocketinn-latest.zip',
    );

    expect(uri.host, 's3.us-east-1.amazonaws.com');
    expect(uri.path, '/my.backups/PocketInn/pocketinn-latest.zip');
  });

  test('WebDAV 下载会等待响应体读取完成后再关闭连接', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final responseBytes = List<int>.generate(1024, (index) => index % 251);
    final requestHandled = Completer<void>();
    final subscription = server.listen((request) async {
      request.response.headers.contentLength = responseBytes.length;
      request.response.add(responseBytes.sublist(0, 128));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      request.response.add(responseBytes.sublist(128));
      await request.response.close();
      if (!requestHandled.isCompleted) {
        requestHandled.complete();
      }
    });

    try {
      final bytes = await RemoteBackupService.instance.downloadWebDav(
        WebDavBackupConfig(
          url: 'http://${InternetAddress.loopbackIPv4.address}:${server.port}',
          remotePath: 'PocketInn',
        ),
        'pocketinn-latest.zip',
      );

      await requestHandled.future;
      expect(bytes, orderedEquals(responseBytes));
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  });

  test('WebDAV 下载到临时文件时保留完整响应体', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final responseBytes = List<int>.generate(4096, (index) => index % 251);
    final subscription = server.listen((request) async {
      request.response.headers.contentLength = responseBytes.length;
      request.response.add(responseBytes);
      await request.response.close();
    });

    File? file;
    try {
      file = await RemoteBackupService.instance.downloadWebDavToFile(
        WebDavBackupConfig(
          url: 'http://${InternetAddress.loopbackIPv4.address}:${server.port}',
          remotePath: 'PocketInn',
        ),
        'pocketinn-latest.zip',
      );

      expect(await file.readAsBytes(), orderedEquals(responseBytes));
    } finally {
      if (file != null && await file.exists()) {
        await file.delete();
      }
      await subscription.cancel();
      await server.close(force: true);
    }
  });

  test('WebDAV 仅在配置的基路径下创建远端目录', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final subscription = server.listen((request) async {
      requests.add('${request.method} ${request.uri.path}');
      if (request.method == 'PROPFIND') {
        request.response.statusCode = HttpStatus.notFound;
      } else if (request.method == 'MKCOL') {
        request.response.statusCode = HttpStatus.created;
      } else if (request.method == 'PUT') {
        request.response.statusCode = HttpStatus.created;
      }
      await request.response.close();
    });

    try {
      await RemoteBackupService.instance.uploadWebDav(
        WebDavBackupConfig(
          url:
              'http://${InternetAddress.loopbackIPv4.address}:${server.port}/remote.php/dav/files/user',
          remotePath: 'PocketInn/nested',
        ),
        Uint8List.fromList([1, 2, 3]),
        'pocketinn-latest.zip',
      );

      expect(
        requests,
        orderedEquals([
          'PROPFIND /remote.php/dav/files/user/PocketInn/nested',
          'PROPFIND /remote.php/dav/files/user/PocketInn',
          'MKCOL /remote.php/dav/files/user/PocketInn',
          'PROPFIND /remote.php/dav/files/user/PocketInn/nested',
          'MKCOL /remote.php/dav/files/user/PocketInn/nested',
          'PUT /remote.php/dav/files/user/PocketInn/nested/pocketinn-latest.zip',
        ]),
      );
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  });

  test('远程下载会拒绝超过上限的响应', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) async {
      request.response.headers.contentLength = 2;
      request.response.add([1, 2]);
      await request.response.close();
    });

    try {
      RemoteBackupService.maximumDownloadSizeForTesting = 1;
      await expectLater(
        RemoteBackupService.instance.downloadWebDav(
          WebDavBackupConfig(
            url:
                'http://${InternetAddress.loopbackIPv4.address}:${server.port}',
            remotePath: 'PocketInn',
          ),
          'pocketinn-latest.zip',
        ),
        throwsA(
          isA<RemoteBackupException>().having(
            (error) => error.message,
            'message',
            contains('过大'),
          ),
        ),
      );
    } finally {
      RemoteBackupService.maximumDownloadSizeForTesting = null;
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}
