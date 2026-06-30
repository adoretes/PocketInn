import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static final Uri _githubUri = Uri.parse(
    'https://github.com/adoretes/PocketInn',
  );

  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用信息卡片
          _AppInfoCard(colorScheme: colorScheme),
          const SizedBox(height: 16),

          // 版本信息
          _SectionCard(
            title: '版本信息',
            subtitle: '当前应用版本详情',
            child: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                final packageInfo = snapshot.data;

                return Column(
                  children: [
                    _InfoRow(
                      label: '版本号',
                      value: packageInfo?.version ?? '读取中...',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: '构建号',
                      value: packageInfo?.buildNumber ?? '读取中...',
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 更新日志
          _SectionCard(
            title: '更新日志',
            subtitle: '最近更新内容',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UpdateLogItem(
                  version: 'v1.1.5',
                  date: '2026-06-30',
                  changes: [
                    '优化记忆系统',
                  ],
                ),
                _UpdateLogItem(
                  version: 'v1.1.4',
                  date: '2026-06-17',
                  changes: [
                    '添加在新建对话和删除角色时与世界书的联动',
                    '增强主题设置，支持深色模式下的文本颜色配置',
                    '锁定默认预设，防止误修改',
                    '重构新建预设方法',
                    '优化记忆树在深色模式下的显示效果',
                    '优化整体显示效果',
                  ],
                ),
                const SizedBox(height: 12),
                _UpdateLogItem(
                  version: 'v1.1.3',
                  date: '2026-06-14',
                  changes: [
                    '实现旧版数据迁移功能',
                    '规范化数据存储路径，使用应用支持目录替代文档目录',
                    '将角色卡持久化的图片路径改为相对路径',
                    '把自定义字体加入到备份中',
                  ],
                ),
                const SizedBox(height: 12),
                _UpdateLogItem(
                  version: 'v1.1.2',
                  date: '2026-06-13',
                  changes: [
                    '移除独立记忆节点，优化记忆展示方式',
                  ],
                ),
                _UpdateLogItem(
                  version: 'v1.1.1',
                  date: '2026-06-13',
                  changes: [
                    '添加配套工具页面，整合 Prompt 版本管理和角色卡生成器',
                    '重构记忆管理功能，替换为可视化消息树',
                    '优化消息树页面标签栏样式',
                    '添加自定义注入提示词功能',
                    '修复新生成消息无法弹出操作的问题',
                  ],
                ),
                const SizedBox(height: 12),
                _UpdateLogItem(
                  version: 'v1.1.0',
                  date: '2026-06-10',
                  changes: [
                    '增加长期记忆功能',
                    '拆分聊天页面，提取独立组件',
                    '移除废弃页面',
                    '移动聊天页长期记忆入口',
                    '统一各服务的数据存储路径',
                    '调整 UI 布局',
                    '更新项目文档',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 开源许可
          _SectionCard(
            title: '开源许可',
            subtitle: '第三方开源库',
            child: Column(
              children: [
                _LicenseItem(
                  name: 'Flutter',
                  license: 'BSD-3-Clause',
                  onTap: () =>
                      _showLicenseDialog(context, 'Flutter', flutterLicense),
                ),
                const SizedBox(height: 8),
                _LicenseItem(
                  name: 'Dart',
                  license: 'BSD-3-Clause',
                  onTap: () => _showLicenseDialog(context, 'Dart', dartLicense),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 联系方式
          _SectionCard(
            title: '联系方式',
            subtitle: '反馈与支持',
            child: Column(
              children: [
                _ContactItem(
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  value: _githubUri.toString(),
                  onTap: _openGitHub,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 版权信息
          Center(
            child: Text(
              '© 2026 PocketInn Team. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLicenseDialog(BuildContext context, String name, String license) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name 许可证'),
        content: SingleChildScrollView(
          child: Text(
            license,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGitHub() async {
    var launched = false;

    try {
      launched = await launchUrl(
        _githubUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开 GitHub 链接')));
    }
  }
}

class _AppInfoCard extends StatelessWidget {
  static const _appIconAsset = 'assets/PInn.png';

  const _AppInfoCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 应用图标
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  _appIconAsset,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 应用名称
            const Text(
              'PocketInn',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'PocketInn 是一款基于 Flutter 开发的类SillyTavern AI 聊天应用，支持多种 AI 模型接口配置，提供角色扮演、世界书、预设等核心功能，让您与 AI 角色进行沉浸式对话体验。',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _UpdateLogItem extends StatelessWidget {
  const _UpdateLogItem({
    required this.version,
    required this.date,
    required this.changes,
  });

  final String version;
  final String date;
  final List<String> changes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                version,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...changes.map(
          (change) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    change,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LicenseItem extends StatelessWidget {
  const _LicenseItem({
    required this.name,
    required this.license,
    required this.onTap,
  });

  final String name;
  final String license;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 14)),
            Row(
              children: [
                Text(
                  license,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLink = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLink ? colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isLink) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const String flutterLicense = '''
Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials provided
with the distribution.
   * Neither the name of Google Inc. nor the names of its
contributors may be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';

const String dartLicense = '''
Copyright 2012, the Dart project authors. All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials provided
with the distribution.
   * Neither the name of Google Inc. nor the names of its
contributors may be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';
