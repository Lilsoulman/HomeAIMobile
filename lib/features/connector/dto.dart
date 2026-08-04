enum ConnectorConnectionStatus {
  online,
  authorizing,
  discovering,
  disconnected,
  failed,
}

class ConnectorProviderDto {
  const ConnectorProviderDto({
    required this.key,
    required this.name,
    required this.description,
  });

  final String key;
  final String name;
  final String description;
}

class ConnectorDto {
  const ConnectorDto({
    required this.id,
    required this.providerKey,
    required this.name,
    required this.description,
    required this.status,
    required this.statusText,
    required this.permissionSummary,
    this.lastUpdatedAt,
  });

  final String id;
  final String providerKey;
  final String name;
  final String description;
  final ConnectorConnectionStatus status;
  final String statusText;
  final String permissionSummary;
  final DateTime? lastUpdatedAt;

  ConnectorDto copyWith({
    ConnectorConnectionStatus? status,
    String? statusText,
    String? permissionSummary,
    DateTime? lastUpdatedAt,
  }) => ConnectorDto(
    id: id,
    providerKey: providerKey,
    name: name,
    description: description,
    status: status ?? this.status,
    statusText: statusText ?? this.statusText,
    permissionSummary: permissionSummary ?? this.permissionSummary,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
}
