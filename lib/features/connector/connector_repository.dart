import 'dto.dart';

export 'dto.dart';

abstract class ConnectorRepository {
  Future<List<ConnectorProviderDto>> listProviders();

  Future<List<ConnectorDto>> listConnectors();

  /// 家庭连接占位创建（8.14 POST /connectors，无凭据）；个人授权请用
  /// [createAuthorizationSession]（B18）。
  Future<ConnectorDto> beginAuthorization(String providerKey);

  Future<ConnectorDto> retry(String connectorId);

  Future<ConnectorDto> discover(String connectorId);

  Future<ConnectorDto> disconnect(String connectorId);

  /// 创建个人 OAuth 授权会话（B18）。响应含 AuthorizationUrl（仅创建响应返回）。
  Future<AuthorizationSessionDto> createAuthorizationSession(
    String providerCode,
  );

  /// 查询本人授权会话脱敏状态（B18 GET）。
  Future<AuthorizationSessionDto> fetchAuthorizationSession(int sessionId);

  /// 撤销本人授权会话（B18 DELETE，幂等，200）。
  Future<void> revokeAuthorization(int sessionId);

  /// 我的个人连接汇总（B19，按 Name 排序）。
  Future<List<PersonalConnectionSummaryDto>> listMyPersonalConnections();
}
