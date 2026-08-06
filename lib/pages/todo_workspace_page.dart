import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ui/nexus_theme.dart';
import '../features/ai/ai_repository.dart';
import '../features/todo/dto.dart';
import '../features/todo/todo_repository.dart';

class TodoWorkspacePage extends StatefulWidget {
  const TodoWorkspacePage({
    super.key,
    required this.repository,
    required this.aiRepository,
  });

  final TodoRepository repository;
  final AiRepository aiRepository;

  @override
  State<TodoWorkspacePage> createState() => _TodoWorkspacePageState();
}

class _TodoWorkspacePageState extends State<TodoWorkspacePage> {
  final _quickAdd = TextEditingController();
  final _search = TextEditingController();
  late Future<List<TodoDto>> _todos = _load();
  final Set<int> _selected = {};
  TodoStatus? _status;
  String _sort = 'due';
  bool _kanban = false;

  Future<List<TodoDto>> _load() => widget.repository.list();
  void _reload() => setState(() {
    _todos = _load();
  });

  @override
  void dispose() {
    _quickAdd.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _quickCreate() async {
    final title = _quickAdd.text.trim();
    if (title.isEmpty) return;
    try {
      await widget.repository.create(title: title);
      _quickAdd.clear();
      _reload();
    } catch (error) {
      _notice('创建失败：$error');
    }
  }

  List<TodoDto> _visible(List<TodoDto> todos) {
    final keyword = _search.text.trim().toLowerCase();
    final list = todos.where((todo) {
      final matchesStatus = _status == null || todo.status == _status;
      final matchesText =
          keyword.isEmpty ||
          todo.title.toLowerCase().contains(keyword) ||
          (todo.description?.toLowerCase().contains(keyword) ?? false) ||
          (todo.type?.toLowerCase().contains(keyword) ?? false);
      return matchesStatus && matchesText;
    }).toList();
    list.sort((left, right) {
      if (left.pinned != right.pinned) return left.pinned ? -1 : 1;
      return switch (_sort) {
        'created' => right.createdAt.compareTo(left.createdAt),
        'priority' => _priorityRank(
          left.priority,
        ).compareTo(_priorityRank(right.priority)),
        _ => _dueCompare(left, right),
      };
    });
    return list;
  }

  int _dueCompare(TodoDto left, TodoDto right) {
    if (left.dueAt == null && right.dueAt == null) {
      return right.createdAt.compareTo(left.createdAt);
    }
    if (left.dueAt == null) return 1;
    if (right.dueAt == null) return -1;
    return left.dueAt!.compareTo(right.dueAt!);
  }

  int _priorityRank(String? priority) => switch (priority) {
    'high' => 0,
    'medium' => 1,
    'low' => 2,
    _ => 3,
  };

  Future<void> _toggle(TodoDto todo) async {
    try {
      await widget.repository.update(todo.id, {
        'status': todo.status == TodoStatus.completed ? 'pending' : 'completed',
      });
      _reload();
    } catch (error) {
      _notice('更新失败：$error');
    }
  }

  Future<void> _edit([TodoDto? todo]) async {
    final draft = await showModalBottomSheet<_TodoDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TodoEditor(todo: todo, repository: widget.repository),
    );
    if (draft == null) return;
    try {
      if (todo == null) {
        await widget.repository.create(
          title: draft.title,
          description: draft.description,
          type: draft.type,
          priority: draft.priority,
          color: draft.color,
          dueAt: draft.dueAt,
          remindAt: draft.remindAt,
          pinned: draft.pinned,
          repeatRule: draft.repeatRule,
        );
      } else {
        await widget.repository.update(todo.id, draft.toPatch());
      }
      _reload();
    } catch (error) {
      _notice('保存失败：$error');
    }
  }

  Future<void> _batchComplete() async {
    await Future.wait(
      _selected.map(
        (id) => widget.repository.update(id, {'status': 'completed'}),
      ),
    );
    setState(_selected.clear);
    _reload();
  }

  Future<void> _batchDelete() async {
    final approved = await _confirm('删除所选 ${_selected.length} 个待办？');
    if (!approved) return;
    try {
      await Future.wait(_selected.map(widget.repository.delete));
      setState(_selected.clear);
      _reload();
    } catch (error) {
      _notice('删除失败：$error');
    }
  }

