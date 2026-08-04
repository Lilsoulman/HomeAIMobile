// 执行模式 30：开发者设置页 —— 切换 baseUrl / 清空登录态。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/env/env_config.dart';
import '../../features/auth/auth_controller.dart';

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({super.key});

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: EnvConfig.instance.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final value = _controller.text.trim();
    final uri = Uri.tryParse(value);
    if (value.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的 API 根地址')));
      return;
    }
    final auth = context.read<AuthController>();
    setState(() => _saving = true);
    final env = EnvConfig.instance;
    await env.setBaseUrl(value);
    if (!mounted) return;
    // 切地址必须清空登录态并跳登录页。
    await auth.clearAndLogout();
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('服务器已切换，请重新登录')));
  }

  Future<void> _reset() async {
    final auth = context.read<AuthController>();
    setState(() => _saving = true);
    await EnvConfig.instance.resetToDefault();
    _controller.text = EnvConfig.instance.baseUrl;
    await auth.clearAndLogout();
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('开发者设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'API 根地址',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例如 http://localhost:5280',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _apply,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('应用并重新登录'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('恢复默认'),
          ),
          const SizedBox(height: 24),
          Text(
            '提示',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '切换服务器会清空登录态，需要重新登录。',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
