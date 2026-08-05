// Connector HTTP 实现，严格按 8.14 契约。

import '../../../core/api/api_client.dart';
import 'connector_repository.dart';

class HttpConnectorRepository implements ConnectorRepository {
  HttpConnectorRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ConnectorProviderDto>> listProviders() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/connector-providers',
      parseData: (value) => value,
    );
    return _asList(raw)
        .whereType<Map>()
        .map(
          (item) => ConnectorProviderDto.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ConnectorDto>> listConnectors() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/connectors',
      parseData: (value) => value,
    );
    return _asList(raw)
        .whereType<Map>()
        .map((item) => ConnectorDto.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Future<ConnectorDto> beginAuthorization(String providerKey) async {
    final providers = await listProviders();
    final provider = providers.firstWhere(
      (item) => item.code == providerKey,
      orElse: () => throw ArgumentError.value(
        providerKey,
        'providerKey',
        '未找到该 Connector Provider',
      ),
    );
    final raw = await _api.request<dynamic>(
      method: 'POST',
      path: '/connectors',
      body: {'providerId': provider.id, 'name': provider.name},
      parseData: (value) => value,
    );
    if (raw is! Map) {
      throw StateError('创建 Connector 失败：响应不是 JSON 对象');
    }
    return ConnectorDto.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<ConnectorDto> retry(String connectorId) async {
    final raw = await _api.request<dynamic>(
      method: 'POST',
      path: '/connectors/$connectorId/test',
      parseData: (value) => value,
    );
    if (raw is! Map) {
      throw StateError('测试 Connector 失败：响应不是 JSON 对象');
    }
    return ConnectorDto.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<ConnectorDto> discover(String connectorId) async {
    final raw = await _api.request<dynamic>(
      method: 'POST',
      path: '/connectors/$connectorId/discovery',
      parseData: (value) => value,
    );
    if (raw is! Map) {
      throw StateError('发现 Connector 失败：响应不是 JSON 对象');
    }
    return ConnectorDto.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<ConnectorDto> disconnect(String connectorId) async {
    // 8.14 暂未提供"断开"端点；按现状对最近一次获取的本地副本置为 disconnected。
    final connectors = await listConnectors();
    final target = connectors.firstWhere(
      (item) => item.id.toString() == connectorId,
      orElse: () => throw ArgumentError.value(
        connectorId,
        'connectorId',
        '未找到该 Connector',
      ),
    );
    return ConnectorDto(
      id: target.id,
      providerId: target.providerId,
      providerCode: target.providerCode,
      providerName: target.providerName,
      name: target.name,
      status: ConnectorConnectionStatus.disconnected,
      lastSyncAt: target.lastSyncAt,
      lastHealthAt: target.lastHealthAt,
      createdAt: target.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const [];
  }
}
