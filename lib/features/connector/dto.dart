// 后端契约：D:\HomeMind\core\docs\frontend-api-integration.md 8.14 / 8.14.1(B18) / 8.26(B19)
// 字段 PascalCase；不暴露 credentialRef、URL、token、vendor entity id。

enum ConnectorConnectionStatus {
  disconnected,
  connected,
  authorizing,
  discovering,
  failed,
}

extension ConnectorConnectionStatusApi on ConnectorConnectionStatus {
  String get apiValue => switch (this) {
    ConnectorConnectionStatus.disconnected => 'disconnected',
    ConnectorConnectionStatus.connected => 'connected',
    ConnectorConnectionStatus.authorizing => 'authorizing',
    ConnectorConnectionStatus.discovering => 'discovering',
    ConnectorConnectionStatus.failed => 'failed',
  };

  static ConnectorConnectionStatus fromApi(String? value) {
    switch (value) {
      case 'connected':
        return ConnectorConnectionStatus.connected;
      case 'authorizing':
        return ConnectorConnectionStatus.authorizing;
      case 'discovering':
        return ConnectorConnectionStatus.discovering;
      case 'failed':
        return ConnectorConnectionStatus.failed;
      case 'disconnected':
      default:
        return ConnectorConnectionStatus.disconnected;
    }
  }
}

/// 授权会话状态（B18，`ConnectorAuthorizationSessionStatus`）。
enum AuthorizationSessionStatus {
  pending,
  used,
  expired,
  revoked,
  completed,
  failed,
}

extension AuthorizationSessionStatusApi on AuthorizationSessionStatus {
  String get apiValue => switch (this) {
    AuthorizationSessionStatus.pending => 'pending',
    AuthorizationSessionStatus.used => 'used',
    AuthorizationSessionStatus.expired => 'expired',
    AuthorizationSessionStatus.revoked => 'revoked',
    AuthorizationSessionStatus.completed => 'completed',
    AuthorizationSessionStatus.failed => 'failed',
  };

  static AuthorizationSessionStatus fromApi(String? value) {
    switch (value) {
      case 'used':
        return AuthorizationSessionStatus.used;
      case 'expired':
        return AuthorizationSessionStatus.expired;
      case 'revoked':
        return AuthorizationSessionStatus.revoked;
      case 'completed':
        return AuthorizationSessionStatus.completed;
      case 'failed':
        return AuthorizationSessionStatus.failed;
      case 'pending':
      default:
        // 未知值回退 pending：轮询保持存活，受 ExpiresAt 上界约束。
        return AuthorizationSessionStatus.pending;
    }
  }
}

/// 个人连接授权生命周期（B19，`WorkspaceConnectorAuthStatus`）。
enum PersonalAuthStatus { none, authorizing, connected, revoked, failed }

extension PersonalAuthStatusApi on PersonalAuthStatus {
  String get apiValue => switch (this) {
    PersonalAuthStatus.none => 'none',
    PersonalAuthStatus.authorizing => 'authorizing',
    PersonalAuthStatus.connected => 'connected',
    PersonalAuthStatus.revoked => 'revoked',
    PersonalAuthStatus.failed => 'failed',
  };

  static PersonalAuthStatus fromApi(String? value) {
    switch (value) {
      case 'authorizing':
        return PersonalAuthStatus.authorizing;
      case 'connected':
        return PersonalAuthStatus.connected;
      case 'revoked':
        return PersonalAuthStatus.revoked;
      case 'failed':
        return PersonalAuthStatus.failed;
      case 'none':
      default:
        return PersonalAuthStatus.none;
    }
  }
}

/// 连接器作用域（B18，`BindingScope`）。
enum ConnectorBindingScope { household, personal }

extension ConnectorBindingScopeApi on ConnectorBindingScope {
  String get apiValue => switch (this) {
    ConnectorBindingScope.household => 'household',
    ConnectorBindingScope.personal => 'personal',
  };

  static ConnectorBindingScope fromApi(String? value) => value == 'personal'
      ? ConnectorBindingScope.personal
      : ConnectorBindingScope.household;
}

class ConnectorProviderDto {
  const ConnectorProviderDto({
    required this.id,
    required this.code,
    required this.name,
    required this.connectorType,
    required this.description,
  });

  final int id;
  final String code;
  final String name;
  final String connectorType;
  final String description;

  factory ConnectorProviderDto.fromJson(Map<String, dynamic> json) =>
      ConnectorProviderDto(
        id: (json['Id'] ?? json['id'] as num).toInt(),
        code: (json['Code'] ?? json['code'] ?? '').toString(),
        name: (json['Name'] ?? json['name'] ?? '').toString(),
        connectorType: (json['ConnectorType'] ?? json['connectorType'] ?? '')
            .toString(),
        description: (json['Description'] ?? json['description'] ?? '')
            .toString(),
      );
}

class ConnectorDto {
  const ConnectorDto({
    required this.id,
    required this.providerId,
    required this.providerCode,
    required this.providerName,
    required this.name,
    required this.status,
    this.lastSyncAt,
    this.lastHealthAt,
    required this.createdAt,
    required this.updatedAt,
    this.bindingScope = ConnectorBindingScope.household,
    this.isCurrentUserOwner = false,
  });

  final int id;
  final int providerId;
  final String providerCode;
  final String providerName;
  final String name;
  final ConnectorConnectionStatus status;
  final DateTime? lastSyncAt;
  final DateTime? lastHealthAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ConnectorBindingScope bindingScope;
  final bool isCurrentUserOwner;

