import 'connector_repository.dart';
import 'dto.dart';

class LocalConnectorRepository implements ConnectorRepository {
  LocalConnectorRepository() : _now = DateTime.now() {
    _connectors = [
      ConnectorDto(
        id: 'home-assistant',
        providerKey: 'home-assistant',
        name: 'Home Assistant',
        description: '家庭空间与场景',
        status: ConnectorConnectionStatus.online,
        statusText: '连接正常',
        permissionSummary: '已授权读取家庭状态和执行已确认场景',
        lastUpdatedAt: _now,
      ),
      const ConnectorDto(
        id: 'shared-calendar',
        providerKey: 'shared-calendar',
        name: '家庭日历',
        description: '共享日程与提醒',
        status: ConnectorConnectionStatus.authorizing,
        statusText: '等待授权完成',
        permissionSummary: '将请求读取共享日程的权限',
      ),
      const ConnectorDto(
        id: 'weather',
        providerKey: 'weather',
        name: '天气服务',
        description: '天气提醒与出行建议',
        status: ConnectorConnectionStatus.disconnected,
        statusText: '尚未连接',
        permissionSummary: '连接后可读取天气预报',
      ),
      const ConnectorDto(
        id: 'home-devices',
        providerKey: 'home-devices',
        name: '家庭设备',
        description: '设备发现与状态同步',
        status: ConnectorConnectionStatus.discovering,
        statusText: '正在发现可用设备',
        permissionSummary: '仅处理已授权的家庭设备',
      ),
      const ConnectorDto(
        id: 'health-calendar',
        providerKey: 'health-calendar',
        name: '健康日历',
        description: '健康提醒与计划',
        status: ConnectorConnectionStatus.failed,
        statusText: '上次连接未完成',
        permissionSummary: '请重试以恢复已授权的服务',
      ),
    ];
  }

  final DateTime _now;
  late final List<ConnectorDto> _connectors;

  static const _providers = [
    ConnectorProviderDto(
      key: 'home-assistant',
      name: 'Home Assistant',
      description: '连接家庭空间、设备摘要与场景',
    ),
    ConnectorProviderDto(
      key: 'shared-calendar',
      name: '家庭日历',
      description: '连接共享日程与提醒',
    ),
    ConnectorProviderDto(
      key: 'weather',
      name: '天气服务',
      description: '连接天气预报和出行提醒',
    ),
    ConnectorProviderDto(
      key: 'home-devices',
      name: '家庭设备',
      description: '发现已授权的家庭设备',
    ),
    ConnectorProviderDto(
      key: 'health-calendar',
      name: '健康日历',
      description: '连接健康提醒与计划',
    ),
    ConnectorProviderDto(
      key: 'family-notes',
      name: '家庭笔记',
      description: '连接共享的家庭事项',
    ),
  ];

  @override
  Future<List<ConnectorProviderDto>> listProviders() async =>
      List.unmodifiable(_providers);

  @override
  Future<List<ConnectorDto>> listConnectors() async =>
      List.unmodifiable(_connectors);

  @override
  Future<ConnectorDto> beginAuthorization(String providerKey) async {
    final provider = _providers.firstWhere(
      (item) => item.key == providerKey,
      orElse: () => throw ArgumentError.value(providerKey, 'providerKey'),
    );
    final index = _connectors.indexWhere(
      (item) => item.providerKey == providerKey,
    );
    final connector = index < 0
        ? ConnectorDto(
            id: provider.key,
            providerKey: provider.key,
            name: provider.name,
            description: provider.description,
            status: ConnectorConnectionStatus.authorizing,
            statusText: '等待授权完成',
            permissionSummary: '将请求必要的服务访问权限',
          )
        : _connectors[index].copyWith(
            status: ConnectorConnectionStatus.authorizing,
            statusText: '等待授权完成',
            permissionSummary: '将请求必要的服务访问权限',
          );
    if (index < 0) {
      _connectors.add(connector);
    } else {
      _connectors[index] = connector;
    }
    return connector;
  }

  @override
  Future<ConnectorDto> discover(String connectorId) => _update(
    connectorId,
    status: ConnectorConnectionStatus.discovering,
    statusText: '正在发现可用设备',
    permissionSummary: '仅处理已授权的家庭设备',
  );

  @override
  Future<ConnectorDto> disconnect(String connectorId) => _update(
    connectorId,
    status: ConnectorConnectionStatus.disconnected,
    statusText: '已断开连接',
    permissionSummary: '重新连接后才会恢复服务访问',
  );

  @override
  Future<ConnectorDto> retry(String connectorId) => _update(
    connectorId,
    status: ConnectorConnectionStatus.online,
    statusText: '连接正常',
    permissionSummary: '已恢复已授权的服务访问',
  );

  Future<ConnectorDto> _update(
    String connectorId, {
    required ConnectorConnectionStatus status,
    required String statusText,
    required String permissionSummary,
  }) async {
    final index = _connectors.indexWhere((item) => item.id == connectorId);
    if (index < 0) throw ArgumentError.value(connectorId, 'connectorId');
    final connector = _connectors[index].copyWith(
      status: status,
      statusText: statusText,
      permissionSummary: permissionSummary,
      lastUpdatedAt: DateTime.now(),
    );
    _connectors[index] = connector;
    return connector;
  }
}