  Future<void> _exportJson(List<TodoDto> todos) async {
    final payload = {
      'schemaVersion': '2.3',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'todos': todos.map(_todoJson).toList(),
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    _notice('已复制 ${todos.length} 个待办的 JSON 到剪贴板');
  }

  Map<String, dynamic> _todoJson(TodoDto todo) => {
    'title': todo.title,
    'description': todo.description,
    'type': todo.type,
    'priority': todo.priority,
    'color': todo.color,
    'status': todo.status.wireValue,
    'dueAt': todo.dueAt?.toUtc().toIso8601String(),
    'remindAt': todo.remindAt?.toUtc().toIso8601String(),
    'pinned': todo.pinned,
    'repeatRule': todo.repeatRule,
  };

  Future<void> _import({required bool ai}) async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ai ? 'AI 提取待办' : '导入待办 JSON'),
        content: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: ai
                ? '例如：明天完成提案，周五和设计师确认封面'
                : '粘贴 schemaVersion 2.3 的 JSON',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final drafts = ai ? await _extractWithAi(raw) : _decodeImport(raw);
      for (final draft in drafts) {
        await widget.repository.create(
          title: draft.title,
          description: draft.description,
          type: draft.type,
          priority: draft.priority,
          color: draft.color,
          dueAt: draft.dueAt,
          remindAt: draft.remindAt,
          pinned: draft.pinned,
          repeatRule: draft.repeatRule,
        );
      }
      _reload();
      _notice('已导入 ${drafts.length} 个待办');
    } catch (error) {
      _notice('导入失败：$error');
    }
  }

  List<_TodoDraft> _decodeImport(String raw) {
    final decoded = jsonDecode(raw);
    final values = decoded is Map ? decoded['todos'] : decoded;
    if (values is! List) throw const FormatException('未找到 todos 数组');
    return values.whereType<Map>().map((value) {
      final map = value.cast<String, dynamic>();
      final title = map['title']?.toString().trim() ?? '';
      if (title.isEmpty) throw const FormatException('待办标题不能为空');
      return _TodoDraft(
        title: title,
        description: map['description']?.toString(),
        type: map['type']?.toString(),
        priority: map['priority']?.toString(),
        color: map['color']?.toString(),
        dueAt: _date(map['dueAt']),
        remindAt: _date(map['remindAt']),
        pinned: map['pinned'] == true,
        repeatRule: map['repeatRule']?.toString(),
      );
    }).toList();
  }

  DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Future<List<_TodoDraft>> _extractWithAi(String input) async {
    final response = await widget.aiRepository.generate(
      scope: 'import',
      prompt: '将输入拆为待办。每行一个待办标题，不要编号或解释。',
      input: input,
    );
    final titles = response.content
        .split(RegExp(r'\r?\n'))
        .map(
          (line) => line.replaceFirst(RegExp(r'^\s*[-*•\d.)]+\s*'), '').trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList();
    if (titles.isEmpty) throw const FormatException('AI 未返回待办');
    return titles.map((title) => _TodoDraft(title: title)).toList();
  }

  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        ),
      ) ??
      false;

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_selected.isEmpty ? '待办' : '已选 ${_selected.length} 项'),
      actions: _selected.isNotEmpty
          ? [
              IconButton(
                tooltip: '批量完成',
                onPressed: _batchComplete,
                icon: const Icon(Icons.done_all),
              ),
              IconButton(
                tooltip: '批量删除',
                onPressed: _batchDelete,
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(
                onPressed: () => setState(_selected.clear),
                icon: const Icon(Icons.close),
              ),
            ]
          : [
              IconButton(
                tooltip: '导出',
                onPressed: () async => _exportJson(await _todos),
                icon: const Icon(Icons.upload_outlined),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'json') _import(ai: false);
                  if (value == 'ai') _import(ai: true);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'json', child: Text('导入 JSON')),
                  PopupMenuItem(value: 'ai', child: Text('AI 提取待办')),
                ],
              ),
            ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _edit(),
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<TodoDto>>(
      future: _todos,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _TodoLoadError(onRetry: _reload);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final todos = _visible(snapshot.data!);
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: NexusLayout.pagePadding.copyWith(
              top: 8,
              bottom: NexusLayout.bottomContentPadding,
            ),
            children: [
              if (_selected.isEmpty) ...[
                const NexusPageHeader(
                  title: '待办',
                  description: '聚焦下一件该完成的事，随时调整节奏。',
                ),
                const SizedBox(height: NexusLayout.sectionGap),
              ],
              NexusSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _quickAdd,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _quickCreate(),
                      decoration: InputDecoration(
                        hintText: '快速添加待办，回车创建',
                        prefixIcon: const Icon(Icons.add_task_outlined),
                        suffixIcon: IconButton(
                          tooltip: '创建待办',
                          onPressed: _quickCreate,
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: NexusLayout.controlGap),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: '搜索标题、类型或描述',
                      ),
                    ),
                    const SizedBox(height: NexusLayout.controlGap),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...<TodoStatus?>[
                            null,
                            TodoStatus.pending,
                            TodoStatus.inProgress,
                            TodoStatus.completed,
                          ].map(
                            (status) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_statusText(status)),
                                selected: _status == status,
                                onSelected: (_) =>
                                    setState(() => _status = status),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: '排序方式',
                            onSelected: (value) =>
                                setState(() => _sort = value),
                            child: Chip(
                              avatar: const Icon(Icons.sort, size: 18),
                              label: Text('排序：$_sortText'),
                            ),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'due', child: Text('到期时间')),
                              PopupMenuItem(
                                value: 'created',
                                child: Text('创建时间'),
                              ),
                              PopupMenuItem(
                                value: 'priority',
                                child: Text('优先级'),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('看板'),
                            selected: _kanban,
                            onSelected: (value) =>
                                setState(() => _kanban = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              if (todos.isEmpty)
                const _TodoEmptyState()
              else if (_kanban)
                _Kanban(todos: todos, onTap: _edit, onToggle: _toggle)
              else
                ...todos.map(
                  (todo) => Padding(
                    padding: const EdgeInsets.only(bottom: NexusLayout.itemGap),
                    child: _TodoTile(
                      todo: todo,
                      selected: _selected.contains(todo.id),
                      selecting: _selected.isNotEmpty,
                      onTap: () => _selected.isNotEmpty
                          ? setState(
                              () => _selected.contains(todo.id)
                                  ? _selected.remove(todo.id)
                                  : _selected.add(todo.id),
                            )
                          : _edit(todo),
                      onLongPress: () => setState(() => _selected.add(todo.id)),
                      onToggle: () => _toggle(todo),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  String get _sortText => switch (_sort) {
    'created' => '创建时间',
    'priority' => '优先级',
    _ => '到期时间',
  };
  String _statusText(TodoStatus? value) => switch (value) {
    null => '全部',
    TodoStatus.pending => '待办',
    TodoStatus.inProgress => '进行中',
    TodoStatus.completed => '已完成',
    TodoStatus.unknown => '未知',
  };
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.todo,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
  });
  final TodoDto todo;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final done = todo.status == TodoStatus.completed;
    return NexusSurface(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: selecting
            ? Checkbox(value: selected, onChanged: (_) => onTap())
            : Checkbox(value: done, onChanged: (_) => onToggle()),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Wrap(
          spacing: 7,
          runSpacing: 4,
          children: [
            if (todo.dueAt != null)
              _Tag(
                text: '截止 ${_dateLabel(todo.dueAt!)}',
                icon: Icons.schedule_outlined,
              ),
            if (todo.repeatRule != null && todo.repeatRule != 'none')
              const _Tag(text: '重复', icon: Icons.repeat_rounded),
            if (todo.remindAt != null)
              const _Tag(text: '提醒', icon: Icons.notifications_outlined),
            if (todo.type?.isNotEmpty ?? false) _Tag(text: todo.type!),
          ],
        ),
        trailing: todo.pinned
            ? const Icon(Icons.push_pin_rounded, size: 18)
            : null,
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) Icon(icon, size: 14),
      if (icon != null) const SizedBox(width: 3),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _Kanban extends StatelessWidget {
  const _Kanban({
    required this.todos,
    required this.onTap,
    required this.onToggle,
  });
  final List<TodoDto> todos;
  final ValueChanged<TodoDto> onTap;
  final ValueChanged<TodoDto> onToggle;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final status in [
          TodoStatus.pending,
          TodoStatus.inProgress,
          TodoStatus.completed,
        ])
          SizedBox(
            width: 245,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(switch (status) {
                    TodoStatus.pending => '待办',
                    TodoStatus.inProgress => '进行中',
                    TodoStatus.completed => '已完成',
                    _ => '',
                  }, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...todos
                      .where((todo) => todo.status == status)
                      .map(
                        (todo) => _TodoTile(
                          todo: todo,
                          selected: false,
                          selecting: false,
                          onTap: () => onTap(todo),
                          onLongPress: () => onTap(todo),
                          onToggle: () => onToggle(todo),
                        ),
                      ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _TodoEmptyState extends StatelessWidget {
  const _TodoEmptyState();

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 36,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        const Text('没有匹配的待办'),
      ],
    ),
  );
}

class _TodoLoadError extends StatelessWidget {
  const _TodoLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: NexusLayout.pagePadding,
      child: NexusSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text('待办暂时无法加载'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TodoDraft {
  const _TodoDraft({
    required this.title,
    this.description,
    this.type,
    this.priority,
    this.color,
    this.dueAt,
    this.remindAt,
    this.pinned = false,
    this.repeatRule,
  });
  final String title;
  final String? description;
  final String? type;
  final String? priority;
  final String? color;
  final DateTime? dueAt;
  final DateTime? remindAt;
  final bool pinned;
  final String? repeatRule;
  Map<String, dynamic> toPatch() => {
    'title': title,
    'description': description,
    'priority': priority,
    'color': color,
    'dueAt': dueAt,
    'remindAt': remindAt,
    'pinned': pinned,
    'repeatRule': repeatRule,
  };
}

class _TodoEditor extends StatefulWidget {
  const _TodoEditor({this.todo, required this.repository});
  final TodoDto? todo;
  final TodoRepository repository;
  @override
  State<_TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<_TodoEditor> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _type;
  late String _priority;
  late String _repeat;
  late bool _pinned;
  late Future<List<SubtaskDto>> _subtasks;
  DateTime? _dueAt;
  DateTime? _remindAt;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.todo?.title ?? '');
    _description = TextEditingController(text: widget.todo?.description ?? '');
    _type = TextEditingController(text: widget.todo?.type ?? '');
    _priority = widget.todo?.priority ?? 'medium';
    _repeat = widget.todo?.repeatRule ?? 'none';
    _pinned = widget.todo?.pinned ?? false;
    _dueAt = widget.todo?.dueAt;
    _remindAt = widget.todo?.remindAt;
    _subtasks = widget.todo == null
        ? Future.value(const [])
        : widget.repository.listSubtasks(widget.todo!.id);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _type.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool reminder}) async {
    final initial =
        (reminder ? _remindAt : _dueAt)?.toLocal() ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (reminder) {
        _remindAt = value;
      } else {
        _dueAt = value;
      }
    });
  }

  void _reloadSubtasks() {
    final todo = widget.todo;
    if (todo == null) return;
    setState(() => _subtasks = widget.repository.listSubtasks(todo.id));
  }

  Future<void> _addSubtask() async {
    final todo = widget.todo;
    if (todo == null) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;
    try {
      await widget.repository.addSubtask(todo.id, text: text.trim());
      _reloadSubtasks();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add subtask: $error')));
    }
  }

  Future<void> _toggleSubtask(SubtaskDto subtask) async {
    final todo = widget.todo;
    if (todo == null) return;
    await widget.repository.updateSubtask(todo.id, subtask.id, {
      'done': !subtask.done,
    });
    _reloadSubtasks();
  }

  Future<void> _deleteSubtask(SubtaskDto subtask) async {
    final todo = widget.todo;
    if (todo == null) return;
    await widget.repository.deleteSubtask(todo.id, subtask.id);
    _reloadSubtasks();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      _TodoDraft(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        type: _type.text.trim().isEmpty ? null : _type.text.trim(),
        priority: _priority,
        dueAt: _dueAt,
        remindAt: _remindAt,
        pinned: _pinned,
        repeatRule: _repeat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.todo == null ? '新建待办' : '编辑待办',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _type,
              decoration: const InputDecoration(
                labelText: '类型',
                hintText: '工作、生活…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: '优先级',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'high', child: Text('高')),
                DropdownMenuItem(value: 'medium', child: Text('中')),
                DropdownMenuItem(value: 'low', child: Text('低')),
              ],
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: _repeat,
              decoration: const InputDecoration(
                labelText: '重复',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('不重复')),
                DropdownMenuItem(value: 'daily', child: Text('每天')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'biweekly', child: Text('每两周')),
                DropdownMenuItem(value: 'monthly', child: Text('每月')),
                DropdownMenuItem(value: 'yearly', child: Text('每年')),
              ],
              onChanged: (value) => setState(() => _repeat = value!),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _pinned,
              onChanged: (value) => setState(() => _pinned = value),
              title: const Text('置顶'),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pick(reminder: false),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(_dueAt == null ? '设置截止时间' : '截止已设置'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pick(reminder: true),
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(_remindAt == null ? '设置提醒' : '提醒已设置'),
                ),
              ],
            ),
            if (widget.todo != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subtasks',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add subtask',
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add_task_outlined),
                  ),
                ],
              ),
              FutureBuilder<List<SubtaskDto>>(
                future: _subtasks,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Unable to load subtasks');
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final subtasks = snapshot.data!;
                  if (subtasks.isEmpty) {
                    return const Text('No subtasks yet');
                  }
                  return Column(
                    children: subtasks
                        .map(
                          (subtask) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: subtask.done,
                              onChanged: (_) => _toggleSubtask(subtask),
                            ),
                            title: Text(
                              subtask.text,
                              style: TextStyle(
                                decoration: subtask.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete subtask',
                              onPressed: () => _deleteSubtask(subtask),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _submit, child: const Text('保存')),
            ),
          ],
        ),
      ),
    ),
  );
}
