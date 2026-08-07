// 专家会话（B20）DTO 契约说明（与后端 §8.27 对齐）：
// - 会话为个人资源，路由无 homes 前缀；跨用户/跨租户/已软删一律 404。
// - ConversationView：Id/Title/ExpertId/ExpertVersionId/WorkspaceConnectorId/
//   CreatedAt/UpdatedAt/RowVersion；更新（PUT）需携带 RowVersion，冲突 409+40903。
// - Message：Id/Role/Content/RunId/CreatedAt；Role 枚举 user|assistant。
// - POST /conversations/{id}/messages 响应 { RunId, Status, MessageId }；
//   客户端不缓存会话上下文，终态后由服务端自动追加 assistant 摘要消息。
// - 兼容 PascalCase 与 camelCase 两种 key（与既有 DTO 一致）。

enum ConversationMessageRole {
  user,
  assistant;

  String get apiValue => name;

  static ConversationMessageRole fromApiValue(Object? value) =>
      value?.toString() == assistant.apiValue ? assistant : user;
}

class ConversationDto {
  const ConversationDto({
    required this.id,
    required this.title,
    this.expertId,
    this.expertVersionId,
    this.workspaceConnectorId,
    required this.createdAt,
    required this.updatedAt,
    required this.rowVersion,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      ConversationDto(
        id: _intOrZero(json['Id'] ?? json['id']),
        title: (json['Title'] ?? json['title'] ?? '').toString(),
        expertId: _intOrNull(json['ExpertId'] ?? json['expertId']),
        expertVersionId: _intOrNull(
          json['ExpertVersionId'] ?? json['expertVersionId'],
        ),
        workspaceConnectorId: _intOrNull(
          json['WorkspaceConnectorId'] ?? json['workspaceConnectorId'],
        ),
        createdAt: _date(json['CreatedAt'] ?? json['createdAt']),
        updatedAt: _date(json['UpdatedAt'] ?? json['updatedAt']),
        rowVersion: _intOrZero(json['RowVersion'] ?? json['rowVersion']),
      );

  final int id;
  final String title;
  final int? expertId;
  final int? expertVersionId;
  final int? workspaceConnectorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int rowVersion;
}

class ConversationMessageDto {
  const ConversationMessageDto({
    required this.id,
    required this.role,
    required this.content,
    this.runId,
    required this.createdAt,
  });

  factory ConversationMessageDto.fromJson(Map<String, dynamic> json) =>
      ConversationMessageDto(
        id: _intOrZero(json['Id'] ?? json['id']),
        role: ConversationMessageRole.fromApiValue(
          json['Role'] ?? json['role'],
        ),
        content: (json['Content'] ?? json['content'] ?? '').toString(),
        runId: _intOrNull(json['RunId'] ?? json['runId']),
        createdAt: _date(json['CreatedAt'] ?? json['createdAt']),
      );

  final int id;
  final ConversationMessageRole role;
  final String content;
  final int? runId;
  final DateTime createdAt;
}

/// 消息发送结果：`{ RunId, Status, MessageId }`。
class SendMessageResultDto {
  const SendMessageResultDto({
    required this.runId,
    required this.status,
    required this.messageId,
  });

  factory SendMessageResultDto.fromJson(Map<String, dynamic> json) =>
      SendMessageResultDto(
        runId: _intOrZero(json['RunId'] ?? json['runId']),
        status: (json['Status'] ?? json['status'] ?? '').toString(),
        messageId: _intOrZero(json['MessageId'] ?? json['messageId']),
      );

  final int runId;
  final String status;
  final int messageId;
}

/// 会话游标分页：`{ Items, Cursor }`。
class ConversationPageDto {
  const ConversationPageDto({required this.items, this.cursor});

  factory ConversationPageDto.fromJson(Map<String, dynamic> json) =>
      ConversationPageDto(
        items: (json['Items'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => ConversationDto.fromJson(item.cast<String, dynamic>()),
            )
            .toList(growable: false),
        cursor: json['Cursor'] as String?,
      );

  final List<ConversationDto> items;
  final String? cursor;
}

/// 消息游标分页：`{ Items, Cursor }`。
class MessagePageDto {
  const MessagePageDto({required this.items, this.cursor});

  factory MessagePageDto.fromJson(Map<String, dynamic> json) => MessagePageDto(
    items: (json['Items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ConversationMessageDto.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false),
    cursor: json['Cursor'] as String?,
  );

  final List<ConversationMessageDto> items;
  final String? cursor;
}

int _intOrZero(Object? value) => _intOrNull(value) ?? 0;

int? _intOrNull(Object? value) => switch (value) {
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

DateTime _date(Object? value) => _nullableDate(value) ?? DateTime.now().toUtc();

DateTime? _nullableDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();
