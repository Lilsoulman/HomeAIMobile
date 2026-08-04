import 'dto.dart';
import 'todo_repository.dart';

class LocalTodoRepository implements TodoRepository {
  LocalTodoRepository() {
    final now = DateTime.now();
    _todos.addAll([
      _TodoRecord(
        id: _nextTodoId++,
        title: '梳理本周关键目标',
        type: '规划',
        priority: 'high',
        dueAt: DateTime(now.year, now.month, now.day, 18),
        pinned: true,
        createdAt: now,
      ),
      _TodoRecord(
        id: _nextTodoId++,
        title: '安排一次深度工作',
        type: '工作',
        priority: 'medium',
        dueAt: now.add(const Duration(days: 1, hours: 10)),
        repeatRule: 'weekly',
        createdAt: now,
      ),
    ]);
  }

  final List<_TodoRecord> _todos = [];
  final Map<int, List<_SubtaskRecord>> _subtasks = {};
  int _nextTodoId = 1;
  int _nextSubtaskId = 1;

  @override
  Future<SubtaskDto> addSubtask(
    int todoId, {
    required String text,
    int? seq,
  }) async {
    _requireTodo(todoId);
    final item = _SubtaskRecord(
      id: _nextSubtaskId++,
      text: text.trim(),
      done: false,
      seq: seq ?? _subtasks[todoId]?.length ?? 0,
    );
    _subtasks.putIfAbsent(todoId, () => []).add(item);
    return item.toDto();
  }

  @override
  Future<TodoDto> create({
    required String title,
    String? description,
    String? type,
    String? priority,
    String? color,
    String? status,
    DateTime? dueAt,
    DateTime? remindAt,
    bool? pinned,
    int? sortOrder,
    String? repeatRule,
    int? parentId,
  }) async {
    final now = DateTime.now();
    final item = _TodoRecord(
      id: _nextTodoId++,
      title: title.trim(),
      description: description,
      type: type,
      priority: priority,
      color: color,
      status: status ?? 'pending',
      dueAt: dueAt,
      remindAt: remindAt,
      pinned: pinned ?? false,
      sortOrder: sortOrder ?? 0,
      repeatRule: repeatRule,
      createdAt: now,
      updatedAt: now,
    );
    _todos.add(item);
    return item.toDto();
  }

  @override
  Future<void> delete(int id) async {
    _todos.removeWhere((item) => item.id == id);
    _subtasks.remove(id);
  }

  @override
  Future<void> deleteSubtask(int todoId, int subId) async {
    _subtasks[todoId]?.removeWhere((item) => item.id == subId);
  }

  @override
  Future<List<SubtaskDto>> listSubtasks(int todoId) async =>
      (_subtasks[todoId] ?? const [])
          .map((item) => item.toDto())
          .toList(growable: false);

  @override
  Future<List<TodoDto>> list({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async => _todos
      .where((item) {
        if (status != null && item.status != status) {
          return false;
        }
        if (from != null &&
            (item.dueAt == null || item.dueAt!.isBefore(from))) {
          return false;
        }
        if (to != null && (item.dueAt == null || item.dueAt!.isAfter(to))) {
          return false;
        }
        return true;
      })
      .map((item) => item.toDto())
      .toList(growable: false);

  @override
  Future<TodoDto> update(int id, Map<String, dynamic> patch) async {
    final item = _requireTodo(id);
    item.apply(patch);
    return item.toDto();
  }

  @override
  Future<SubtaskDto> updateSubtask(
    int todoId,
    int subId,
    Map<String, dynamic> patch,
  ) async {
    final item = _subtasks[todoId]
        ?.where((item) => item.id == subId)
        .firstOrNull;
    if (item == null) throw StateError('未找到子任务');
    item.text = patch['text']?.toString() ?? item.text;
    item.done = patch['done'] as bool? ?? item.done;
    item.seq = patch['seq'] as int? ?? item.seq;
    return item.toDto();
  }

  _TodoRecord _requireTodo(int id) =>
      _todos.where((item) => item.id == id).firstOrNull ??
      (throw StateError('未找到待办'));
}

class _TodoRecord {
  _TodoRecord({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.priority,
    this.color,
    this.status = 'pending',
    this.dueAt,
    this.remindAt,
    this.pinned = false,
    this.sortOrder = 0,
    this.repeatRule,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final int id;
  String title;
  String? description;
  String? type;
  String? priority;
  String? color;
  String status;
  DateTime? dueAt;
  DateTime? remindAt;
  DateTime? completedAt;
  bool pinned;
  int sortOrder;
  String? repeatRule;
  final DateTime createdAt;
  DateTime updatedAt;

  void apply(Map<String, dynamic> patch) {
    title = patch['title']?.toString() ?? title;
    description = patch.containsKey('description')
        ? patch['description']?.toString()
        : description;
    type = patch.containsKey('type') ? patch['type']?.toString() : type;
    priority = patch.containsKey('priority')
        ? patch['priority']?.toString()
        : priority;
    color = patch.containsKey('color') ? patch['color']?.toString() : color;
    dueAt = patch.containsKey('dueAt') ? patch['dueAt'] as DateTime? : dueAt;
    remindAt = patch.containsKey('remindAt')
        ? patch['remindAt'] as DateTime?
        : remindAt;
    pinned = patch['pinned'] as bool? ?? pinned;
    sortOrder = patch['sortOrder'] as int? ?? sortOrder;
    repeatRule = patch.containsKey('repeatRule')
        ? patch['repeatRule']?.toString()
        : repeatRule;
    if (patch['status'] != null) {
      status = patch['status'].toString();
      completedAt = status == 'completed' ? DateTime.now() : null;
    }
    updatedAt = DateTime.now();
  }

  TodoDto toDto() => TodoDto(
    id: id,
    title: title,
    description: description,
    type: type,
    priority: priority,
    color: color,
    status: switch (status) {
      'pending' => TodoStatus.pending,
      'in_progress' => TodoStatus.inProgress,
      'completed' => TodoStatus.completed,
      _ => TodoStatus.unknown,
    },
    dueAt: dueAt,
    remindAt: remindAt,
    completedAt: completedAt,
    pinned: pinned,
    sortOrder: sortOrder,
    repeatRule: repeatRule,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class _SubtaskRecord {
  _SubtaskRecord({
    required this.id,
    required this.text,
    required this.done,
    required this.seq,
  });
  final int id;
  String text;
  bool done;
  int seq;
  SubtaskDto toDto() => SubtaskDto(id: id, text: text, done: done, seq: seq);
}
