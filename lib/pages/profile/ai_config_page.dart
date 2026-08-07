import 'package:flutter/material.dart';

import '../../features/ai/ai_repository.dart';

enum _AiConfigMode { add, view, edit }

class AiConfigPage extends StatefulWidget {
  const AiConfigPage({super.key, required this.repository});
  final AiRepository repository;

  @override
  State<AiConfigPage> createState() => _AiConfigPageState();
}

class _AiConfigPageState extends State<AiConfigPage> {
  final _endpoint = TextEditingController();
  final _model = TextEditingController();
  final _apiKey = TextEditingController();
  double _temperature = .7;
  bool _loading = true;
  bool _saving = false;
  bool _hasApiKey = false;
  bool _enabled = true;
  _AiConfigMode _mode = _AiConfigMode.add;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final config = await widget.repository.getConfig();
      _endpoint.text = config.endpoint ?? '';
      _model.text = config.model ?? '';
      _temperature = config.temperature;
      _hasApiKey = config.hasApiKey;
      _enabled = config.enabled;
      _mode = (config.endpoint?.trim().isNotEmpty ?? false)
          ? _AiConfigMode.view
          : _AiConfigMode.add;
    } catch (error) {
      if (mounted) _notice('加载配置失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startEdit() {
    _apiKey.clear();
    setState(() => _mode = _AiConfigMode.edit);
  }

  Future<void> _save({bool test = false}) async {
    if (_endpoint.text.trim().isEmpty || _model.text.trim().isEmpty) {
      _notice('请填写 endpoint 和模型名');
      return;
    }
    if (_apiKey.text.trim().isEmpty) {
      _notice('请填写 API Key');
      return;
    }
    setState(() => _saving = true);
    try {
      final config = await widget.repository.updateConfig(
        endpoint: _endpoint.text.trim(),
        model: _model.text.trim(),
        temperature: _temperature,
        enabled: _enabled,
        apiKey: _apiKey.text,
      );
      _hasApiKey = config.hasApiKey;
      _enabled = config.enabled;
      _apiKey.clear();
      if (test) await widget.repository.testConnection();
      if (mounted) {
        setState(() => _mode = _AiConfigMode.view);
        _notice(test ? '连接正常' : 'AI 配置已保存');
      }
    } catch (error) {
      if (mounted) _notice('${test ? '测试' : '保存'}失败：$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() {
      _enabled = value;
      _saving = true;
    });
    try {
      final config = await widget.repository.updateConfig(
        endpoint: _endpoint.text.trim(),
        model: _model.text.trim(),
        temperature: _temperature,
        enabled: value,
      );
      _enabled = config.enabled;
      if (mounted) _notice(value ? 'AI 已启用' : 'AI 已禁用');
    } catch (error) {
      if (mounted) _notice('切换失败：$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  void dispose() {
    _endpoint.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI 配置')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('密钥仅提交给 NexusMind 服务端加密保存，不会回传到客户端。'),
              const SizedBox(height: 18),
              if (_mode == _AiConfigMode.view)
                ..._buildViewMode(context)
              else
                ..._buildEditMode(context),
            ],
          ),
  );

  List<Widget> _buildViewMode(BuildContext context) => [
    SwitchListTile(
      value: _enabled,
      onChanged: _saving ? null : _toggleEnabled,
      title: const Text('启用 AI 能力'),
      subtitle: const Text('关闭后 AI 生成功能不可用'),
    ),
    const SizedBox(height: 4),
    _InfoTile(
      icon: Icons.dns_outlined,
      label: 'Endpoint',
      value: _endpoint.text,
    ),
    _InfoTile(icon: Icons.smart_toy_outlined, label: '模型', value: _model.text),
    _InfoTile(
      icon: Icons.thermostat_outlined,
      label: '温度',
      value: '${_temperature.toStringAsFixed(1)}（严谨↔创意）',
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: _saving ? null : _startEdit,
      icon: const Icon(Icons.edit_outlined),
      label: const Text('编辑配置'),
    ),
  ];

  List<Widget> _buildEditMode(BuildContext context) => [
    TextField(
      controller: _endpoint,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'OpenAI 兼容 Endpoint',
        hintText: 'https://api.openai.com/v1',
        border: OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 14),
    TextField(
      controller: _model,
      decoration: const InputDecoration(
        labelText: '模型',
        hintText: 'gpt-4.1-mini',
        border: OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 14),
    TextField(
      controller: _apiKey,
      obscureText: true,
      decoration: InputDecoration(
        labelText: _hasApiKey ? 'API Key（已配置，需重新输入）' : 'API Key',
        border: const OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 22),
    Text('温度：${_temperature.toStringAsFixed(1)}'),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('严谨', style: Theme.of(context).textTheme.bodySmall),
          Text('创意', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
    Slider(
      min: 0,
      max: 1,
      divisions: 10,
      value: _temperature,
      label: _temperature.toStringAsFixed(1),
      onChanged: _saving
          ? null
          : (value) => setState(() => _temperature = value),
    ),
    const SizedBox(height: 10),
    FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: const Icon(Icons.save_outlined),
      label: const Text('保存配置'),
    ),
    const SizedBox(height: 10),
    OutlinedButton.icon(
      onPressed: _saving ? null : () => _save(test: true),
      icon: const Icon(Icons.wifi_tethering_outlined),
      label: const Text('保存并测试连接'),
    ),
  ];
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
