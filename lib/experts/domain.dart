enum ExpertSourceType {
  expert,
  group;

  String get apiValue => name;

  static ExpertSourceType fromApiValue(Object? value) =>
      value?.toString() == group.apiValue ? group : expert;
}

/// 专家来源（B21 起）：`basic`（平台基础）/ `mine`（本人自建）。
enum ExpertSource {
  basic,
  mine;

  String get apiValue => name;

  static ExpertSource fromApiValue(Object? value) =>
      value?.toString() == mine.apiValue ? mine : basic;
}

class Expert {
  const Expert({
    required this.id,
    required this.sourceType,
    required this.name,
    required this.category,
    required this.description,
    required this.estimatedCredits,
    this.source = ExpertSource.basic,
  });

  final String id;
  final ExpertSourceType sourceType;
  final String name;
  final String category;
  final String description;
  final int estimatedCredits;
  final ExpertSource source;
}

/// 专家详情（B21 自建专家表单编辑用）：目录字段 + persona/methodology/
/// promptTemplate/toolPolicy 等编辑字段与乐观锁版本。
class ExpertDetail {
  const ExpertDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.estimatedCredits,
    this.source = ExpertSource.basic,
    this.persona,
    this.methodology,
    this.promptTemplate,
    this.toolPolicy,
    this.outputSchema,
    this.version,
    this.versionId,
    this.rowVersion,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final int estimatedCredits;
  final ExpertSource source;
  final String? persona;
  final String? methodology;
  final String? promptTemplate;
  final String? toolPolicy;
  final String? outputSchema;
  final int? version;
  final int? versionId;

  /// 更新所需的乐观锁版本；详情接口未返回时为 null（冲突时以 409 提示刷新）。
  final int? rowVersion;

  /// 自建专家均为单专家类型（sourceType=expert），非 group。
  Expert toExpert() => Expert(
    id: id,
    sourceType: ExpertSourceType.expert,
    name: name,
    category: category,
    description: description,
    estimatedCredits: estimatedCredits,
    source: source,
  );
}
