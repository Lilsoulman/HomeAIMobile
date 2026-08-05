// 后端契约：D:\HomeMind\core\docs\frontend-api-integration.md 8.14
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
  );
}

DateTime? _parseDate(dynamic raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
