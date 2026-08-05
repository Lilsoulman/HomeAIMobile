// 执行模式 13：Todo / Subtask DTO。

enum TodoStatus { pending, inProgress, completed, unknown }

TodoStatus _parseStatus(String? raw) {
  switch (raw) {
    case 'pending':
      return TodoStatus.pending;
    case 'in_progress':
      return TodoStatus.inProgress;
    case 'completed':
      return TodoStatus.completed;
    default:
      return TodoStatus.unknown;
  }
}

extension TodoStatusX on TodoStatus {
  String get wireValue => switch (this) {
    TodoStatus.pending => 'pending',
    TodoStatus.inProgress => 'in_progress',
    TodoStatus.completed => 'completed',
    TodoStatus.unknown => 'pending',
  };
}

class TodoDto {
  TodoDto({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.priority,
    this.color,
    required this.status,
    this.dueAt,
    this.remindAt,
    this.completedAt,
    required this.pinned,
    required this.sortOrder,
    this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoDto.fromJson(Map<String, dynamic> json) => TodoDto(
    id: (json['Id'] as num).toInt(),
    title: (json['Title'] ?? '').toString(),
    description: json['Description'] as String?,
    type: json['Type'] as String?,
    priority: json['Priority'] as String?,
    color: json['Color'] as String?,
    status: _parseStatus(json['Status'] as String?),
    dueAt: json['DueAt'] == null
        ? null
        : DateTime.parse(json['DueAt'] as String),
    remindAt: json['RemindAt'] == null
        ? null
        : DateTime.parse(json['RemindAt'] as String),
    completedAt: json['CompletedAt'] == null
        ? null
        : DateTime.parse(json['CompletedAt'] as String),
    pinned: (json['Pinned'] as bool?) ?? false,
    sortOrder: ((json['SortOrder'] as num?) ?? 0).toInt(),
    repeatRule: json['RepeatRule'] as String?,
    createdAt: DateTime.parse(json['CreatedAt'] as String),
    updatedAt: DateTime.parse(json['UpdatedAt'] as String),
  );

  final int id;
  final String title;
  final String? description;
  final String? type;
  final String? priority;
  final String? color;
  final TodoStatus status;
  final DateTime? dueAt;
  final DateTime? remindAt;
  final DateTime? completedAt;
  final bool pinned;
  final int sortOrder;
  final String? repeatRule;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SubtaskDto {
  SubtaskDto({
    required this.id,
    required this.text,
    required this.done,
    required this.seq,
  });

  factory SubtaskDto.fromJson(Map<String, dynamic> json) => SubtaskDto(
    id: (json['id'] as num).toInt(),
    text: (json['text'] ?? '').toString(),
    done: _asBool(json['done']),
    seq: ((json['seq'] as num?) ?? 0).toInt(),
  );

  final int id;
  final String text;
  final bool done;
  final int seq;
}

bool _asBool(Object? value) => switch (value) {
  bool value => value,
  num value => value != 0,
  _ => false,
};