  factory ConnectorDto.fromJson(Map<String, dynamic> json) => ConnectorDto(
    id: (json['Id'] ?? json['id'] as num).toInt(),
    providerId: (json['ProviderId'] ?? json['providerId'] as num).toInt(),
    providerCode: (json['ProviderCode'] ?? json['providerCode'] ?? '')
        .toString(),
    providerName: (json['ProviderName'] ?? json['providerName'] ?? '')
        .toString(),
    name: (json['Name'] ?? json['name'] ?? '').toString(),
    status: ConnectorConnectionStatusApi.fromApi(
      (json['Status'] ?? json['status'])?.toString(),
    ),
    lastSyncAt: _parseDate(json['LastSyncAt'] ?? json['lastSyncAt']),
    lastHealthAt: _parseDate(json['LastHealthAt'] ?? json['lastHealthAt']),
    createdAt:
        _parseDate(json['CreatedAt'] ?? json['createdAt']) ?? DateTime.now(),
    updatedAt:
        _parseDate(json['UpdatedAt'] ?? json['updatedAt']) ?? DateTime.now(),
    bindingScope: ConnectorBindingScopeApi.fromApi(
      (json['BindingScope'] ?? json['bindingScope'])?.toString(),
    ),
    isCurrentUserOwner:
        (json['IsCurrentUserOwner'] ?? json['isCurrentUserOwner'] ?? false) ==
        true,
  );
}

/// 授权会话脱敏视图（B18 §8.14.1）。AuthorizationUrl 仅创建响应返回；
/// RedirectUri 仅查询响应返回。不携带任何 code/token/credentialRef。
class AuthorizationSessionDto {
  const AuthorizationSessionDto({
    required this.sessionId,
    required this.providerCode,
    required this.providerName,
    required this.status,
    this.expiresAt,
    this.authorizationUrl,
    this.redirectUri,
  });

  final int sessionId;
  final String providerCode;
  final String providerName;
  final AuthorizationSessionStatus status;
  final DateTime? expiresAt;
  final String? authorizationUrl;
  final String? redirectUri;

  factory AuthorizationSessionDto.fromJson(Map<String, dynamic> json) =>
      AuthorizationSessionDto(
        sessionId: (json['SessionId'] ?? json['sessionId'] as num).toInt(),
        providerCode: (json['ProviderCode'] ?? json['providerCode'] ?? '')
            .toString(),
        providerName: (json['ProviderName'] ?? json['providerName'] ?? '')
            .toString(),
        status: AuthorizationSessionStatusApi.fromApi(
          (json['Status'] ?? json['status'])?.toString(),
        ),
        expiresAt: _parseDate(json['ExpiresAt'] ?? json['expiresAt']),
        authorizationUrl: (json['AuthorizationUrl'] ?? json['authorizationUrl'])
            ?.toString(),
        redirectUri: (json['RedirectUri'] ?? json['redirectUri'])?.toString(),
      );
}

/// 我的个人连接汇总（B19 §8.26）。Status 为运行健康，AuthStatus 为授权生命周期。
class PersonalConnectionSummaryDto {
  const PersonalConnectionSummaryDto({
    required this.connectorId,
    required this.providerId,
    required this.providerCode,
    required this.providerName,
    required this.name,
    required this.status,
    required this.authStatus,
    this.lastSyncAt,
    this.lastHealthAt,
    this.lastSessionId,
    this.lastSessionStatus,
    this.lastSessionExpiresAt,
  });

  final int connectorId;
  final int providerId;
  final String providerCode;
  final String providerName;
  final String name;
  final ConnectorConnectionStatus status;
  final PersonalAuthStatus authStatus;
  final DateTime? lastSyncAt;
  final DateTime? lastHealthAt;
  final int? lastSessionId;
  final AuthorizationSessionStatus? lastSessionStatus;
  final DateTime? lastSessionExpiresAt;

  factory PersonalConnectionSummaryDto.fromJson(
    Map<String, dynamic> json,
  ) => PersonalConnectionSummaryDto(
    connectorId: (json['ConnectorId'] ?? json['connectorId'] as num).toInt(),
    providerId: (json['ProviderId'] ?? json['providerId'] as num).toInt(),
    providerCode: (json['ProviderCode'] ?? json['providerCode'] ?? '')
        .toString(),
    providerName: (json['ProviderName'] ?? json['providerName'] ?? '')
        .toString(),
    name: (json['Name'] ?? json['name'] ?? '').toString(),
    status: ConnectorConnectionStatusApi.fromApi(
      (json['Status'] ?? json['status'])?.toString(),
    ),
    authStatus: PersonalAuthStatusApi.fromApi(
      (json['AuthStatus'] ?? json['authStatus'])?.toString(),
    ),
    lastSyncAt: _parseDate(json['LastSyncAt'] ?? json['lastSyncAt']),
    lastHealthAt: _parseDate(json['LastHealthAt'] ?? json['lastHealthAt']),
    lastSessionId: (json['LastSessionId'] ?? json['lastSessionId'] as num?)
        ?.toInt(),
    lastSessionStatus:
        json['LastSessionStatus'] == null && json['lastSessionStatus'] == null
        ? null
        : AuthorizationSessionStatusApi.fromApi(
            (json['LastSessionStatus'] ?? json['lastSessionStatus'])
                ?.toString(),
          ),
    lastSessionExpiresAt: _parseDate(
      json['LastSessionExpiresAt'] ?? json['lastSessionExpiresAt'],
    ),
  );
}

DateTime? _parseDate(dynamic raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
