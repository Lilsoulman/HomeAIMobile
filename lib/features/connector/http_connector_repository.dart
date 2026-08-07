// Connector HTTP 实现，严格按 8.14 / 8.14.1(B18) / 8.26(B19) 契约。

import '../../../core/api/api_client.dart';
import 'connector_repository.dart';

class HttpConnectorRepository implements ConnectorRepository {
  HttpConnectorRepository(this._api);

  // 服务端须配置 ConnectorOAuth:AllowedRedirectUris 包含该值，否则创建
  // 授权会话返回 422+10001。
  static const _redirectUri = 'https://app.example.com/callback';

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
  Future<AuthorizationSessionDto> createAuthorizationSession(
    String providerCode,
  ) async {
    final raw = await _api.request<dynamic>(
      method: 'POST',
      path: '/connector-providers/$providerCode/authorizations',
      body: {'redirectUri': _redirectUri},
      parseData: (value) => value,
    );
    if (raw is! Map) {
      throw StateError('创建授权会话失败：响应不是 JSON 对象');
    }
    return AuthorizationSessionDto.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<AuthorizationSessionDto> fetchAuthorizationSession(
    int sessionId,
  ) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/connector-authorizations/$sessionId',
      parseData: (value) => value,
    );
    if (raw is! Map) {
      throw StateError('查询授权会话失败：响应不是 JSON 对象');
    }
    return AuthorizationSessionDto.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<void> revokeAuthorization(int sessionId) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/connector-authorizations/$sessionId',
      parseData: (value) => value,
    );
  }

  @override
  Future<List<PersonalConnectionSummaryDto>> listMyPersonalConnections() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/connector-authorizations/my',
      parseData: (value) => value,
    );
    return _asList(raw)
        .whereType<Map>()
        .map(
          (item) => PersonalConnectionSummaryDto.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
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
