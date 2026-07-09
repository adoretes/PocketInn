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
  // Provider 级文本控制器：name / baseUrl / apiKey
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  // 每个 model 的 modelId / customBody 控制器，按 model.id 索引
  final Map<String, TextEditingController> _modelIdControllers = {};
  final Map<String, TextEditingController> _customBodyControllers = {};
  final Set<String> _testingIds = <String>{};
  final Set<String> _loadingModelIds = <String>{}; // provider ids 拉取中
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
      for (final m in item.models) {
        _initModelControllers(m);
      }
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
    };
  }

  void _initModelControllers(ApiModel model) {
    if (_modelIdControllers.containsKey(model.id)) return;
    _modelIdControllers[model.id] = TextEditingController(text: model.modelId);
    _customBodyControllers[model.id] = TextEditingController(
      text: model.customBody,
    );
  }

  void _disposeControllersForItem(String id) {
    final itemControllers = _controllers[id];
    if (itemControllers == null) return;
    for (final controller in itemControllers.values) {
      controller.dispose();
    }
    _controllers.remove(id);
  }

  void _disposeModelControllers(String modelId) {
    _modelIdControllers[modelId]?.dispose();
    _customBodyControllers[modelId]?.dispose();
    _modelIdControllers.remove(modelId);
    _customBodyControllers.remove(modelId);
  }

  ApiConfig _applyControllersToItem(ApiConfig item) {
    final controllers = _controllers[item.id]!;
    final nameText = controllers['name']!.text.trim();
    final updatedModels = item.models.map((m) {
      final modelIdCtl = _modelIdControllers[m.id]!;
      final customBodyCtl = _customBodyControllers[m.id]!;
      return m.copyWith(
        modelId: modelIdCtl.text.trim(),
        customBody: customBodyCtl.text.trim(),
      );
    }).toList();
    return item.copyWith(
      name: nameText.isEmpty ? item.name : nameText,
      baseUrl: controllers['baseUrl']!.text.trim(),
      apiKey: controllers['apiKey']!.text.trim(),
      models: updatedModels,
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
      // 校验每个 model 的 customBody 是否合法 JSON
      for (final m in updated.models) {
        m.parseCustomBody();
      }
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
    final updatedModels = item.models.map((m) {
      final modelIdCtl = _modelIdControllers[m.id];
      final customBodyCtl = _customBodyControllers[m.id];
      return m.copyWith(
        modelId: modelIdCtl?.text.trim() ?? m.modelId,
        customBody: customBodyCtl?.text.trim() ?? m.customBody,
      );
    }).toList();
    return item.copyWith(
      name: controllers['name']!.text.trim(),
      baseUrl: controllers['baseUrl']!.text.trim(),
      apiKey: controllers['apiKey']!.text.trim(),
      models: updatedModels,
    );
  }

  Future<void> _onTestConnection(ApiConfig item) async {
    final draft = _buildDraftConfig(item);
    if (draft == null) return;
    if (draft.models.isEmpty) {
      _showError('请先添加至少一个模型再测试连接');
      return;
    }

    setState(() {
      _testingIds.add(item.id);
    });
    try {
      final result = await OpenAICompatibleApiService.instance.testConnection(
        draft.resolveFirstOrEmpty(),
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

  /// 拉取远端模型列表，弹多选框，把勾选的模型作为新条目批量添加到当前 provider 下。
  /// 已存在的 modelId 会被自动过滤，避免重复。
  Future<void> _showFetchModelsDialog(ApiConfig item) async {
    if (_loadingModelIds.contains(item.id)) return;
    final draft = _buildDraftConfig(item);
    if (draft == null) return;

    setState(() {
      _loadingModelIds.add(item.id);
    });
    try {
      final models = await OpenAICompatibleApiService.instance.fetchModels(
        draft.resolveFirstOrEmpty(),
      );
      if (!mounted) return;
      if (models.isEmpty) {
        _showError('未拉取到模型列表');
        return;
      }
      // 过滤掉已存在的 modelId，避免重复添加
      final existingIds = item.models
          .map((m) => m.modelId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      final candidates = models
          .where((m) => !existingIds.contains(m.modelId))
          .toList(growable: false);
      if (candidates.isEmpty) {
        _showError('远端模型已全部存在，无需重复添加');
        return;
      }

      final selectedIds = await showDialog<Set<String>>(
        context: context,
        builder: (_) => _FetchModelsDialog(candidates: candidates),
      );
      if (selectedIds == null || selectedIds.isEmpty) return;

      final itemIndex = _configItems.indexWhere((i) => i.id == item.id);
      if (itemIndex < 0) return;
      final newModels = <ApiModel>[];
      for (final modelId in selectedIds) {
        final newModel = ApiModel(
          id: ApiConfigService.instance.generateModelId(),
          modelId: modelId,
          customBody: '',
        );
        _initModelControllers(newModel);
        newModels.add(newModel);
      }
      setState(() {
        _configItems[itemIndex] = item.copyWith(
          models: [...item.models, ...newModels],
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 ${newModels.length} 个模型')),
        );
      }
    } on FormatException catch (error) {
      if (mounted) _showError(error.message.toString());
    } on Object catch (error) {
      if (mounted) _showError('拉取模型失败: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingModelIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _showCustomBodyDialog(ApiModel model) async {
    final controller = _customBodyControllers[model.id];
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

  void _addModel(ApiConfig item) {
    final itemIndex = _configItems.indexWhere((i) => i.id == item.id);
    if (itemIndex < 0) return;
    final newModel = ApiModel(
      id: ApiConfigService.instance.generateModelId(),
      modelId: '',
      customBody: '',
    );
    _initModelControllers(newModel);
    setState(() {
      _configItems[itemIndex] = item.copyWith(
        models: [...item.models, newModel],
      );
    });
  }

  Future<void> _deleteModel(ApiConfig item, ApiModel model) async {
    final itemIndex = _configItems.indexWhere((i) => i.id == item.id);
    if (itemIndex < 0) return;
    _disposeModelControllers(model.id);
    setState(() {
      _configItems[itemIndex] = item.copyWith(
        models: item.models.where((m) => m.id != model.id).toList(),
      );
    });
  }

  Future<void> _deleteConfigItem(ApiConfig item) async {
    for (final m in item.models) {
      _disposeModelControllers(m.id);
    }
    setState(() {
      _configItems.removeWhere((i) => i.id == item.id);
      _expandedIds.remove(item.id);
      _disposeControllersForItem(item.id);
    });
    await _persistConfigs(successMessage: '已删除配置: ${item.name}');
  }

  void _reorderConfigs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _configItems.removeAt(oldIndex);
      _configItems.insert(newIndex, item);
    });
    _persistConfigs();
  }

  void _createNewConfig() {
    final newItem = ApiConfig(
      id: ApiConfigService.instance.generateId(),
      name: '新配置',
      baseUrl: '',
      apiKey: '',
      models: const [],
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
    for (final c in _modelIdControllers.values) {
      c.dispose();
    }
    for (final c in _customBodyControllers.values) {
      c.dispose();
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
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _configItems.length,
              onReorder: _reorderConfigs,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => child,
              itemBuilder: (context, index) {
                final item = _configItems[index];
                if (!_controllers.containsKey(item.id)) {
                  _initControllersForItem(item);
                  for (final m in item.models) {
                    _initModelControllers(m);
                  }
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
      key: ValueKey(item.id),
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
                  ReorderableDragStartListener(
                    index: _configItems.indexOf(item),
                    child: const Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '模型数：${item.models.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 16),
                  _buildModelsList(item),
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
                        onPressed: () => _deleteConfigItem(item),
                        icon: const Icon(Icons.delete_outline, size: 22),
                        tooltip: '删除配置',
                      ),
                      const SizedBox(width: 4),
                      FilledButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveConfigItem(item),
                        icon: const Icon(Icons.save_outlined, size: 18),
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

  Widget _buildModelsList(ApiConfig item) {
    final isLoading = _loadingModelIds.contains(item.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '模型列表（${item.models.length}）',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () => _addModel(item),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: isLoading ? null : () => _showFetchModelsDialog(item),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 18),
              label: const Text('拉取'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (item.models.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '尚未添加模型，可手填或点"拉取"从远端批量添加',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          )
        else
          for (final model in item.models)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _modelIdControllers[model.id],
                      decoration: const InputDecoration(
                        labelText: 'Model ID',
                        hintText: 'deepseek-chat',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCustomBodyDialog(model),
                    icon: const Icon(Icons.code, size: 20),
                    tooltip: '自定义 Body',
                  ),
                  IconButton(
                    onPressed: () => _deleteModel(item, model),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: '删除模型',
                  ),
                ],
              ),
            ),
      ],
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
}

class _FetchModelsDialog extends StatefulWidget {
  final List<FetchedModelInfo> candidates;

  const _FetchModelsDialog({required this.candidates});

  @override
  State<_FetchModelsDialog> createState() => _FetchModelsDialogState();
}

class _FetchModelsDialogState extends State<_FetchModelsDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _selected = <String>{};
  final _collapsedGroups = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FetchedModelInfo> get _filtered {
    if (_searchQuery.isEmpty) return widget.candidates;
    final q = _searchQuery.toLowerCase();
    return widget.candidates
        .where((m) => m.modelId.toLowerCase().contains(q))
        .toList();
  }

  Map<String?, List<FetchedModelInfo>> get _grouped {
    final result = <String?, List<FetchedModelInfo>>{};
    for (final m in _filtered) {
      result.putIfAbsent(m.ownedBy ?? '', () => []).add(m);
    }
    return result;
  }

  bool get _allSelected =>
      _filtered.every((m) => _selected.contains(m.modelId));

  int get _totalCount => widget.candidates.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.removeAll(_filtered.map((m) => m.modelId));
      } else {
        _selected.addAll(_filtered.map((m) => m.modelId));
      }
    });
  }

  void _toggleGroup(String? groupKey, List<FetchedModelInfo> models) {
    setState(() {
      final all = models.every((m) => _selected.contains(m.modelId));
      if (all) {
        _selected.removeAll(models.map((m) => m.modelId));
      } else {
        _selected.addAll(models.map((m) => m.modelId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    return AlertDialog(
      title: const Text('选择要添加的模型'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.88,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索模型...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) => setState(() {
                _searchQuery = v;
                if (v.isNotEmpty) _collapsedGroups.clear();
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _filtered.isEmpty ? null : _toggleAll,
                  icon: Icon(
                    _allSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 20,
                  ),
                  label: Text(
                    _allSelected ? '取消全选' : '全选',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const Spacer(),
                Text(
                  '已选 ${_selected.length} / $_totalCount',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty ? '暂无可用模型' : '未找到匹配的模型',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final entry in groups.entries)
                          _buildGroup(entry.key, entry.value),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(Set.of(_selected)),
          child: Text(
            _selected.isEmpty
                ? '添加'
                : '添加 (${_selected.length})',
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(String? groupKey, List<FetchedModelInfo> models) {
    final label = (groupKey?.isNotEmpty == true) ? groupKey! : '其他';
    final allSelected = models.every((m) => _selected.contains(m.modelId));
    final isCollapsed = _collapsedGroups.contains(groupKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleGroup(groupKey, models),
                child: Icon(
                  allSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 18,
                  color: Colors.grey[700],
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isCollapsed) {
                        _collapsedGroups.remove(groupKey);
                      } else {
                        _collapsedGroups.add(groupKey!);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${models.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isCollapsed
                              ? Icons.expand_more
                              : Icons.expand_less,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isCollapsed)
          for (final m in models)
            ListTile(
              onTap: () {
                setState(() {
                  if (_selected.contains(m.modelId)) {
                    _selected.remove(m.modelId);
                  } else {
                    _selected.add(m.modelId);
                  }
                });
              },
              selected: _selected.contains(m.modelId),
              title: Text(
                m.modelId,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
              subtitle: m.ownedBy?.isNotEmpty == true
                  ? Text(
                      m.ownedBy!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    )
                  : null,
              dense: true,
              contentPadding: const EdgeInsets.only(left: 0, right: 8),
              trailing: _selected.contains(m.modelId)
                  ? const Icon(Icons.check, size: 18)
                  : null,
              visualDensity: VisualDensity.compact,
            ),
      ],
    );
  }
}
