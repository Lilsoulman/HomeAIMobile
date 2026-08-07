// 连接中心，按 8.14 契约消费 HttpConnectorRepository。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/connector/connector_repository.dart';

class ConnectorCenterPage extends StatefulWidget {
  const ConnectorCenterPage({super.key});

  @override
  State<ConnectorCenterPage> createState() => _ConnectorCenterPageState();
}

class _ConnectorCenterPageState extends State<ConnectorCenterPage> {
  late Future<_ConnectorCenterData> _data;
  String? _workingKey;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _data = _load();

  Future<_ConnectorCenterData> _load() async {
    final repository = context.read<ConnectorRepository>();
    final results = await Future.wait<Object>([
      repository.listConnectors(),
      repository.listProviders(),
    ]);
    return _ConnectorCenterData(
      connectors: results[0] as List<ConnectorDto>,
      providers: results[1] as List<ConnectorProviderDto>,
    );
  }

  Future<void> _runConnectorCommand(
    ConnectorDto connector,
    Future<ConnectorDto> Function(ConnectorRepository repository) command,
  ) async {
    setState(() => _workingKey = connector.id.toString());
    try {
      await command(context.read<ConnectorRepository>());
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (error) {
      if (mounted) _showFailure(error.msg);
    } catch (_) {
      if (mounted) _showFailure('连接服务暂时无法处理，请稍后重试。');
    } finally {
      if (mounted) setState(() => _workingKey = null);
    }
  }

  Future<void> _beginAuthorization(ConnectorProviderDto provider) async {
    setState(() => _workingKey = provider.code);
    try {
      await context.read<ConnectorRepository>().beginAuthorization(
        provider.code,
      );
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (error) {
      if (mounted) _showFailure(error.msg);
    } catch (_) {
      if (mounted) _showFailure('暂时无法开始连接，请稍后重试。');
    } finally {
      if (mounted) setState(() => _workingKey = null);
    }
  }

  Future<void> _confirmDisconnect(ConnectorDto connector) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('断开"${connector.name}"'),
        content: const Text('断开后，NexusMind 将停止访问这项服务，直到你重新连接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('断开'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runConnectorCommand(
      connector,
      (repository) => repository.disconnect(connector.id.toString()),
    );
  }

  void _showFailure(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('连接'),
      actions: [
        IconButton(
          tooltip: '刷新',
          onPressed: _workingKey == null ? () => setState(_reload) : null,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: FutureBuilder<_ConnectorCenterData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ConnectorLoadError(onRetry: () => setState(_reload));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final connectedProviderCodes = data.connectors
              .map((c) => c.providerCode)
              .toSet();
          final availableProviders = data.providers
              .where((p) => !connectedProviderCodes.contains(p.code))
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _data;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: NexusLayout.pagePadding.copyWith(bottom: 36),
              children: [
                Text('连接服务', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  '管理家庭服务的数据访问与连接状态。凭据不会显示在这里。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: NexusLayout.sectionGap),
                Text('已添加的服务', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (data.connectors.isEmpty)
                  const _ConnectorEmpty()
                else
                  ...data.connectors.map(
                    (connector) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ConnectorCard(
                        connector: connector,
                        busy:
                            _workingKey == connector.id.toString() ||
                            _workingKey == connector.providerCode,
                        onCommand: (command) =>
                            _runConnectorCommand(connector, command),
                        onDisconnect: () => _confirmDisconnect(connector),
                      ),
                    ),
                  ),
                if (availableProviders.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('可添加的服务', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  NexusSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: availableProviders
                          .map(
                            (provider) => Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                leading: const Icon(Icons.add_link_outlined),
                                title: Text(provider.name),
                                subtitle: Text(provider.description),
                                trailing: IconButton(
                                  tooltip: '连接${provider.name}',
                                  onPressed: _workingKey == null
                                      ? () => _beginAuthorization(provider)
                                      : null,
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _ConnectorCenterData {
  const _ConnectorCenterData({
    required this.connectors,
    required this.providers,
  });

  final List<ConnectorDto> connectors;
  final List<ConnectorProviderDto> providers;
}

class _ConnectorCard extends StatelessWidget {
  const _ConnectorCard({
    required this.connector,
    required this.busy,
    required this.onCommand,
    required this.onDisconnect,
  });

  final ConnectorDto connector;
  final bool busy;
  final void Function(
    Future<ConnectorDto> Function(ConnectorRepository repository) command,
  )
  onCommand;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(context, connector.status);
    final lastSync = connector.lastSyncAt;
    final lastHealth = connector.lastHealthAt;
    return NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status.icon, color: status.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  connector.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                status.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (lastHealth != null)
            Text(
              '上次健康检查：${_formatTime(lastHealth)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (lastSync != null)
            Text(
              '上次同步：${_formatTime(lastSync)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => _runPrimaryCommand(connector),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_primaryIcon(connector.status)),
                label: Text(_primaryLabel(connector.status)),
              ),
              if (connector.status != ConnectorConnectionStatus.disconnected)
                TextButton(
                  onPressed: busy ? null : onDisconnect,
                  child: const Text('断开'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _runPrimaryCommand(ConnectorDto connector) {
    switch (connector.status) {
      case ConnectorConnectionStatus.connected:
        onCommand((repository) => repository.discover(connector.id.toString()));
      case ConnectorConnectionStatus.authorizing:
      case ConnectorConnectionStatus.discovering:
      case ConnectorConnectionStatus.failed:
        onCommand((repository) => repository.retry(connector.id.toString()));
      case ConnectorConnectionStatus.disconnected:
        onCommand(
          (repository) => repository.beginAuthorization(connector.providerCode),
        );
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final M = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$M-$d $h:$m';
  }
}

class _ConnectorEmpty extends StatelessWidget {
  const _ConnectorEmpty();

  @override
  Widget build(BuildContext context) =>
      const NexusSurface(child: Text('还没有添加服务。你可以从下方开始连接。'));
}

class _ConnectorLoadError extends StatelessWidget {
  const _ConnectorLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: NexusLayout.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          const Text('连接服务暂时无法加载。'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    ),
  );
}

_ConnectorStatusPresentation _statusPresentation(
  BuildContext context,
  ConnectorConnectionStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    ConnectorConnectionStatus.connected => _ConnectorStatusPresentation(
      label: '在线',
      icon: Icons.check_circle_outline,
      color: scheme.secondary,
    ),
    ConnectorConnectionStatus.authorizing => _ConnectorStatusPresentation(
      label: '授权中',
      icon: Icons.key_outlined,
      color: scheme.primary,
    ),
    ConnectorConnectionStatus.discovering => _ConnectorStatusPresentation(
      label: '发现中',
      icon: Icons.radar_outlined,
      color: scheme.primary,
    ),
    ConnectorConnectionStatus.disconnected => _ConnectorStatusPresentation(
      label: '未连接',
      icon: Icons.link_off_outlined,
      color: scheme.onSurfaceVariant,
    ),
    ConnectorConnectionStatus.failed => _ConnectorStatusPresentation(
      label: '需重试',
      icon: Icons.error_outline,
      color: scheme.error,
    ),
  };
}

String _primaryLabel(ConnectorConnectionStatus status) => switch (status) {
  ConnectorConnectionStatus.connected => '发现设备',
  ConnectorConnectionStatus.authorizing => '完成授权',
  ConnectorConnectionStatus.discovering => '重新检查',
  ConnectorConnectionStatus.disconnected => '开始连接',
  ConnectorConnectionStatus.failed => '重试',
};

IconData _primaryIcon(ConnectorConnectionStatus status) => switch (status) {
  ConnectorConnectionStatus.connected => Icons.radar_outlined,
  ConnectorConnectionStatus.authorizing => Icons.verified_user_outlined,
  ConnectorConnectionStatus.discovering => Icons.refresh_rounded,
  ConnectorConnectionStatus.disconnected => Icons.add_link_outlined,
  ConnectorConnectionStatus.failed => Icons.refresh_rounded,
};

class _ConnectorStatusPresentation {
  const _ConnectorStatusPresentation({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
