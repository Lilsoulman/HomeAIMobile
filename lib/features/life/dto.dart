// P5c 个人生活专家 DTO 契约说明（与后端 §8.21/§8.22 对齐）：
// - 翻牌（Intent: recommend）为只读 L1，不产生确认动作；响应含
//   Status / ResultSummary / Recommendations（FavoriteId、Name、Reason、Tags）。
// - 行程（Intent: plan）响应 Status 为 pending_actions，Actions 为
//   calendar_create_event（RiskLevel 恒为 L1）；Data.Id 为 runId，
//   确认接口 `runs/{runId}/actions/{actionId}/confirm` 依赖它。
// - 两个端点均同步返回结果；不渲染提示或思考链，不展示 FavoriteId。

class LifeRecommendationDto {
  const LifeRecommendationDto({
    required this.favoriteId,
    required this.name,
    this.reason,
    this.tags = const [],
  });

  factory LifeRecommendationDto.fromJson(Map<String, dynamic> json) =>
      LifeRecommendationDto(
        favoriteId: _intOrZero(json['FavoriteId'] ?? json['favoriteId']),
        name: (json['Name'] ?? json['name'] ?? '').toString(),
        reason: _stringOrNull(json['Reason'] ?? json['reason']),
        tags: _stringList(json['Tags'] ?? json['tags']),
      );

  final int favoriteId;
  final String name;
  final String? reason;
  final List<String> tags;
}

class LifeRecommendResultDto {
  const LifeRecommendResultDto({
    required this.status,
    this.resultSummary,
    this.recommendations = const [],
  });

  factory LifeRecommendResultDto.fromJson(Map<String, dynamic> json) =>
      LifeRecommendResultDto(
        status: (json['Status'] ?? json['status'] ?? '').toString(),
        resultSummary: _stringOrNull(
          json['ResultSummary'] ?? json['resultSummary'],
        ),
        recommendations: _dtoList(
          json['Recommendations'] ?? json['recommendations'],
          LifeRecommendationDto.fromJson,
        ),
      );

  final String status;
  final String? resultSummary;
  final List<LifeRecommendationDto> recommendations;
}

class LifePlanActionDto {
  const LifePlanActionDto({
    required this.id,
    this.actionType,
    this.status,
    this.title,
    this.description,
    this.riskLevel,
  });

  factory LifePlanActionDto.fromJson(Map<String, dynamic> json) =>
      LifePlanActionDto(
        id: _intOrZero(json['Id'] ?? json['id']),
        actionType: _stringOrNull(json['ActionType'] ?? json['actionType']),
        status: _stringOrNull(json['Status'] ?? json['status']),
        title: _stringOrNull(json['Title'] ?? json['title']),
        description: _stringOrNull(json['Description'] ?? json['description']),
        riskLevel: _stringOrNull(json['RiskLevel'] ?? json['riskLevel']),
      );

  final int id;
  final String? actionType;
  final String? status;
  final String? title;
  final String? description;
  final String? riskLevel;
}

class LifePlanResultDto {
  const LifePlanResultDto({
    required this.runId,
    required this.status,
    this.resultSummary,
    this.actions = const [],
  });

  factory LifePlanResultDto.fromJson(Map<String, dynamic> json) =>
      LifePlanResultDto(
        runId: _intOrZero(json['Id'] ?? json['id']),
        status: (json['Status'] ?? json['status'] ?? '').toString(),
        resultSummary: _stringOrNull(
          json['ResultSummary'] ?? json['resultSummary'],
        ),
        actions: _dtoList(
          json['Actions'] ?? json['actions'],
          LifePlanActionDto.fromJson,
        ),
      );

  final int runId;
  final String status;
  final String? resultSummary;
  final List<LifePlanActionDto> actions;
}

List<T> _dtoList<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => fromJson(entry.cast<String, dynamic>()))
      .toList(growable: false);
}

int _intOrZero(Object? value) => _intOrNull(value) ?? 0;

int? _intOrNull(Object? value) => switch (value) {
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}
