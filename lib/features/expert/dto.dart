// Expert Run DTO 契约说明（与产品总纲、后端 §8 对齐）：
// - AgentRun 状态枚举收敛为七态：draft | queued | planning | running |
//   completed | failed | cancelled。
// - 兼容视图：draft 与 queued UI 文本"准备中"；planning 与 running 合并为
//   "处理中"。
// - ActionType 枚举：plan | todos | calendar_events | smart_home_device。
//   front-end 命名为 ExpertRunActionType.smartHomeDevices。
// - RunDto 携带 mode: single|team 与 inputJson（仅用于回显输入摘要，禁止展示
//   prompt / 模型思考链 / 凭据 / 供应商原始字段）。
// - ActionDto 携带 deviceId / deviceName / capability / targetValue / spaceName
//   / actionTitle / actionDescription，兼容 PascalCase 与 camelCase 两种 key。
//
// F6-pre 调整：扩展七态枚举、ActionType、RunDto 与 ActionDto；保留既有 DTO
// 字段，不破坏调用方。

enum ExpertRunSourceType {
  expert,
  group;

  String get apiValue => name;

  static ExpertRunSourceType fromApiValue(Object? value) =>
      value?.toString() == group.apiValue ? group : expert;
}

enum ExpertRunStatus {
  draft,
  queued,
  planning,
  running,
  completed,
  failed,
  cancelled;

  bool get isTerminal =>
      this == completed || this == failed || this == cancelled;

  String get label => switch (this) {
    draft || queued => '准备中',
    planning || running => '处理中',
    completed => '已完成',
    failed => '运行失败',
    cancelled => '已取消',
  };

  static ExpertRunStatus fromApiValue(Object? value) =>
      switch (value?.toString()) {
        'draft' => draft,
        'queued' => queued,
        'planning' => planning,
        'running' => running,
        'completed' => completed,
        'failed' => failed,
        'cancelled' => cancelled,
        _ => queued,
      };
}

enum ExpertRunActionType {
  plan,
  todos,
  calendarEvents,
  smartHomeDevices;

  String get apiValue => switch (this) {
    plan => 'plan',
    todos => 'todos',
    calendarEvents => 'calendar_events',
    smartHomeDevices => 'smart_home_device',
  };

  String get label => switch (this) {
    plan => '加入计划',
    todos => '创建任务',
    calendarEvents => '创建日程',
    smartHomeDevices => '设备行动',
  };

  static ExpertRunActionType fromApiValue(Object? value) =>
      switch (value?.toString()) {
        'plan' => plan,
        'todos' => todos,
        'calendar_events' || 'calendarEvents' => calendarEvents,
        'smart_home_device' || 'smartHomeDevices' => smartHomeDevices,
        _ => plan,
      };
}

class ExpertRunDto {
  const ExpertRunDto({
    required this.id,
    required this.sourceType,
    required this.status,
    this.resultSummary,
    this.result,
    this.estimatedCredits,
    this.actualCredits,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.mode,
    this.inputJson,
    this.actions = const [],
  });

  factory ExpertRunDto.fromJson(Map<String, dynamic> json) => ExpertRunDto(
    id: _intOrZero(json['Id'] ?? json['id']),
    sourceType: ExpertRunSourceType.fromApiValue(
      json['SourceType'] ?? json['sourceType'],
    ),
    status: ExpertRunStatus.fromApiValue(json['status'] ?? json['Status']),
    resultSummary: (json['ResultSummary'] ?? json['resultSummary'])?.toString(),
    result: _stringOrNull(json['Result'] ?? json['result']),
    estimatedCredits: _intOrNull(
      json['EstimatedCredits'] ?? json['estimatedCredits'],
    ),
    actualCredits: _intOrNull(json['ActualCredits'] ?? json['actualCredits']),
    createdAt: _date(json['CreatedAt'] ?? json['createdAt']),
    startedAt: _nullableDate(json['StartedAt'] ?? json['startedAt']),
    finishedAt: _nullableDate(json['FinishedAt'] ?? json['finishedAt']),
    mode: _stringOrNull(json['mode'] ?? json['Mode']),
    inputJson: _stringOrNull(
      json['inputJson'] ?? json['InputJson'] ?? json['Input'],
    ),
    actions: _actionsFromJson(json['Actions'] ?? json['actions']),
  );

