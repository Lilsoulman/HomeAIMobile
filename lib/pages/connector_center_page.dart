// 连接中心：家庭连接状态（8.14）+ 我的个人连接（B18 授权 / B19 汇总）。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/connector/connector_repository.dart';

class ConnectorCenterPage extends StatefulWidget {
  const ConnectorCenterPage({super.key});

  @override
  State<ConnectorCenterPage> createState() => _ConnectorCenterPageState();
}

class _ConnectorCenterPageState extends State<ConnectorCenterPage>
    with WidgetsBindingObserver {
  late Future<_ConnectorCenterData> _data;
  String? _workingKey;
  Timer? _sessionPoller;
  int? _pollingSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionPoller?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从系统浏览器返回时立即补一轮查询，不等下一个轮询 tick。
    if (state == AppLifecycleState.resumed && _pollingSessionId != null) {
      _pollOnce(_pollingSessionId!);
    }
  }

  void _reload() {
    _data = _load();
  }

  Future<_ConnectorCenterData> _load() async {
    final repository = context.read<ConnectorRepository>();
    final results = await Future.wait<Object>([
      repository.listConnectors(),
      repository.listProviders(),
      repository.listMyPersonalConnections(),
    ]);
    return _ConnectorCenterData(
      connectors: results[0] as List<ConnectorDto>,
      providers: results[1] as List<ConnectorProviderDto>,
      personal: results[2] as List<PersonalConnectionSummaryDto>,
    );
  }

  void _startPolling(int sessionId) {
    _sessionPoller?.cancel();
    _pollingSessionId = sessionId;
    _sessionPoller = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollOnce(sessionId),
    );
  }

  Future<void> _pollOnce(int sessionId) async {
    try {
      final session = await context
          .read<ConnectorRepository>()
          .fetchAuthorizationSession(sessionId);
      final terminal = session.status != AuthorizationSessionStatus.pending;
      final expired =
          session.expiresAt != null &&
          !session.expiresAt!.isAfter(DateTime.now());
      if (terminal || expired) {
        _sessionPoller?.cancel();
        _sessionPoller = null;
        _pollingSessionId = null;
        if (mounted) setState(_reload);
      }
    } catch (_) {
      // 瞬时错误吞掉继续轮询，受会话过期上界约束。
    }
  }

  Future<void> _startPersonalAuthorization(String providerCode) async {
    setState(() => _workingKey = providerCode);
    try {
      final session = await context
          .read<ConnectorRepository>()
          .createAuthorizationSession(providerCode);
      final url = session.authorizationUrl;
      if (url == null || url.isEmpty) throw StateError('授权地址为空');
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw StateError('无法打开浏览器');
      if (!mounted) return;
      setState(_reload);
      _startPolling(session.sessionId);
    } on ApiException catch (error) {
      if (mounted) _showFailure(error.msg);
    } catch (_) {
      if (mounted) _showFailure('暂时无法开始授权，请稍后重试。');
    } finally {
      if (mounted) setState(() => _workingKey = null);
    }
  }

  Future<void> _confirmRevokePersonal(
    PersonalConnectionSummaryDto connector,
  ) async {
    final sessionId = connector.lastSessionId;
    if (sessionId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('撤销"${connector.name}"'),
        content: const Text('撤销后，NexusMind 将停止访问这项服务，直到你重新授权。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _workingKey = connector.connectorId.toString());
    try {
      await context.read<ConnectorRepository>().revokeAuthorization(sessionId);
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (error) {
      if (mounted) _showFailure(error.msg);
    } catch (_) {
      if (mounted) _showFailure('撤销失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _workingKey = null);
    }
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
          final household = data.connectors
              .where((c) => c.bindingScope != ConnectorBindingScope.personal)
              .toList();
          final connectedProviderCodes = data.connectors
              .map((c) => c.providerCode)
              .toSet();
          final personalProviderCodes = data.personal
              .map((p) => p.providerCode)
              .toSet();
          final availableProviders = data.providers
              .where(
                (p) =>
                    !connectedProviderCodes.contains(p.code) &&
                    !personalProviderCodes.contains(p.code),
              )
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
                  '管理你的个人连接与家庭服务的数据访问。凭据不会显示在这里。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: NexusLayout.sectionGap),
                Text('我的个人连接', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (data.personal.isEmpty)
                  const _PersonalEmpty()
                else
                  ...data.personal.map(
                    (connector) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PersonalConnectionCard(
                        connector: connector,
                        busy: _workingKey == connector.connectorId.toString(),
                        onConnect: () =>
                            _startPersonalAuthorization(connector.providerCode),
                        onRevoke: () => _confirmRevokePersonal(connector),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text('家庭连接', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (household.isEmpty)
                  const _ConnectorEmpty()
                else
                  ...household.map(
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
                                      ? () => _startPersonalAuthorization(
                                          provider.code,
                                        )
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
    required this.personal,
  });

  final List<ConnectorDto> connectors;
  final List<ConnectorProviderDto> providers;
  final List<PersonalConnectionSummaryDto> personal;
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
              const _ScopeTag(label: '家庭', icon: Icons.home_outlined),
              const SizedBox(width: 8),
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
}

class _PersonalConnectionCard extends StatelessWidget {
  const _PersonalConnectionCard({
    required this.connector,
    required this.busy,
    required this.onConnect,
    required this.onRevoke,
  });

  final PersonalConnectionSummaryDto connector;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final presentation = _personalPresentation(context, connector);
    final lastSync = connector.lastSyncAt;
    final lastHealth = connector.lastHealthAt;
    return NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(presentation.icon, color: presentation.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  connector.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const _ScopeTag(label: '个人', icon: Icons.person_outline),
              const SizedBox(width: 8),
              Text(
                presentation.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: presentation.color,
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
          if (presentation.waitingAuthorization) ...[
            Text(
              '请在浏览器中完成授权，完成后返回即可看到最新状态。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (connector.lastSessionId != null)
              TextButton(
                onPressed: busy ? null : onRevoke,
                child: const Text('撤销'),
              ),
          ] else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : presentation.primaryIsRevoke
                      ? onRevoke
                      : onConnect,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(presentation.primaryIcon),
                  label: Text(presentation.primaryLabel),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PersonalEmpty extends StatelessWidget {
  const _PersonalEmpty();

  @override
  Widget build(BuildContext context) =>
      const NexusSurface(child: Text('还没有个人连接。你可以在下方添加服务。'));
}

class _ScopeTag extends StatelessWidget {
  const _ScopeTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
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

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  final M = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$M-$d $h:$m';
}

/// 个人连接状态判定（§8.26 语义：pending 未过期 → 等待完成授权；
/// revoked → 重新授权入口）。
_PersonalPresentation _personalPresentation(
  BuildContext context,
  PersonalConnectionSummaryDto connector,
) {
  final scheme = Theme.of(context).colorScheme;
  final pending =
      connector.lastSessionStatus == AuthorizationSessionStatus.pending;
  final expired =
      connector.lastSessionExpiresAt != null &&
      !connector.lastSessionExpiresAt!.isAfter(DateTime.now());
  if (pending) {
    if (!expired) {
      return _PersonalPresentation(
        label: '等待完成授权',
        icon: Icons.hourglass_top_outlined,
        color: scheme.primary,
        waitingAuthorization: true,
        primaryLabel: '',
        primaryIcon: Icons.add_link_outlined,
      );
    }
    return _PersonalPresentation(
      label: '授权已过期',
      icon: Icons.timer_off_outlined,
      color: scheme.onSurfaceVariant,
      primaryLabel: '重新授权',
      primaryIcon: Icons.add_link_outlined,
    );
  }
  switch (connector.authStatus) {
    case PersonalAuthStatus.connected:
      return _PersonalPresentation(
        label: '已连接',
        icon: Icons.check_circle_outline,
        color: scheme.secondary,
        primaryLabel: '断开',
        primaryIcon: Icons.link_off_outlined,
        primaryIsRevoke: true,
      );
    case PersonalAuthStatus.authorizing:
      return _PersonalPresentation(
        label: '授权中',
        icon: Icons.key_outlined,
        color: scheme.primary,
        primaryLabel: '重新授权',
        primaryIcon: Icons.add_link_outlined,
      );
    case PersonalAuthStatus.failed:
      return _PersonalPresentation(
        label: '授权失败',
        icon: Icons.error_outline,
        color: scheme.error,
        primaryLabel: '重新授权',
        primaryIcon: Icons.add_link_outlined,
      );
    case PersonalAuthStatus.revoked:
    case PersonalAuthStatus.none:
      return _PersonalPresentation(
        label: connector.authStatus == PersonalAuthStatus.revoked
            ? '已撤销'
            : '未授权',
        icon: Icons.link_off_outlined,
        color: scheme.onSurfaceVariant,
        primaryLabel: connector.authStatus == PersonalAuthStatus.revoked
            ? '重新授权'
            : '连接',
        primaryIcon: Icons.add_link_outlined,
      );
  }
}

class _PersonalPresentation {
  const _PersonalPresentation({
    required this.label,
    required this.icon,
    required this.color,
    this.waitingAuthorization = false,
    this.primaryLabel = '',
    required this.primaryIcon,
    this.primaryIsRevoke = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool waitingAuthorization;
  final String primaryLabel;
  final IconData primaryIcon;

  /// 主按钮为「断开」时指向撤销而非重新授权。
  final bool primaryIsRevoke;
}
