import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/remote_backup_config.dart';
import 'package:pocket_inn/services/remote_backup_service.dart';

void main() {
  group('远程备份上传', () {
    tearDown(() {
      RemoteBackupService.requestTimeoutForTesting = null;
    });

    test('慢速服务器下进度随实际发送推进而非瞬间完成', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var serverReceived = 0;
      server.listen((request) {
        if (request.method == 'PROPFIND') {
          request.response
            ..statusCode = HttpStatus.multiStatus
            ..close();
          return;
        }
        if (request.method != 'PUT') {
          request.response
            ..statusCode = HttpStatus.methodNotAllowed
            ..close();
          return;
        }
        // 模拟慢速网络：每读完一个块就暂停 100ms，
        // 客户端写满发送窗口后必须等服务器读取，进度应跟随该节奏推进。
        Future<void>(() async {
          try {
            await for (final chunk in request) {
              serverReceived += chunk.length;
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
            request.response.statusCode = HttpStatus.ok;
            await request.response.close();
          } catch (_) {
            // 客户端提前断开时忽略。
          }
        });
      });

      final payload = Uint8List(2 * 1024 * 1024);
      final progressValues = <int>[];
      final progressTimes = <DateTime>[];
      await RemoteBackupService.instance.uploadWebDav(
        WebDavBackupConfig(
          url: 'http://127.0.0.1:${server.port}',
          remotePath: 'root',
        ),
        payload,
        'test.zip',
        onProgress: (sent, total) {
          progressValues.add(sent);
          progressTimes.add(DateTime.now());
        },
      ).timeout(const Duration(seconds: 15));

      expect(serverReceived, payload.length);
      expect(progressValues, isNotEmpty);
      expect(progressValues.last, payload.length);
      expect(
        progressValues,
        orderedEquals([...progressValues]..sort()),
        reason: '进度值应单调递增',
      );
      final spread = progressTimes.last.difference(progressTimes.first);
      expect(
        spread,
        greaterThanOrEqualTo(const Duration(milliseconds: 800)),
        reason: '进度应随服务器读取节奏推进（间隔仅 ${spread.inMilliseconds}ms）',
      );
    });

    test('发送停滞超过超时时间才报错，而非限制上传总时长', () async {
      RemoteBackupService.requestTimeoutForTesting =
          const Duration(milliseconds: 700);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        if (request.method == 'PROPFIND') {
          request.response
            ..statusCode = HttpStatus.multiStatus
            ..close();
          return;
        }
        // PUT：既不读取请求体也不响应，使客户端发送停滞。
      });

      final payload = Uint8List(16 * 1024 * 1024);
      await expectLater(
        RemoteBackupService.instance.uploadWebDav(
          WebDavBackupConfig(
            url: 'http://127.0.0.1:${server.port}',
            remotePath: 'root',
          ),
          payload,
          'test.zip',
          onProgress: (sent, total) {},
        ).timeout(const Duration(seconds: 10)),
        throwsA(
          isA<RemoteBackupException>().having(
            (error) => error.message,
            'message',
            contains('超时'),
          ),
        ),
      );
    });

    test('S3 上传走同一流式写入路径且可成功', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var serverReceived = 0;
      var contentType = '';
      server.listen((request) {
        if (request.method != 'PUT') {
          request.response
            ..statusCode = HttpStatus.methodNotAllowed
            ..close();
          return;
        }
        Future<void>(() async {
          try {
            await for (final chunk in request) {
              serverReceived += chunk.length;
            }
            contentType = request.headers.contentType?.mimeType ?? '';
            request.response.statusCode = HttpStatus.ok;
            await request.response.close();
          } catch (_) {
            // 客户端提前断开时忽略。
          }
        });
      });

      final payload = Uint8List(512 * 1024);
      final progressValues = <int>[];
      await RemoteBackupService.instance.uploadS3(
        S3BackupConfig(
          endpoint: 'http://127.0.0.1:${server.port}',
          region: 'us-east-1',
          bucket: 'backups',
          accessKey: 'access',
          secretKey: 'secret',
          usePathStyle: true,
        ),
        payload,
        'pocketinn-latest.zip',
        onProgress: (sent, total) => progressValues.add(sent),
      ).timeout(const Duration(seconds: 15));

      expect(serverReceived, payload.length);
      expect(contentType, 'application/zip');
      expect(progressValues.last, payload.length);
    });
  });
}
