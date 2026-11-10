import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/services/update_service.dart';

void main() {
  group('UpdateService.normalizeVersion', () {
    test('去掉 v 前缀', () {
      expect(UpdateService.normalizeVersion('v1.7.1'), '1.7.1');
      expect(UpdateService.normalizeVersion('V1.7.1'), '1.7.1');
    });

    test('去掉构建元数据', () {
      expect(UpdateService.normalizeVersion('1.7.1+70'), '1.7.1');
    });

    test('去除首尾空白', () {
      expect(UpdateService.normalizeVersion('  v1.7.1  '), '1.7.1');
    });
  });

  group('UpdateService.compareVersions', () {
    test('相同版本返回 0', () {
      expect(UpdateService.compareVersions('1.7.1', '1.7.1'), 0);
      expect(UpdateService.compareVersions('v1.7.1', '1.7.1'), 0);
    });

    test('补丁版本更新', () {
      expect(UpdateService.compareVersions('1.7.2', '1.7.1'), greaterThan(0));
      expect(UpdateService.compareVersions('1.7.1', '1.7.2'), lessThan(0));
    });

    test('次版本与主版本更新', () {
      expect(UpdateService.compareVersions('1.8.0', '1.7.9'), greaterThan(0));
      expect(UpdateService.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('段数不同时缺失段按 0 处理', () {
      expect(UpdateService.compareVersions('1.7', '1.7.0'), 0);
      expect(UpdateService.compareVersions('1.7.1', '1.7'), greaterThan(0));
    });

    test('预发布版本小于正式版本', () {
      expect(
        UpdateService.compareVersions('1.7.2-beta.1', '1.7.2'),
        lessThan(0),
      );
      expect(
        UpdateService.compareVersions('1.7.2', '1.7.2-beta.1'),
        greaterThan(0),
      );
    });
  });
}