  final int id;
  final ExpertRunSourceType sourceType;
  final ExpertRunStatus status;
  final String? resultSummary;
  final String? result;
  final int? estimatedCredits;
  final int? actualCredits;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? mode;
  final String? inputJson;
  final List<ExpertRunActionDto> actions;

  bool get isTeam => mode == 'team';

  ExpertRunDto copyWithAction(ExpertRunActionDto action) {
    var index = actions.indexWhere((item) => item.id == action.id);
    if (index < 0 && action.isDeviceAction) {
      index = actions.indexWhere(
        (item) => item.isDeviceAction && item.status == 'pending',
      );
    }
    final updatedActions = List<ExpertRunActionDto>.of(actions);
    if (index < 0) {
      updatedActions.add(action);
    } else {
      updatedActions[index] = action;
    }
    return ExpertRunDto(
      id: id,
      sourceType: sourceType,
      status: status,
      resultSummary: resultSummary,
      result: result,
      estimatedCredits: estimatedCredits,
      actualCredits: actualCredits,
      createdAt: createdAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
      mode: mode,
      inputJson: inputJson,
      actions: updatedActions,
    );
  }
}

class ExpertRunEventDto {
  const ExpertRunEventDto({
    required this.id,
    required this.sequence,
    required this.eventType,
    required this.createdAt,
  });

  factory ExpertRunEventDto.fromJson(Map<String, dynamic> json) =>
      ExpertRunEventDto(
        id: _intOrZero(json['Id'] ?? json['id']),
        sequence: _intOrZero(json['Sequence'] ?? json['sequence']),
        eventType: (json['EventType'] ?? json['eventType'] ?? '').toString(),
        createdAt: _date(json['CreatedAt'] ?? json['createdAt']),
      );

  final int id;
  final int sequence;
  final String eventType;
  final DateTime createdAt;

  String? get displayText => switch (eventType) {
    'draft' || 'queued' => '任务已进入队列',
    'planning' || 'running' => '正在分析上下文',
    'completed' => '建议已生成',
    'failed' => '运行未能完成',
    'cancelled' => '运行已取消',
    _ => null,
  };
}

class ExpertRunActionDto {
  const ExpertRunActionDto({
    required this.id,
    required this.status,
    this.actionType,
    this.deviceId,
    this.deviceName,
    this.capability,
    this.targetValue,
    this.spaceName,
    this.actionTitle,
    this.actionDescription,
  });

  factory ExpertRunActionDto.fromJson(Map<String, dynamic> json) =>
      ExpertRunActionDto(
        id: _intOrZero(json['Id'] ?? json['id']),
        status: (json['status'] ?? json['Status'] ?? '').toString(),
        actionType: _resolveActionType(json),
        deviceId: _intOrNull(json['DeviceId'] ?? json['deviceId']),
        deviceName: _stringOrNull(json['DeviceName'] ?? json['deviceName']),
        capability: _stringOrNull(json['Capability'] ?? json['capability']),
        targetValue: json['TargetValue'] ?? json['targetValue'],
        spaceName: _stringOrNull(json['SpaceName'] ?? json['spaceName']),
        actionTitle: _stringOrNull(
          json['Title'] ?? json['ActionTitle'] ?? json['actionTitle'],
        ),
        actionDescription: _stringOrNull(
          json['Description'] ??
              json['ActionDescription'] ??
              json['actionDescription'],
        ),
      );

  final int id;
  final String status;
  final ExpertRunActionType? actionType;
  final int? deviceId;
  final String? deviceName;
  final String? capability;
  final Object? targetValue;
  final String? spaceName;
  final String? actionTitle;
  final String? actionDescription;

  bool get isDeviceAction => actionType == ExpertRunActionType.smartHomeDevices;
}

ExpertRunActionType? _resolveActionType(Map<String, dynamic> json) {
  final raw = json['ActionType'] ?? json['actionType'];
  if (raw == null) return null;
  return ExpertRunActionType.fromApiValue(raw);
}

List<ExpertRunActionDto> _actionsFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => ExpertRunActionDto.fromJson(item.cast<String, dynamic>()))
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

DateTime _date(Object? value) => _nullableDate(value) ?? DateTime.now().toUtc();

DateTime? _nullableDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();
