import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/family_schedule/dto.dart';
import '../features/family_schedule/family_schedule_repository.dart';

class FamilySchedulePage extends StatefulWidget {
  const FamilySchedulePage({super.key});

  @override
  State<FamilySchedulePage> createState() => _FamilySchedulePageState();
}

class _FamilySchedulePageState extends State<FamilySchedulePage> {
  late Future<_FamilyScheduleData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<_FamilyScheduleData> _load() async {
    final repository = context.read<FamilyScheduleRepository>();
    final from = DateTime.now();
    final to = from.add(const Duration(days: 7));
    final values = await Future.wait<Object>([
      repository.listEvents(from: from, to: to),
      repository.listConflicts(from: from, to: to),
      repository.listAvailability(from: from, to: to),
      repository.listDocumentDeadlines(),
      repository.listReminders(),
      repository.tomorrowPreview(),
    ]);
    return _FamilyScheduleData(
      events: values[0] as List<FamilyScheduleEventDto>,
      conflicts: values[1] as List<FamilyScheduleConflictDto>,
      availability: values[2] as List<FamilyScheduleAvailabilityDto>,
      deadlines: values[3] as List<FamilyDocumentDeadlineDto>,
      reminders: values[4] as List<FamilyScheduleReminderDto>,
      tomorrow: values[5] as FamilyTomorrowPreviewDto,
    );
  }

  Future<void> _addDeadline() async {
    final request = await showDialog<FamilyDocumentDeadlineCreateDto>(
      context: context,
      builder: (_) => const _DocumentDeadlineDialog(),
    );
    if (request == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<FamilyScheduleRepository>().createDocumentDeadline(
        request,
      );
      if (mounted) _reload();
    } on ApiException catch (error) {
      if (mounted) _message(error.msg);
    } catch (_) {
      if (mounted) _message('家庭日程暂时不可用，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('家庭日程'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: '刷新',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : _addDeadline,
      icon: const Icon(Icons.add_alert_outlined),
      label: const Text('添加到期提醒'),
    ),
    body: FutureBuilder<_FamilyScheduleData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _LoadError(onRetry: _reload);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) return const _ScheduleEmpty();
        return ListView(
          padding: NexusLayout.pagePadding.copyWith(bottom: 100),
          children: [
            _TomorrowPreviewCard(preview: data.tomorrow),
            _Section(
              title: '未来七天',
              emptyText: '近期没有家庭日程。',
              children: data.events
                  .map((event) => _EventTile(event: event))
                  .toList(growable: false),
            ),
            _Section(
              title: '日程冲突',
              emptyText: '暂未发现时间冲突。',
              children: data.conflicts
                  .map((conflict) => _ConflictTile(conflict: conflict))
                  .toList(growable: false),
            ),
            _Section(
              title: '共同空档',
              emptyText: '未来七天暂无共同空档。',
              children: data.availability
                  .take(3)
                  .map((slot) => _AvailabilityTile(slot: slot))
                  .toList(growable: false),
            ),
            _Section(
              title: '到期提醒',
              emptyText: '暂时没有到期事项。',
              children: [
                ...data.reminders.map(_ReminderTile.new),
                ...data.deadlines
                    .where((deadline) => deadline.isActive)
                    .map((deadline) => _DeadlineTile(deadline: deadline)),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _FamilyScheduleData {
  const _FamilyScheduleData({
    required this.events,
    required this.conflicts,
    required this.availability,
    required this.deadlines,
    required this.reminders,
    required this.tomorrow,
  });

  final List<FamilyScheduleEventDto> events;
  final List<FamilyScheduleConflictDto> conflicts;
  final List<FamilyScheduleAvailabilityDto> availability;
  final List<FamilyDocumentDeadlineDto> deadlines;
  final List<FamilyScheduleReminderDto> reminders;
  final FamilyTomorrowPreviewDto tomorrow;

  bool get isEmpty =>
      events.isEmpty &&
      conflicts.isEmpty &&
      availability.isEmpty &&
      deadlines.isEmpty &&
      reminders.isEmpty &&
      tomorrow.events.isEmpty &&
      tomorrow.conflicts.isEmpty &&
      tomorrow.reminders.isEmpty;
}

class _TomorrowPreviewCard extends StatelessWidget {
  const _TomorrowPreviewCard({required this.preview});
  final FamilyTomorrowPreviewDto preview;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_twilight_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '明日预览',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(_dateLabel(preview.date)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            preview.events.isEmpty &&
                    preview.conflicts.isEmpty &&
                    preview.reminders.isEmpty
                ? '明天暂无日程、冲突或到期事项。'
                : '日程 ${preview.events.length} 项 · 冲突 ${preview.conflicts.length} 项 · 提醒 ${preview.reminders.length} 项',
          ),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.children,
  });
  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (children.isEmpty)
          NexusSurface(child: Text(emptyText))
        else
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NexusSurface(child: child),
            ),
          ),
      ],
    ),
  );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final FamilyScheduleEventDto event;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.event_outlined),
    title: Text(event.title),
    subtitle: Text('${event.memberName} · ${_eventTimeLabel(event)}'),
  );
}

