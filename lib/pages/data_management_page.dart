import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/remote_backup_config.dart';
import '../services/app_backup_service.dart';
import '../services/app_data_service.dart';
import '../services/remote_backup_service.dart';
import '../services/remote_backup_settings_service.dart';

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String _restoreStepText(RestoreStep step) {
  return switch (step) {
    RestoreStep.validating => '正在校验备份文件…',
    RestoreStep.cleaning => '正在清空当前数据…',
    RestoreStep.writingFiles => '正在恢复文件…',
    RestoreStep.migrating => '正在迁移数据…',
    RestoreStep.reloading => '正在重载应用…',
  };
}

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  bool _isExporting = false;
  bool _isRestoring = false;
  bool _isClearing = false;
  bool _isLoadingRemoteSettings = true;
  String? _remoteOperation;
  RemoteBackupType _remoteBackupType = RemoteBackupType.webdav;
  bool _isRemoteBackupExpanded = false;

  final _webDavUrlController = TextEditingController();
  final _webDavPathController = TextEditingController();
  final _webDavUsernameController = TextEditingController();
  final _webDavPasswordController = TextEditingController();
  final _s3EndpointController = TextEditingController();
  final _s3RegionController = TextEditingController();
  final _s3BucketController = TextEditingController();
  final _s3PathController = TextEditingController();
  final _s3AccessKeyController = TextEditingController();
  final _s3SecretKeyController = TextEditingController();
  bool _s3UsePathStyle = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRemoteSettings());
  }

  @override
  void dispose() {
    _webDavUrlController.dispose();
    _webDavPathController.dispose();
    _webDavUsernameController.dispose();
    _webDavPasswordController.dispose();
    _s3EndpointController.dispose();
    _s3RegionController.dispose();
    _s3BucketController.dispose();
    _s3PathController.dispose();
    _s3AccessKeyController.dispose();
    _s3SecretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: '备份与恢复',
            subtitle: '导出 ZIP 备份包，或从备份包整体恢复',
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.archive_outlined,
                  title: '备份数据',
                  subtitle: '导出角色、聊天、预设、配置和设置为 ZIP',
                  enabled: !_isAnyBusy,
                  trailing: _isExporting,
                  onTap: _handleExport,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.restore_page_outlined,
                  title: '恢复备份',
                  subtitle: '用 ZIP 备份包覆盖当前全部本地数据',
                  enabled: !_isAnyBusy,
                  trailing: _isRestoring,
                  onTap: _handleRestore,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.cloud_upload_outlined,
                  title: '上传远程备份',
                  subtitle: '生成 ZIP 后覆盖指定的远程备份文件',
                  enabled: !_isAnyBusy,
                  trailing:
                      _remoteOperation == '上传 WebDAV' ||
                      _remoteOperation == '上传 S3',
                  onTap: _handleUploadRemote,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.cloud_download_outlined,
                  title: '下载并恢复',
                  subtitle: '下载指定远程备份并覆盖当前全部本地数据',
                  enabled: !_isAnyBusy,
                  trailing:
                      _remoteOperation == '恢复 WebDAV' ||
                      _remoteOperation == '恢复 S3',
                  onTap: _handleDownloadRemote,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRemoteBackupSection(),
          const SizedBox(height: 16),
          _SectionCard(
            title: '危险操作',
            subtitle: '永久清除当前设备上的全部本地数据',
            child: _ActionTile(
              icon: Icons.delete_forever_rounded,
              title: '清除全部数据',
              subtitle: '删除聊天、角色、世界书、预设、配置和日志',
              enabled: !_isAnyBusy,
              trailing: _isClearing,
              destructive: true,
              onTap: _handleClear,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isBusy => _isExporting || _isRestoring || _isClearing;

  bool get _isRemoteBusy => _remoteOperation != null;

  bool get _isAnyBusy => _isBusy || _isRemoteBusy;

  Future<void> _loadRemoteSettings() async {
    try {
      final settings = await RemoteBackupSettingsService.instance.load();
      if (!mounted) {
        return;
      }
      _setControllers(settings);
      // 将旧版配置推断出的选择状态写回，后续不再依赖默认回退。
      await _saveRemoteSettings();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRemoteSettings = false;
        });
      }
    }
  }

  void _setControllers(RemoteBackupSettings settings) {
    final webdav = settings.webdav;
    _webDavUrlController.text = webdav.url;
    _webDavPathController.text = webdav.remotePath;
    _webDavUsernameController.text = webdav.username;
    _webDavPasswordController.text = webdav.password;

    final s3 = settings.s3;
    _s3EndpointController.text = s3.endpoint;
    _s3RegionController.text = s3.region;
    _s3BucketController.text = s3.bucket;
    _s3PathController.text = s3.remotePath;
    _s3AccessKeyController.text = s3.accessKey;
    _s3SecretKeyController.text = s3.secretKey;
    _s3UsePathStyle = s3.usePathStyle;
    _remoteBackupType = settings.selectedType;
    _isRemoteBackupExpanded = settings.isExpanded;
  }

  WebDavBackupConfig _webDavConfig() {
    return WebDavBackupConfig(
      url: _webDavUrlController.text.trim(),
      remotePath: _webDavPathController.text.trim(),
      username: _webDavUsernameController.text,
      password: _webDavPasswordController.text,
    );
  }

  S3BackupConfig _s3Config() {
    return S3BackupConfig(
      endpoint: _s3EndpointController.text.trim(),
      region: _s3RegionController.text.trim(),
      bucket: _s3BucketController.text.trim(),
      remotePath: _s3PathController.text.trim(),
      accessKey: _s3AccessKeyController.text,
      secretKey: _s3SecretKeyController.text,
      usePathStyle: _s3UsePathStyle,
    );
  }

  Future<void> _saveRemoteSettings() async {
    await RemoteBackupSettingsService.instance.save(
      RemoteBackupSettings(
        webdav: _webDavConfig(),
        s3: _s3Config(),
        selectedType: _remoteBackupType,
        isExpanded: _isRemoteBackupExpanded,
      ),
    );
  }

  Widget _buildRemoteBackupSection() {
    if (_isLoadingRemoteSettings) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return _RemoteBackupCard(
      title: '远程备份配置',
      subtitle: '${_remoteBackupType.label} · 仅手动 · 远程配置不跟随上传',
      type: _remoteBackupType,
      operation: _remoteOperation,
      enabled: !_isAnyBusy,
      expanded: _isRemoteBackupExpanded,
      onTypeChanged: (type) {
        setState(() {
          _remoteBackupType = type;
        });
        unawaited(_saveRemoteSettings());
      },
      onExpandedChanged: (expanded) {
        setState(() {
          _isRemoteBackupExpanded = expanded;
        });
        unawaited(_saveRemoteSettings());
      },
      onSave: _handleSaveRemoteSettings,
      onTest: _handleTestRemote,
      fields: _remoteBackupType == RemoteBackupType.webdav
          ? _buildWebDavFields()
          : _buildS3Fields(),
    );
  }

  List<Widget> _buildWebDavFields() {
    return [
      _RemoteTextField(
        controller: _webDavUrlController,
        label: 'WebDAV 地址',
        hint: 'https://dav.example.com/remote.php/dav/files/user',
        keyboardType: TextInputType.url,
      ),
      _RemoteTextField(
        controller: _webDavPathController,
        label: '远端目录',
        hint: 'PocketInn',
      ),
      _RemoteTextField(
        controller: _webDavUsernameController,
        label: '用户名',
        autofillHints: const [AutofillHints.username],
      ),
      _RemoteTextField(
        controller: _webDavPasswordController,
        label: '密码',
        obscureText: true,
        autofillHints: const [AutofillHints.password],
      ),
    ];
  }

  List<Widget> _buildS3Fields() {
    return [
      _RemoteTextField(
        controller: _s3EndpointController,
        label: 'Endpoint（可选）',
        hint: 'AWS 可留空，例如 https://s3.example.com',
        keyboardType: TextInputType.url,
      ),
      _RemoteTextField(
        controller: _s3RegionController,
        label: 'Region',
        hint: 'us-east-1',
      ),
      _RemoteTextField(controller: _s3BucketController, label: 'Bucket'),
      _RemoteTextField(
        controller: _s3PathController,
        label: '对象路径',
        hint: 'PocketInn',
      ),
      _RemoteTextField(controller: _s3AccessKeyController, label: 'Access Key'),
      _RemoteTextField(
        controller: _s3SecretKeyController,
        label: 'Secret Key',
        obscureText: true,
      ),
      StatefulBuilder(
        builder: (context, setFieldState) {
          return SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('使用 Path-style 地址'),
            subtitle: const Text('MinIO、部分自建 S3 服务通常需要开启'),
            value: _s3UsePathStyle,
            onChanged: !_isRemoteBusy
                ? (value) {
                    setFieldState(() {
                      _s3UsePathStyle = value;
                    });
                  }
                : null,
          );
        },
      ),
    ];
  }

  Future<void> _handleSaveRemoteSettings() async {
    await _runRemoteOperation('保存配置', () async {
      await _saveRemoteSettings();
    });
  }

  Future<void> _handleTestRemote() async {
    if (_remoteBackupType == RemoteBackupType.webdav) {
      await _handleTestWebDav();
    } else {
      await _handleTestS3();
    }
  }

  Future<void> _handleUploadRemote() async {
    if (_remoteBackupType == RemoteBackupType.webdav) {
      await _handleUploadWebDav();
    } else {
      await _handleUploadS3();
    }
  }

  Future<void> _handleDownloadRemote() async {
    if (_remoteBackupType == RemoteBackupType.webdav) {
      await _handleRestoreWebDav();
    } else {
      await _handleRestoreS3();
    }
  }

  Future<void> _handleTestWebDav() async {
    await _runRemoteOperation('测试 WebDAV', () async {
      await _saveRemoteSettings();
      await RemoteBackupService.instance.testWebDav(_webDavConfig());
    });
  }

  Future<void> _handleUploadWebDav() async {
    if (_isRemoteBusy) return;
    setState(() => _remoteOperation = '上传 WebDAV');
    try {
      await _saveRemoteSettings();
      if (!mounted) return;
      final result = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ProgressDialog(
          title: '上传到 WebDAV',
          task: (update) async {
            update(step: '正在打包数据…', progress: null);
            final bytes = await AppBackupService.instance.buildBackupArchiveBytes();
            update(step: '正在上传到服务器…', progress: 0.0);
            await RemoteBackupService.instance.uploadWebDav(
              _webDavConfig(),
              bytes,
              AppBackupService.remoteBackupFileName,
              onProgress: (sent, total) {
                update(
                  step: '正在上传到服务器…',
                  progress: total > 0 ? sent / total : null,
                  detail: '${_formatSize(sent)} / ${_formatSize(total)}',
                );
              },
            );
          },
        ),
      );
      if (!mounted) return;
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传 WebDAV 成功')),
        );
      } else if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传 WebDAV 失败：$result')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传 WebDAV 失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _remoteOperation = null);
      }
    }
  }

  Future<void> _handleRestoreWebDav() async {
    await _restoreRemote(
      'WebDAV',
      download: (onProgress) => RemoteBackupService.instance.downloadWebDavToFile(
        _webDavConfig(),
        AppBackupService.remoteBackupFileName,
        onProgress: onProgress,
      ),
    );
  }

  Future<void> _handleTestS3() async {
    await _runRemoteOperation('测试 S3', () async {
      await _saveRemoteSettings();
      await RemoteBackupService.instance.testS3(_s3Config());
    });
  }

  Future<void> _handleUploadS3() async {
    if (_isRemoteBusy) return;
    setState(() => _remoteOperation = '上传 S3');
    try {
      await _saveRemoteSettings();
      if (!mounted) return;
      final result = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ProgressDialog(
          title: '上传到 S3',
          task: (update) async {
            update(step: '正在打包数据…', progress: null);
            final bytes = await AppBackupService.instance.buildBackupArchiveBytes();
            update(step: '正在上传到服务器…', progress: 0.0);
            await RemoteBackupService.instance.uploadS3(
              _s3Config(),
              bytes,
              AppBackupService.remoteBackupFileName,
              onProgress: (sent, total) {
                update(
                  step: '正在上传到服务器…',
                  progress: total > 0 ? sent / total : null,
                  detail: '${_formatSize(sent)} / ${_formatSize(total)}',
                );
              },
            );
          },
        ),
      );
      if (!mounted) return;
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传 S3 成功')),
        );
      } else if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传 S3 失败：$result')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传 S3 失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _remoteOperation = null);
      }
    }
  }

  Future<void> _handleRestoreS3() async {
    await _restoreRemote(
      'S3',
      download: (onProgress) => RemoteBackupService.instance.downloadS3ToFile(
        _s3Config(),
        AppBackupService.remoteBackupFileName,
        onProgress: onProgress,
      ),
    );
  }

  Future<void> _restoreRemote(
    String type, {
    required Future<File> Function(void Function(int, int)?) download,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('从 $type 恢复备份'),
        content: const Text('远端备份会覆盖当前全部本地数据，建议先导出一次本地备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('下载并恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await _saveRemoteSettings();
    if (!mounted) return;

    final result = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProgressDialog(
        title: '从 $type 恢复备份',
        task: (update) async {
          final archiveFile = await download((received, total) {
            update(
              step: '正在从远端下载备份…',
              progress: total > 0 ? received / total : null,
              detail: total > 0
                  ? '${_formatSize(received)} / ${_formatSize(total)}'
                  : _formatSize(received),
            );
          });
          update(step: '正在恢复备份…', progress: null);
          try {
            await AppBackupService.instance.restoreBackupArchive(
              archiveFile.path,
              onStep: (step) {
                update(step: _restoreStepText(step), progress: null);
              },
            );
          } finally {
            if (await archiveFile.exists()) {
              await archiveFile.delete();
            }
          }
        },
      ),
    );

    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('从 $type 恢复成功')),
      );
      Navigator.pop(context);
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('从 $type 恢复失败：$result')),
      );
    }
  }

  Future<void> _runRemoteOperation(
    String operation,
    Future<void> Function() action,
  ) async {
    if (_isRemoteBusy) {
      return;
    }
    setState(() {
      _remoteOperation = operation;
    });
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$operation成功')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$operation失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _remoteOperation = null;
        });
      }
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });
    try {
      final path = await AppBackupService.instance.exportBackup();
      if (!mounted || path == null) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('备份已导出：$path')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('备份失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复备份'),
        content: const Text('恢复会覆盖当前全部本地数据，建议先执行一次备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('开始恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isRestoring = true;
    });
    try {
      final restored = await AppBackupService.instance.restoreBackupFromFile();
      if (!mounted || !restored) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('备份已恢复')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('恢复失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _handleClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除数据'),
        content: const Text('这会清除本地聊天记录、角色、世界书、预设、API 配置、应用设置和请求日志，且无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isClearing = true;
    });
    try {
      await AppDataService.instance.clearAllData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('本地数据已清除')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清除失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.trailing,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool trailing;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = destructive ? colorScheme.error : colorScheme.primary;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled ? null : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
          ],
        ),
      ),
    );
  }
}

