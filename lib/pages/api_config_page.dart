import 'package:flutter/material.dart';

import '../core/error_handler.dart';
import '../data/api_configs.dart';
import '../models/api_config.dart';
import '../services/api_config_service.dart';
import '../services/openai_compatible_api_service.dart';

class OpenAICompatibleConfigPage extends StatefulWidget {
  const OpenAICompatibleConfigPage({super.key});

  @override
  State<OpenAICompatibleConfigPage> createState() =>
      _OpenAICompatibleConfigPageState();
}

class _OpenAICompatibleConfigPageState
    extends State<OpenAICompatibleConfigPage> {
  List<ApiConfig> _configItems = [];
  final Set<String> _expandedIds = <String>{};
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Set<String> _testingIds = <String>{};
  final Set<String> _loadingModelIds = <String>{};
  final Map<String, List<String>> _modelsByConfigId = {};
  final Map<String, FocusNode> _modelFocusNodes = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final items = apiConfigsNotifier.value
        .map((item) => item.copyWith())
        .toList();
    for (final item in items) {
      _initControllersForItem(item);
    }
    if (!mounted) return;
    setState(() {
      _configItems = items;
    });
  }

  void _initControllersForItem(ApiConfig item) {
    if (_controllers.containsKey(item.id)) return;
    _controllers[item.id] = {
      'name': TextEditingController(text: item.name),
      'baseUrl': TextEditingController(text: item.baseUrl),
      'apiKey': TextEditingController(text: item.apiKey),
      'model': TextEditingController(text: item.model),
      'customBody': TextEditingController(text: item.customBody),
    };
    final focusNode = FocusNode();
    _modelFocusNodes[item.id] = focusNode;
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _fetchModels(item.id);
      }
    });
  }

  void _disposeControllersForItem(String id) {
    final itemControllers = _controllers[id];
    if (itemControllers == null) return;
    for (final controller in itemControllers.values) {
      controller.dispose();
    }
    _controllers.remove(id);
    _modelFocusNodes[id]?.dispose();
    _modelFocusNodes.remove(id);
  }

  ApiConfig _applyControllersToItem(ApiConfig item) {
    final controllers = _controllers[item.id]!;
    final nameText = controllers['name']!.text.trim();
    return item.copyWith(
      name: nameText.isEmpty ? item.name : nameText,
      baseUrl: controllers['baseUrl']!.text.trim(),
      apiKey: controllers['apiKey']!.text.trim(),
      model: controllers['model']!.text.trim(),
      customBody: controllers['customBody']!.text.trim(),
    );
  }

  void _replaceConfigItem(ApiConfig updated) {
    final index = _configItems.indexWhere((i) => i.id == updated.id);
    if (index < 0) return;
    setState(() {
      _configItems[index] = updated;
    });
  }

  Future<void> _persistConfigs({String? successMessage}) async {
    setState(() {
      _isSaving = true;
    });
    try {
      await updateApiConfigs(_configItems);
      if (!mounted || successMessage == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveConfigItem(ApiConfig item) async {
    final controllers = _controllers[item.id];
    if (controllers == null) return;

    final name = controllers['name']!.text.trim();
    if (name.isEmpty) {
      _showError('配置名称不能为空');
      return;
    }

    try {
      final updated = _applyControllersToItem(item);
      updated.parseCustomBody();
      _replaceConfigItem(updated);
      await _persistConfigs(successMessage: '配置 "${updated.name}" 已保存');
    } on FormatException catch (error) {
      _showError(error.message.toString());
    } on Object catch (error) {
      if (!mounted) return;
      handleAppException(
        context,
        toAppException(error, fallbackMessage: '自定义 body 不是合法 JSON'),
      );
    }
  }

  ApiConfig? _buildDraftConfig(ApiConfig item) {
    final controllers = _controllers[item.id];
    if (controllers == null) return null;

    return item.copyWith(
      name: controllers['name']!.text.trim(),
      baseUrl: controllers['baseUrl']!.text.trim(),
      apiKey: controllers['apiKey']!.text.trim(),
      model: controllers['model']!.text.trim(),
      customBody: controllers['customBody']!.text.trim(),
    );
  }

  Future<void> _onTestConnection(ApiConfig item) async {
    final draft = _buildDraftConfig(item);
    if (draft == null) return;

    setState(() {
      _testingIds.add(item.id);
    });
    try {
      final result = await OpenAICompatibleApiService.instance.testConnection(
        draft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? (result.isPartial ? Colors.orange : Colors.green)
              : Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _testingIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _fetchModels(String configId) async {
    if (_loadingModelIds.contains(configId)) return;
    final cached = _modelsByConfigId[configId];
    if (cached != null && cached.isNotEmpty) return;

    final itemIndex = _configItems.indexWhere((i) => i.id == configId);
    if (itemIndex < 0) return;
    final item = _configItems[itemIndex];
    final draft = _buildDraftConfig(item);
    if (draft == null) return;

    setState(() {
      _loadingModelIds.add(configId);
    });
    try {
      final models = await OpenAICompatibleApiService.instance.fetchModels(
        draft,
      );
      if (!mounted) return;
      setState(() {
        _modelsByConfigId[configId] = models;
        _loadingModelIds.remove(configId);
      });
      if (models.isEmpty) {
        _showError('未拉取到模型列表');
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _loadingModelIds.remove(configId);
        });
        _showError(error.message.toString());
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loadingModelIds.remove(configId);
        });
        _showError('拉取模型失败: $error');
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String? hint,
    required int maxLines,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: maxLines > 1,
      border: const OutlineInputBorder(),
    );
  }

  Widget _buildModelDropdownMenu(ApiConfig item) {
    final controller = _controllers[item.id]!['model']!;
    final models = _modelsByConfigId[item.id] ?? [];
    final isLoading = _loadingModelIds.contains(item.id);
    final focusNode = _modelFocusNodes[item.id]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          controller: controller,
          focusNode: focusNode,
          enableFilter: true,
          menuHeight: 300,
          hintText: 'gpt-3.5-turbo, deepseek-chat, etc.',
          trailingIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.arrow_drop_down),
          dropdownMenuEntries: models
              .map(
                (model) => DropdownMenuEntry<String>(
                  value: model,
                  label: model,
                  labelWidget: Text(model, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onSelected: (value) {
            if (value != null) {
              _replaceConfigItem(item.copyWith(model: value));
            }
          },
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        );
      },
    );
  }

  Future<void> _showCustomBodyDialog(ApiConfig item) async {
    final controller = _controllers[item.id]?['customBody'];
    if (controller == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('自定义 Body'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: TextField(
              controller: controller,
              maxLines: 12,
              minLines: 8,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '{"temperature":0.7,"stream":true}',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('完成'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConfigItem(ApiConfig item) async {
    setState(() {
      _configItems.removeWhere((i) => i.id == item.id);
      _expandedIds.remove(item.id);
      _disposeControllersForItem(item.id);
    });
    await _persistConfigs(successMessage: '已删除配置: ${item.name}');
  }

  void _createNewConfig() {
    final newItem = ApiConfig(
      id: ApiConfigService.instance.generateId(),
      name: '新配置',
      baseUrl: '',
      apiKey: '',
      model: '',
      customBody: '',
    );
    _initControllersForItem(newItem);
    setState(() {
      _configItems.add(newItem);
      _expandedIds.add(newItem.id);
    });
  }

  void _toggleExpanded(ApiConfig item) {
    setState(() {
      if (_expandedIds.contains(item.id)) {
        _expandedIds.remove(item.id);
      } else {
        _expandedIds.add(item.id);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    for (final controllers in _controllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    for (final focusNode in _modelFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 配置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewConfig,
            tooltip: '新建配置',
          ),
        ],
      ),
      body: _configItems.isEmpty
          ? const Center(child: Text('暂无配置，点击右上角 + 新建'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _configItems.length,
              itemBuilder: (context, index) {
                final item = _configItems[index];
                if (!_controllers.containsKey(item.id)) {
                  _initControllersForItem(item);
                }
                return _buildConfigCard(item);
              },
            ),
    );
  }

  Widget _buildConfigCard(ApiConfig item) {
    final controllers = _controllers[item.id]!;
    final isExpanded = _expandedIds.contains(item.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpanded(item),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controllers['name']!,
                    label: '配置名称',
                    hint: '例如: DeepSeek',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: controllers['baseUrl']!,
                    label: 'Base URL',
                    hint: 'https://api.openai.com/v1',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: controllers['apiKey']!,
                    label: 'API Key',
                    hint: 'sk-...',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _buildModelDropdownMenu(item),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _testingIds.contains(item.id)
                            ? null
                            : () => _onTestConnection(item),
                        icon: _testingIds.contains(item.id)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.network_ping, size: 22),
                        tooltip: '测试连接',
                      ),
                      IconButton(
                        onPressed: () => _showCustomBodyDialog(item),
                        icon: const Icon(Icons.code, size: 22),
                        tooltip: '自定义 Body',
                      ),
                      IconButton(
                        onPressed: () => _deleteConfigItem(item),
                        icon: const Icon(Icons.delete_outline, size: 22),
                        tooltip: '删除配置',
                      ),
                      const SizedBox(width: 4),
                      FilledButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveConfigItem(item),
                        label: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: _buildInputDecoration(
        label: label,
        hint: hint,
        maxLines: maxLines,
      ),
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText
          ? 1
          : maxLines > 1
          ? 4
          : 1,
      style: const TextStyle(fontSize: 14),
    );
  }
}