class _ConflictTile extends StatelessWidget {
  const _ConflictTile({required this.conflict});
  final FamilyScheduleConflictDto conflict;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.warning_amber_rounded),
    title: Text('${conflict.first.memberName} 与 ${conflict.second.memberName}'),
    subtitle: Text(
      '${conflict.first.title} / ${conflict.second.title}\n${_rangeLabel(conflict.overlapStartAt, conflict.overlapEndAt)}',
    ),
    isThreeLine: true,
  );
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({required this.slot});
  final FamilyScheduleAvailabilityDto slot;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.groups_outlined),
    title: const Text('全员可用'),
    subtitle: Text(_rangeLabel(slot.startAt, slot.endAt)),
  );
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile(this.reminder);
  final FamilyScheduleReminderDto reminder;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.notifications_active_outlined),
    title: Text(reminder.title),
    subtitle: Text(
      '${_dateLabel(reminder.dueDate)} · ${_daysLabel(reminder.daysRemaining)}',
    ),
  );
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({required this.deadline});
  final FamilyDocumentDeadlineDto deadline;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.badge_outlined),
    title: Text(deadline.displayName),
    subtitle: Text(
      '${_documentTypeLabel(deadline.documentType)} · ${_dateLabel(deadline.expiresOn)}',
    ),
  );
}

class _ScheduleEmpty extends StatelessWidget {
  const _ScheduleEmpty();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: NexusLayout.pagePadding,
      child: const Text('未来七天没有家庭日程或到期事项。'),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('加载失败，重试'),
    ),
  );
}

class _DocumentDeadlineDialog extends StatefulWidget {
  const _DocumentDeadlineDialog();
  @override
  State<_DocumentDeadlineDialog> createState() =>
      _DocumentDeadlineDialogState();
}

class _DocumentDeadlineDialogState extends State<_DocumentDeadlineDialog> {
  final _displayName = TextEditingController();
  String _documentType = 'other';
  DateTime _expiresOn = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _expiresOn,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 30),
    );
    if (value != null && mounted) setState(() => _expiresOn = value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('添加证件到期提醒'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('仅填写家庭内展示名称，请勿输入证件号码、照片或原文。'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _documentType,
          items: const [
            DropdownMenuItem(value: 'identity_card', child: Text('身份证')),
            DropdownMenuItem(value: 'passport', child: Text('护照')),
            DropdownMenuItem(value: 'driver_license', child: Text('驾驶证')),
            DropdownMenuItem(value: 'residence_permit', child: Text('居住证')),
            DropdownMenuItem(value: 'other', child: Text('其他')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _documentType = value);
          },
        ),
        TextField(
          controller: _displayName,
          decoration: const InputDecoration(labelText: '展示名称'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _chooseDate,
            icon: const Icon(Icons.event_outlined),
            label: Text('到期日：${_dateLabel(_expiresOn)}'),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          final displayName = _displayName.text.trim();
          if (displayName.isEmpty) return;
          Navigator.pop(
            context,
            FamilyDocumentDeadlineCreateDto(
              documentType: _documentType,
              displayName: displayName,
              expiresOn: _expiresOn,
            ),
          );
        },
        child: const Text('保存'),
      ),
    ],
  );
}

String _eventTimeLabel(FamilyScheduleEventDto event) => event.allDay
    ? '${_dateLabel(event.startAt)} 全天'
    : event.endAt == null
    ? _dateTimeLabel(event.startAt)
    : _rangeLabel(event.startAt, event.endAt!);

String _rangeLabel(DateTime start, DateTime end) =>
    '${_dateTimeLabel(start)} - ${_timeLabel(end)}';

String _dateTimeLabel(DateTime value) =>
    '${_dateLabel(value)} ${_timeLabel(value)}';

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.month}月${local.day}日';
}

String _timeLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _daysLabel(int days) => days < 0
    ? '已逾期 ${days.abs()} 天'
    : days == 0
    ? '今天到期'
    : '$days 天后到期';

String _documentTypeLabel(String type) => switch (type) {
  'identity_card' => '身份证',
  'passport' => '护照',
  'driver_license' => '驾驶证',
  'residence_permit' => '居住证',
  _ => '证件',
};
