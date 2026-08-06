// P2 家庭协同数据层：家庭成员 / 知识库 / 决策历史 DTO。
// 字段依据服务端 FamilyViewModels.cs（B11/B14 已发布契约），PascalCase 键。

class FamilyMemberDto {
  const FamilyMemberDto({
    required this.id,
    required this.name,
    required this.relation,
    this.birthday,
    required this.isElderly,
    required this.isChild,
    required this.isPrimary,
    required this.memberStatus,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyMemberDto.fromJson(Map<String, dynamic> json) =>
      FamilyMemberDto(
        id: (json['Id'] as num).toInt(),
        name: (json['Name'] ?? '').toString(),
        relation: (json['Relation'] ?? '').toString(),
        birthday: json['Birthday'] == null
            ? null
            : DateTime.parse(json['Birthday'] as String),
        isElderly: (json['IsElderly'] as bool?) ?? false,
        isChild: (json['IsChild'] as bool?) ?? false,
        isPrimary: (json['IsPrimary'] as bool?) ?? false,
        memberStatus: (json['MemberStatus'] ?? '').toString(),
        preferences: json['Preferences'] as String?,
        createdAt: DateTime.parse(json['CreatedAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String name;
  final String relation;
  final DateTime? birthday;
  final bool isElderly;
  final bool isChild;
  final bool isPrimary;
  final String memberStatus;
  final String? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class FamilyKnowledgeDto {
  const FamilyKnowledgeDto({
    required this.id,
    required this.category,
    required this.key,
    required this.value,
    this.notes,
    required this.sourceType,
    this.sourceMemberId,
    required this.confidenceScore,
    required this.conflictResolutionStrategy,
    this.resolutionSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyKnowledgeDto.fromJson(Map<String, dynamic> json) =>
      FamilyKnowledgeDto(
        id: (json['Id'] as num).toInt(),
        category: (json['Category'] ?? '').toString(),
        key: (json['Key'] ?? '').toString(),
        value: (json['Value'] ?? '').toString(),
        notes: json['Notes'] as String?,
        sourceType: (json['SourceType'] ?? '').toString(),
        sourceMemberId: json['SourceMemberId'] == null
            ? null
            : (json['SourceMemberId'] as num).toInt(),
        confidenceScore: ((json['ConfidenceScore'] as num?) ?? 0).toDouble(),
        conflictResolutionStrategy: (json['ConflictResolutionStrategy'] ?? '')
            .toString(),
        resolutionSummary: json['ResolutionSummary'] as String?,
        createdAt: DateTime.parse(json['CreatedAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String category;
  final String key;
  final String value;
  final String? notes;
  final String sourceType;
  final int? sourceMemberId;
  final double confidenceScore;
  final String conflictResolutionStrategy;
  final String? resolutionSummary;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class FamilyKnowledgeResolutionDto {
  const FamilyKnowledgeResolutionDto({
    required this.knowledgeId,
    required this.conflictKey,
    required this.strategy,
    required this.resolutionSummary,
    required this.conflictingIds,
  });

  factory FamilyKnowledgeResolutionDto.fromJson(Map<String, dynamic> json) =>
      FamilyKnowledgeResolutionDto(
        knowledgeId: (json['KnowledgeId'] as num).toInt(),
        conflictKey: (json['ConflictKey'] ?? '').toString(),
        strategy: (json['Strategy'] ?? '').toString(),
        resolutionSummary: (json['ResolutionSummary'] ?? '').toString(),
        conflictingIds: (json['ConflictingIds'] as List? ?? const [])
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(growable: false),
      );

  final int knowledgeId;
  final String conflictKey;
  final String strategy;
  final String resolutionSummary;
  final List<int> conflictingIds;
}

/// 知识写入响应：`{ Knowledge, Resolution? }`。
class FamilyKnowledgeWriteResultDto {
  const FamilyKnowledgeWriteResultDto({
    required this.knowledge,
    this.resolution,
  });

  factory FamilyKnowledgeWriteResultDto.fromJson(Map<String, dynamic> json) =>
      FamilyKnowledgeWriteResultDto(
        knowledge: FamilyKnowledgeDto.fromJson(
          (json['Knowledge'] as Map).cast<String, dynamic>(),
        ),
        resolution: json['Resolution'] == null
            ? null
            : FamilyKnowledgeResolutionDto.fromJson(
                (json['Resolution'] as Map).cast<String, dynamic>(),
              ),
      );

  final FamilyKnowledgeDto knowledge;
  final FamilyKnowledgeResolutionDto? resolution;
}

class FamilyDecisionDto {
  const FamilyDecisionDto({
    required this.id,
    required this.scenario,
    required this.decisionMade,
    this.rationale,
    this.alternatives,
    this.madeByMemberId,
    required this.decidedAt,
    required this.updatedAt,
  });

  factory FamilyDecisionDto.fromJson(Map<String, dynamic> json) =>
      FamilyDecisionDto(
        id: (json['Id'] as num).toInt(),
        scenario: (json['Scenario'] ?? '').toString(),
        decisionMade: (json['DecisionMade'] ?? '').toString(),
        rationale: json['Rationale'] as String?,
        alternatives: json['Alternatives'] as String?,
        madeByMemberId: json['MadeByMemberId'] == null
            ? null
            : (json['MadeByMemberId'] as num).toInt(),
        decidedAt: DateTime.parse(json['DecidedAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String scenario;
  final String decisionMade;
  final String? rationale;
  final String? alternatives;
  final int? madeByMemberId;
  final DateTime decidedAt;
  final DateTime updatedAt;
}

/// 决策历史游标分页：`{ Items, Cursor }`。
class FamilyDecisionPageDto {
  const FamilyDecisionPageDto({required this.items, this.cursor});

  factory FamilyDecisionPageDto.fromJson(Map<String, dynamic> json) =>
      FamilyDecisionPageDto(
        items: (json['Items'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (entry) =>
                  FamilyDecisionDto.fromJson(entry.cast<String, dynamic>()),
            )
            .toList(growable: false),
        cursor: json['Cursor'] as String?,
      );

  final List<FamilyDecisionDto> items;
  final String? cursor;
}
