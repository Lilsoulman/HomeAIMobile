import 'package:flutter/material.dart';

import '../../features/ai/ai_repository.dart';

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
    } catch (error) {
      if (mounted) _notice('加载配置失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({bool test = false}) async {
    if (_endpoint.text.trim().isEmpty || _model.text.trim().isEmpty) {
      _notice('请填写 endpoint 和模型名');
      return;
    }
    setState(() => _saving = true);
    try {
      final config = await widget.repository.updateConfig(
        endpoint: _endpoint.text.trim(),
        model: _model.text.trim(),
        temperature: _temperature,
        apiKey: _apiKey.text,
      );
      _hasApiKey = config.hasApiKey;
      _apiKey.clear();
      if (test) await widget.repository.testConnection();
      if (mounted) _notice(test ? '连接正常' : 'AI 配置已保存');
    } catch (error) {
      if (mounted) _notice('${test ? '测试' : '保存'}失败：$error');
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
                  labelText: _hasApiKey ? '更新 API Key（已配置）' : 'API Key',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 22),
              Text('温度：${_temperature.toStringAsFixed(1)}'),
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
            ],
          ),
  );
}
