// P2 家庭协同数据层：管家动态 / 确认中心 DTO。
// 字段依据服务端 StewardViewModels.cs（B12/B14 已发布契约），PascalCase 键。

class StewardActivityDto {
  const StewardActivityDto({
    required this.id,
    this.runId,
    required this.category,
    required this.title,
    this.description,
    required this.riskLevel,
    required this.status,
    this.resultSummary,
    required this.undoable,
    this.undoneAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StewardActivityDto.fromJson(Map<String, dynamic> json) =>
      StewardActivityDto(
        id: (json['Id'] as num).toInt(),
        runId: json['RunId'] == null ? null : (json['RunId'] as num).toInt(),
        category: (json['Category'] ?? '').toString(),
        title: (json['Title'] ?? '').toString(),
        description: json['Description'] as String?,
        riskLevel: (json['RiskLevel'] ?? '').toString(),
        status: (json['Status'] ?? '').toString(),
        resultSummary: json['ResultSummary'] as String?,
        undoable: (json['Undoable'] as bool?) ?? false,
        undoneAt: json['UndoneAt'] == null
            ? null
            : DateTime.parse(json['UndoneAt'] as String),
        createdAt: DateTime.parse(json['CreatedAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final int? runId;
  final String category;
  final String title;
  final String? description;
  final String riskLevel;
  final String status;
  final String? resultSummary;
  final bool undoable;
  final DateTime? undoneAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// 管家动态游标分页：`{ Items, Cursor }`。
class StewardActivityPageDto {
  const StewardActivityPageDto({required this.items, this.cursor});

  factory StewardActivityPageDto.fromJson(Map<String, dynamic> json) =>
      StewardActivityPageDto(
        items: (json['Items'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (entry) =>
                  StewardActivityDto.fromJson(entry.cast<String, dynamic>()),
            )
            .toList(growable: false),
        cursor: json['Cursor'] as String?,
      );

  final List<StewardActivityDto> items;
  final String? cursor;
}

class ConfirmationItemDto {
  const ConfirmationItemDto({
    required this.id,
    this.activityId,
    required this.riskLevel,
    required this.title,
    this.description,
    this.impactSummary,
    this.suggestedAction,
    required this.status,
    this.expiresAt,
    this.confirmedAt,
    this.deniedAt,
    this.expiredAt,
    required this.updatedAt,
  });

  factory ConfirmationItemDto.fromJson(Map<String, dynamic> json) =>
      ConfirmationItemDto(
        id: (json['Id'] as num).toInt(),
        activityId: json['ActivityId'] == null
            ? null
            : (json['ActivityId'] as num).toInt(),
        riskLevel: (json['RiskLevel'] ?? '').toString(),
        title: (json['Title'] ?? '').toString(),
        description: json['Description'] as String?,
        impactSummary: json['ImpactSummary'] as String?,
        suggestedAction: json['SuggestedAction'] as String?,
        status: (json['Status'] ?? '').toString(),
        expiresAt: _dateOrNull(json, 'ExpiresAt'),
        confirmedAt: _dateOrNull(json, 'ConfirmedAt'),
        deniedAt: _dateOrNull(json, 'DeniedAt'),
        expiredAt: _dateOrNull(json, 'ExpiredAt'),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final int? activityId;
  final String riskLevel;
  final String title;
  final String? description;
  final String? impactSummary;
  final String? suggestedAction;
  final String status;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;
  final DateTime? deniedAt;
  final DateTime? expiredAt;
  final DateTime updatedAt;
}

/// L1 批量确认结果：`{ ConfirmedCount, Items }`。
class ConfirmationBatchResultDto {
  const ConfirmationBatchResultDto({
    required this.confirmedCount,
    required this.items,
  });

  factory ConfirmationBatchResultDto.fromJson(Map<String, dynamic> json) =>
      ConfirmationBatchResultDto(
        confirmedCount: ((json['ConfirmedCount'] as num?) ?? 0).toInt(),
        items: (json['Items'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (entry) =>
                  ConfirmationItemDto.fromJson(entry.cast<String, dynamic>()),
            )
            .toList(growable: false),
      );

  final int confirmedCount;
  final List<ConfirmationItemDto> items;
}

DateTime? _dateOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? null : DateTime.parse(value as String);
}
