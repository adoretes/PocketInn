import 'package:flutter/material.dart';

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
  }

  void _disposeControllersForItem(String id) {
    final itemControllers = _controllers[id];
    if (itemControllers == null) return;
    for (final controller in itemControllers.values) {
      controller.dispose();
    }
    _controllers.remove(id);
  }

  ApiConfig _applyControllersToItem(ApiConfig item) {
    final controllers = _controllers[item.id]!;
    item.name = controllers['name']!.text.trim().isEmpty
        ? item.name
        : controllers['name']!.text.trim();
    item.baseUrl = controllers['baseUrl']!.text.trim();
    item.apiKey = controllers['apiKey']!.text.trim();
    item.model = controllers['model']!.text.trim();
    item.customBody = controllers['customBody']!.text.trim();
    return item;
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
      setState(() {});
      await _persistConfigs(successMessage: '配置 "${updated.name}" 已保存');
    } on FormatException catch (error) {
      _showError(error.message.toString());
    } on Object catch (_) {
      _showError('自定义 body 不是合法 JSON');
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

  Future<void> _onModelFieldTap(
    ApiConfig item,
    BuildContext fieldContext,
  ) async {
    final draft = _buildDraftConfig(item);
    if (draft == null) return;

    setState(() {
      _loadingModelIds.add(item.id);
    });
    try {
      final models = await OpenAICompatibleApiService.instance.fetchModels(
        draft,
      );
      if (!mounted) return;
      _modelsByConfigId[item.id] = models;
      if (models.isEmpty) {
        _showError('未拉取到模型列表');
        return;
      }
      if (!fieldContext.mounted) {
        return;
      }
      await _showModelMenu(
        item: item,
        fieldContext: fieldContext,
        models: models,
      );
    } on FormatException catch (error) {
      _showError(error.message.toString());
    } on Object catch (error) {
      _showError('拉取模型失败: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingModelIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _showModelMenu({
    required ApiConfig item,
    required BuildContext fieldContext,
    required List<String> models,
  }) async {
    final controller = _controllers[item.id]?['model'];
    if (controller == null) return;

    final renderBox = fieldContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(fieldContext).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;

    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = RelativeRect.fromRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy,
        renderBox.size.width,
        renderBox.size.height,
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: rect,
      items: models
          .map(
            (model) => PopupMenuItem<String>(
              value: model,
              child: Text(model, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
    if (selected == null) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: selected,
      selection: TextSelection.collapsed(offset: selected.length),
      composing: TextRange.empty,
    );
    setState(() {
      item.model = selected;
    });
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String? hint,
    required int maxLines,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: maxLines > 1,
      border: const OutlineInputBorder(),
      suffixIcon: suffixIcon,
    );
  }

  Widget? _buildModelSuffix(ApiConfig item) {
    if (_loadingModelIds.contains(item.id)) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final models = _modelsByConfigId[item.id];
    if (models == null || models.isEmpty) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        '${models.length}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
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
      enabled: false,
    );
    _initControllersForItem(newItem);
    setState(() {
      _configItems.add(newItem);
      _expandedIds.add(newItem.id);
    });
  }

  Future<void> _toggleEnabled(ApiConfig item, bool value) async {
    setState(() {
      item.enabled = value;
    });
    await _persistConfigs();
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
                  Switch(
                    value: item.enabled,
                    onChanged: (value) => _toggleEnabled(item, value),
                    activeThumbColor: Colors.green,
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
                  _buildTextField(
                    controller: controllers['model']!,
                    label: 'Model',
                    hint: 'gpt-3.5-turbo, deepseek-chat, etc.',
                    onTapBuilder: (fieldContext) =>
                        _onModelFieldTap(item, fieldContext),
                    suffixIcon: _buildModelSuffix(item),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: controllers['customBody']!,
                    label: '自定义 Body',
                    hint: '{"temperature":0.7,"stream":true}',
                    maxLines: 6,
                  ),
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
                            : const Icon(Icons.link, size: 24),
                        color: Colors.blue,
                        tooltip: '测试连接',
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _deleteConfigItem(item),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: '删除配置',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveConfigItem(item),
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
    Widget? suffixIcon,
    Future<void> Function(BuildContext fieldContext)? onTapBuilder,
  }) {
    return Builder(
      builder: (fieldContext) => TextField(
        controller: controller,
        decoration: _buildInputDecoration(
          label: label,
          hint: hint,
          maxLines: obscureText ? 1 : maxLines,
          suffixIcon: suffixIcon,
        ),
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        minLines: obscureText
            ? 1
            : maxLines > 1
            ? 4
            : 1,
        style: const TextStyle(fontSize: 14),
        onTap: onTapBuilder == null ? null : () => onTapBuilder(fieldContext),
      ),
    );
  }
}
