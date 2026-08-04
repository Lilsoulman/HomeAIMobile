// 执行模式 10：Auth 端点 DTO（PascalCase，与后端一致，避免双向转换）。

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.tenantId,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['AccessToken'] as String,
    refreshToken: json['RefreshToken'] as String,
    userId: (json['UserId'] as num).toInt(),
    tenantId: (json['TenantId'] as num).toInt(),
  );

  final String accessToken;
  final String refreshToken;
  final int userId;
  final int tenantId;
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.status,
    required this.timezone,
    required this.locale,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: (json['id'] as num).toInt(),
    displayName: (json['DisplayName'] ?? '').toString(),
    avatarUrl: json['AvatarUrl'] as String?,
    status: (json['status'] ?? '').toString(),
    timezone: (json['timezone'] ?? '').toString(),
    locale: (json['locale'] ?? '').toString(),
    createdAt: DateTime.parse(json['CreatedAt'] as String),
  );

  final int id;
  final String displayName;
  final String? avatarUrl;
  final String status;
  final String timezone;
  final String locale;
  final DateTime createdAt;
}