class _RemoteBackupCard extends StatefulWidget {
  const _RemoteBackupCard({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.enabled,
    required this.expanded,
    required this.operation,
    required this.onTypeChanged,
    required this.onExpandedChanged,
    required this.onSave,
    required this.onTest,
    required this.fields,
  });

  final String title;
  final String subtitle;
  final RemoteBackupType type;
  final bool enabled;
  final bool expanded;
  final String? operation;
  final ValueChanged<RemoteBackupType> onTypeChanged;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onSave;
  final VoidCallback onTest;
  final List<Widget> fields;

  @override
  State<_RemoteBackupCard> createState() => _RemoteBackupCardState();
}

class _RemoteBackupCardState extends State<_RemoteBackupCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSaving = widget.operation == '保存配置';
    final isTesting =
        widget.operation == '测试 WebDAV' || widget.operation == '测试 S3';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              widget.onExpandedChanged(!widget.expanded);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.cloud_sync_outlined, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.chevron_right_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (widget.expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: widget.fields
                    .expand((field) => [field, const SizedBox(height: 10)])
                    .toList(growable: false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Row(
                children: [
                  SegmentedButton<RemoteBackupType>(
                    segments: const [
                      ButtonSegment<RemoteBackupType>(
                        value: RemoteBackupType.webdav,
                        label: Text('WebDAV'),
                      ),
                      ButtonSegment<RemoteBackupType>(
                        value: RemoteBackupType.s3,
                        label: Text('S3'),
                      ),
                    ],
                    selected: {widget.type},
                    showSelectedIcon: false,
                    onSelectionChanged: widget.enabled
                        ? (values) => widget.onTypeChanged(values.first)
                        : null,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '测试连接',
                    onPressed: widget.enabled ? widget.onTest : null,
                    icon: isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_ping),
                  ),
                  const SizedBox(width: 3),
                  FilledButton.icon(
                    onPressed: widget.enabled ? widget.onSave : null,
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('保存'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemoteTextField extends StatelessWidget {
  const _RemoteTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

typedef _ProgressUpdate = void Function({
  required String step,
  double? progress,
  String? detail,
});

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({
    required this.title,
    required this.task,
  });

  final String title;
  final Future<void> Function(_ProgressUpdate update) task;

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  String _step = '准备中…';
  double? _progress;
  String? _detail;

  @override
  void initState() {
    super.initState();
    Future.microtask(_startTask);
  }

  Future<void> _startTask() async {
    try {
      await widget.task(({required step, progress, detail}) {
        if (mounted) {
          setState(() {
            _step = step;
            _progress = progress;
            _detail = detail;
          });
        }
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) Navigator.of(context).pop(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_progress != null)
              LinearProgressIndicator(value: _progress)
            else
              const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _step,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (_detail != null) ...[
              const SizedBox(height: 8),
              Text(
                _detail!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
