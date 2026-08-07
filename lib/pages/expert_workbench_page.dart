import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../experts/domain.dart';
import '../experts/expert_repository.dart';
import '../features/attachment/attachment_repository.dart';
import '../features/attachment/dto.dart';
import '../features/expert/dto.dart';
import '../features/expert/expert_run_repository.dart';

class ExpertCatalogPage extends StatefulWidget {
  const ExpertCatalogPage({super.key, required this.repository});

  final ExpertRepository repository;

  @override
  State<ExpertCatalogPage> createState() => _ExpertCatalogPageState();
}

class _ExpertCatalogPageState extends State<ExpertCatalogPage> {
  String _query = '';
  late Future<List<Expert>> _experts = _load();

  Future<List<Expert>> _load() => widget.repository.listExperts(query: _query);

  void _reload() => setState(() {
    _experts = _load();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FutureBuilder<List<Expert>>(
        future: _experts,
        builder: (context, snapshot) {
          final experts = snapshot.data ?? const <Expert>[];
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: NexusLayout.pagePadding.copyWith(
                bottom: NexusLayout.bottomContentPadding,
              ),
              children: [
                NexusPageHeader(
                  title: 'AI 专家',
                  description: '选择合适的专家，把目标变成可确认的下一步。',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '周末出行',
                        onPressed: () => context.push('/ai/travel'),
                        icon: const Icon(Icons.landscape_outlined),
                      ),
                      IconButton(
                        tooltip: '每日知识',
                        onPressed: () => context.push('/ai/knowledge'),
                        icon: const Icon(Icons.auto_stories_outlined),
                      ),
                      IconButton(
                        tooltip: '探店翻牌',
                        onPressed: () => context.push('/ai/life-recommend'),
                        icon: const Icon(Icons.explore_outlined),
                      ),
                      IconButton(
                        tooltip: '行程规划',
                        onPressed: () => context.push('/ai/life-trip'),
                        icon: const Icon(Icons.luggage_outlined),
                      ),
                      IconButton(
                        tooltip: '专家会话',
                        onPressed: () => context.push('/ai/conversations'),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      IconButton(
                        tooltip: '刷新专家',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NexusLayout.sectionGap),
                TextField(
                  onChanged: (value) {
                    _query = value;
                    _reload();
                  },
                  decoration: const InputDecoration(
                    hintText: '搜索专家',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: NexusLayout.sectionGap),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  _CatalogError(
                    error: _messageFor(snapshot.error),
                    onRetry: _reload,
                  )
                else if (experts.isEmpty)
                  const _CatalogEmpty()
                else
                  ...experts.map(
                    (expert) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: NexusLayout.itemGap,
                      ),
                      child: _ExpertCard(
                        expert: expert,
                        onTap: () => context.push(
                          '/ai/${expert.id}?type=${expert.sourceType.apiValue}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class ExpertWorkspacePage extends StatefulWidget {
  const ExpertWorkspacePage({
    super.key,
    required this.repository,
    required this.runRepository,
    required this.attachmentRepository,
    required this.expertId,
    required this.sourceType,
  });

  final ExpertRepository repository;
  final ExpertRunRepository runRepository;
  final AttachmentRepository attachmentRepository;
  final String expertId;
  final ExpertSourceType sourceType;

  @override
  State<ExpertWorkspacePage> createState() => _ExpertWorkspacePageState();
}

class _ExpertWorkspacePageState extends State<ExpertWorkspacePage> {
  final _input = TextEditingController();
  Timer? _poller;
  late Future<Expert?> _expert = _loadExpert();
  ExpertRunDto? _run;
  List<ExpertRunEventDto> _events = const [];
  String? _runError;
  bool _submitting = false;
  bool _confirming = false;
  late Future<List<AttachmentDto>> _attachments = _loadAttachments();
  final Set<int> _selectedAttachmentIds = <int>{};

  Future<Expert?> _loadExpert() => widget.repository.getExpert(
    widget.expertId,
    sourceType: widget.sourceType,
  );

  Future<List<AttachmentDto>> _loadAttachments() =>
      widget.attachmentRepository.listFiles();

  void _reloadAttachments() => setState(() {
    _attachments = widget.attachmentRepository.listFiles();
  });

  @override
  void dispose() {
    _poller?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _start(Expert expert) async {
    final request = _input.text.trim();
    final sourceId = int.tryParse(expert.id);
    if (request.isEmpty || sourceId == null || _submitting) return;
    setState(() {
      _submitting = true;
      _runError = null;
    });
    try {
      final fileRefs = _selectedAttachmentIds
          .map((id) => <String, dynamic>{'id': id, 'role': 'context'})
          .toList(growable: false);
      final input = <String, dynamic>{'request': request};
      if (fileRefs.isNotEmpty) input['fileRefs'] = fileRefs;
      final run = await widget.runRepository.start(
        sourceType: expert.sourceType == ExpertSourceType.group
            ? ExpertRunSourceType.group
            : ExpertRunSourceType.expert,
        sourceId: sourceId,
        inputJson: jsonEncode(input),
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      _input.clear();
      setState(() => _run = run);
      await _refreshRun();
      _beginPolling();
    } catch (error) {
      if (mounted) setState(() => _runError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _beginPolling() {
    _poller?.cancel();
    if (_run == null || _run!.status.isTerminal) return;
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _refreshRun());
  }

  Future<void> _refreshRun() async {
    final current = _run;
    if (current == null) return;
    try {
      final values = await Future.wait<Object>([
        widget.runRepository.get(current.id),
        widget.runRepository.listEvents(current.id),
      ]);
      if (!mounted) return;
      final refreshed = values[0] as ExpertRunDto;
      setState(() {
        _run = refreshed;
        _events = (values[1] as List<ExpertRunEventDto>)
            .where((event) => event.displayText != null)
            .toList(growable: false);
        _runError = null;
      });
      if (refreshed.status.isTerminal) _poller?.cancel();
    } catch (error) {
      if (mounted) setState(() => _runError = _messageFor(error));
    }
  }

  Future<void> _cancel() async {
    final run = _run;
    if (run == null || run.status.isTerminal || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.runRepository.cancel(run.id);
      await _refreshRun();
    } catch (error) {
      if (mounted) setState(() => _runError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retry() async {
    final run = _run;
    if (run == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.runRepository.retry(run.id);
      await _refreshRun();
      _beginPolling();
    } catch (error) {
      if (mounted) setState(() => _runError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmAction(ExpertRunActionType actionType) async {
    final run = _run;
    if (run == null || _confirming) return;
    final action = _activeDeviceAction(run);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(actionType.label),
        content: _ActionConfirmBody(actionType: actionType, action: action),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _confirming = true);
    try {
      final idempotencyKey = const Uuid().v4();
      final confirmedAction = await widget.runRepository.confirmAction(
        runId: run.id,
        actionType: actionType,
        idempotencyKey: idempotencyKey,
        deviceId: action?.deviceId,
        deviceName: action?.deviceName,
        capability: action?.capability,
        targetValue: action?.targetValue,
        spaceName: action?.spaceName,
        actionTitle: action?.actionTitle,
        actionDescription: action?.actionDescription,
      );
      if (mounted) {
        setState(() {
          _run = _run?.copyWithAction(confirmedAction);
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('${actionType.label}已提交')));
      }
    } catch (error) {
      if (mounted) setState(() => _runError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  ExpertRunActionDto? _activeDeviceAction(ExpertRunDto run) {
    if (run.status != ExpertRunStatus.completed) return null;
    for (final action in run.actions) {
      if (action.isDeviceAction && action.status == 'pending') return action;
    }
    return null;
  }

  void _toggleAttachmentSelected(AttachmentDto file) {
    setState(() {
      if (_selectedAttachmentIds.contains(file.id)) {
        _selectedAttachmentIds.remove(file.id);
      } else {
        _selectedAttachmentIds.add(file.id);
      }
    });
  }

  Future<void> _pickExistingAttachments() async {
    try {
      final files = await widget.attachmentRepository.listFiles();
      if (!mounted) return;
      final selected = await showModalBottomSheet<Set<int>>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _PickExistingSheet(
          files: files,
          initiallySelected: _selectedAttachmentIds,
        ),
      );
      if (selected != null) {
        setState(
          () => _selectedAttachmentIds
            ..clear()
            ..addAll(selected),
        );
      }
    } on ApiException catch (error) {
      _showError(error.msg);
    } catch (_) {
      _showError('附件列表加载失败，请稍后重试。');
    }
  }

  Future<void> _uploadAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showError('未能读取文件内容，请重试。');
        return;
      }
      await widget.attachmentRepository.uploadFile(
        filename: file.name,
        bytes: bytes,
        mimeType: _guessMimeType(file.name),
      );
      if (!mounted) return;
      _reloadAttachments();
      _showError('已上传：${file.name}');
    } on ApiException catch (error) {
      _showError(error.msg);
    } catch (_) {
      _showError('文件上传失败，请稍后重试。');
    }
  }

  Future<void> _removeAttachment(AttachmentDto file) async {
    try {
      await widget.attachmentRepository.deleteFile(file.id);
      if (!mounted) return;
      _selectedAttachmentIds.remove(file.id);
      _reloadAttachments();
    } on ApiException catch (error) {
      _showError(error.msg);
    } catch (_) {
      _showError('附件删除失败，请稍后重试。');
    }
  }

  int? _generatedFileIdOf(ExpertRunDto run) {
    final result = run.result;
    if (result == null || result.isEmpty) return null;
    try {
      final json = jsonDecode(result);
      if (json is Map<String, dynamic>) {
        final value = json['generatedFileId'];
        return value is num ? value.toInt() : null;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _downloadGeneratedFile(int fileId) async {
    try {
      final bytes = await widget.attachmentRepository.downloadFile(fileId);
      if (!mounted) return;
      final path = await FilePicker.platform.saveFile(
        fileName: 'home-mind-ppt-${DateTime.now().millisecondsSinceEpoch}.pptx',
        bytes: bytes,
      );
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('已保存：$path')));
      }
    } catch (_) {
      if (mounted) _showError('文件下载失败，请稍后重试。');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Expert?>(
    future: _expert,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final expert = snapshot.data;
      if (snapshot.hasError || expert == null) {
        return Scaffold(
          appBar: AppBar(),
          body: _CatalogError(
            error: snapshot.hasError ? _messageFor(snapshot.error) : '未找到专家。',
            onRetry: () => setState(() => _expert = _loadExpert()),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(expert.name)),
        body: ListView(
          padding: NexusLayout.pagePadding.copyWith(
            top: 8,
            bottom: NexusLayout.bottomContentPadding,
          ),
          children: [
            _ExpertSummary(expert: expert),
            const SizedBox(height: NexusLayout.sectionGap),
            _AttachmentSurface(
              attachments: _attachments,
              selectedIds: _selectedAttachmentIds,
              onPickExisting: _pickExistingAttachments,
              onUpload: _uploadAttachment,
              onRemove: _removeAttachment,
              onToggleSelected: _toggleAttachmentSelected,
            ),
            const SizedBox(height: NexusLayout.sectionGap),
            if (_run == null)
              _RunComposer(
                controller: _input,
                submitting: _submitting,
                onSubmit: () => _start(expert),
              )
            else ...[
              _RunStatusCard(run: _run!),
              if (_run!.status == ExpertRunStatus.completed) ...[
                const SizedBox(height: NexusLayout.itemGap),
                _RunResultView(run: _run!),
                if (_generatedFileIdOf(_run!) case final fileId?) ...[
                  const SizedBox(height: NexusLayout.itemGap),
                  _GeneratedFileCard(
                    fileId: fileId,
                    onDownload: () => _downloadGeneratedFile(fileId),
                  ),
                ],
              ],
              const SizedBox(height: NexusLayout.itemGap),
              _RunTimeline(events: _events),
              if (_runError != null) ...[
                const SizedBox(height: NexusLayout.itemGap),
                _RunError(message: _runError!, onRetry: _refreshRun),
              ],
              const SizedBox(height: NexusLayout.itemGap),
              _RunActions(
                run: _run!,
                busy: _submitting || _confirming,
                onCancel: _cancel,
                onRetry: _retry,
                onConfirm: _confirmAction,
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({required this.expert, required this.onTap});

  final Expert expert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      child: NexusSurface(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
              ),
              child: Icon(
                expert.sourceType == ExpertSourceType.group
                    ? Icons.groups_rounded
                    : Icons.auto_awesome_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expert.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    expert.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${expert.category} · 预计 ${expert.estimatedCredits} 积分',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '家庭管家托管执行 · 仅 L3 行动需你确认',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ExpertSummary extends StatelessWidget {
  const _ExpertSummary({required this.expert});

  final Expert expert;

  @override
  Widget build(BuildContext context) => NexusSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本次协作', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(expert.description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10),
        Text(
          '分类：${expert.category} · 预计 ${expert.estimatedCredits} 积分',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text(
          '运行由家庭管家托管执行：L1 低风险自动确认，L2 建议你逐项确认，'
          'L3 需你逐项决定，行动可追溯。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _RunComposer extends StatelessWidget {
  const _RunComposer({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => NexusSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('告诉专家你的目标', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: NexusLayout.controlGap),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: '这次希望完成什么？',
            hintText: '例如：为本周安排一份更轻松的晚间计划。',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: NexusLayout.controlGap),
        FilledButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(submitting ? '正在提交…' : '开始分析'),
        ),
      ],
    ),
  );
}

class _RunStatusCard extends StatelessWidget {
  const _RunStatusCard({required this.run});

  final ExpertRunDto run;

  @override
  Widget build(BuildContext context) => NexusSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              run.status == ExpertRunStatus.completed
                  ? Icons.check_circle_outline_rounded
                  : Icons.timelapse_rounded,
              color: run.status == ExpertRunStatus.completed
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              run.status.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        if (run.resultSummary != null && run.resultSummary!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(run.resultSummary!),
        ],
        if (run.actualCredits != null || run.estimatedCredits != null) ...[
          const SizedBox(height: 10),
          Text(
            '积分：${run.actualCredits ?? run.estimatedCredits}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}

/// 运行结果视图：按 JSON 键存在性自适应渲染。
/// - 含 scenes 数组（视频脚本类专家）：渲染标题/钩子/场景时间轴；
/// - 否则按通用方案渲染：kind 标签、title、summary、sections、nextSteps；
/// - 解析失败回退为原始文本。
class _RunResultView extends StatelessWidget {
  const _RunResultView({required this.run});

  final ExpertRunDto run;

  @override
  Widget build(BuildContext context) {
    final result = run.result;
    if (result == null || result.isEmpty) return const SizedBox.shrink();
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(result);
      json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return NexusSurface(
        padding: const EdgeInsets.all(20),
        child: Text(result),
      );
    }
    final scenes = json['scenes'];
    if (scenes is List && scenes.isNotEmpty) {
      return _SceneResultView(json: json, scenes: scenes);
    }
    return _SectionResultView(json: json);
  }
}

class _SectionResultView extends StatelessWidget {
  const _SectionResultView({required this.json});

  final Map<String, dynamic> json;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = json['kind']?.toString();
    final title = json['title']?.toString();
    final summary = json['summary']?.toString();
    final sections = json['sections'];
    final nextSteps = json['nextSteps'];
    final label = switch (kind) {
      'morning_meeting' => '晨会方案',
      'study_session' => '课程设计',
      'activity' => '活动策划',
      'bp' => 'BP 框架',
      _ => null,
    };
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            _KindTag(label: label),
            const SizedBox(height: 10),
          ],
          if (title != null && title.isNotEmpty)
            Text(title, style: theme.textTheme.titleLarge),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(summary, style: theme.textTheme.bodyMedium),
          ],
          if (sections is List && sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...sections.whereType<Map>().map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section['heading']?.toString() ?? '',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(section['content']?.toString() ?? ''),
                  ],
                ),
              ),
            ),
          ],
          if (nextSteps is List && nextSteps.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('下一步', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            ...nextSteps.whereType<String>().map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(step)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SceneResultView extends StatelessWidget {
  const _SceneResultView({required this.json, required this.scenes});

  final Map<String, dynamic> json;
  final List<dynamic> scenes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = json['title']?.toString();
    final hook = json['hook']?.toString();
    final duration = json['durationSeconds'];
    final summary = json['summary']?.toString();
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Text(title, style: theme.textTheme.titleLarge),
          if (duration != null) ...[
            const SizedBox(height: 4),
            Text('时长：$duration 秒', style: theme.textTheme.bodySmall),
          ],
          if (hook != null && hook.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('钩子：$hook', style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 14),
          ...scenes.whereType<Map>().map(
            (scene) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '场景 ${scene['sceneNo'] ?? '?'}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scene['timeRange']?.toString() ?? '',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (scene['visual']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text('画面：${scene['visual']}'),
                  ],
                  if (scene['voiceover']?.toString().isNotEmpty == true)
                    Text('口播：${scene['voiceover']}'),
                  if (scene['note']?.toString().isNotEmpty == true)
                    Text(
                      '提示：${scene['note']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(summary, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _KindTag extends StatelessWidget {
  const _KindTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _GeneratedFileCard extends StatelessWidget {
  const _GeneratedFileCard({required this.fileId, required this.onDownload});

  final int fileId;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PPT 文件已生成', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('点击下载保存到本地', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded),
            label: const Text('下载'),
          ),
        ],
      ),
    );
  }
}

class _RunTimeline extends StatelessWidget {
  const _RunTimeline({required this.events});

  final List<ExpertRunEventDto> events;

  @override
  Widget build(BuildContext context) => NexusSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('运行进度', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (events.isEmpty)
          const Text('正在获取进度…')
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(event.displayText!)),
                  Text(
                    _clock(event.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  String _clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _RunActions extends StatelessWidget {
  const _RunActions({
    required this.run,
    required this.busy,
    required this.onCancel,
    required this.onRetry,
    required this.onConfirm,
  });

  final ExpertRunDto run;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final ValueChanged<ExpertRunActionType> onConfirm;

  @override
  Widget build(BuildContext context) {
    if (run.status == ExpertRunStatus.completed) {
      final hasDeviceAction = run.actions.any(
        (action) => action.isDeviceAction && action.status == 'pending',
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ExpertRunActionType.values
            .where(
              (type) => !hasDeviceAction
                  ? type != ExpertRunActionType.smartHomeDevices
                  : true,
            )
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: busy ? null : () => onConfirm(type),
                  child: Text(type.label),
                ),
              ),
            )
            .toList(),
      );
    }
    if (run.status == ExpertRunStatus.failed ||
        run.status == ExpertRunStatus.cancelled) {
      return OutlinedButton.icon(
        onPressed: busy ? null : onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('重新运行'),
      );
    }
    return OutlinedButton.icon(
      onPressed: busy ? null : onCancel,
      icon: const Icon(Icons.close_rounded),
      label: const Text('取消运行'),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  const _CatalogEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 48),
    child: Center(child: Text('暂时没有可用专家。')),
  );
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    ),
  );
}

class _RunError extends StatelessWidget {
  const _RunError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: () => onRetry(), child: const Text('重试')),
        ],
      ),
    ),
  );
}

class _ActionConfirmBody extends StatelessWidget {
  const _ActionConfirmBody({required this.actionType, required this.action});

  final ExpertRunActionType actionType;
  final ExpertRunActionDto? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (actionType != ExpertRunActionType.smartHomeDevices || action == null) {
      return Text('确认后将根据本次建议${actionType.label}，此操作会提交一次。');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('确认后将对以下设备执行操作：', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 10),
        _ActionRow(label: '空间', value: action!.spaceName),
        _ActionRow(label: '设备', value: action!.deviceName),
        _ActionRow(label: '能力', value: action!.capability),
        _ActionRow(
          label: '目标值',
          value: action!.targetValue == null ? '—' : '${action!.targetValue}',
        ),
        if (action!.actionDescription != null &&
            action!.actionDescription!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            action!.actionDescription!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label, required this.value});

  final String? label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label ?? '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value ?? '—', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

String _messageFor(Object? error) => error is ApiException
    ? error.msg
    : error?.toString().isNotEmpty == true
    ? '暂时无法完成，请稍后重试。'
    : '暂时无法完成，请稍后重试。';

String? _guessMimeType(String filename) {
  final ext = filename.contains('.')
      ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase()
      : '';
  return switch (ext) {
    'pdf' => 'application/pdf',
    'md' || 'markdown' => 'text/markdown',
    'txt' => 'text/plain',
    'json' => 'application/json',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    _ => null,
  };
}

class _AttachmentSurface extends StatelessWidget {
  const _AttachmentSurface({
    required this.attachments,
    required this.selectedIds,
    required this.onPickExisting,
    required this.onUpload,
    required this.onRemove,
    required this.onToggleSelected,
  });

  final Future<List<AttachmentDto>> attachments;
  final Set<int> selectedIds;
  final VoidCallback onPickExisting;
  final VoidCallback onUpload;
  final ValueChanged<AttachmentDto> onRemove;
  final ValueChanged<AttachmentDto> onToggleSelected;

  @override
  Widget build(BuildContext context) {
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('本次附件', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (selectedIds.isNotEmpty)
                Text(
                  '已选 ${selectedIds.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '选择已有文件或上传新文件，作为本次协作的上下文。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AttachmentDto>>(
            future: attachments,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('附件加载失败：${snapshot.error}'),
                );
              }
              final files = snapshot.data ?? const <AttachmentDto>[];
              if (files.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '还没有附件，先上传一个或选择已有文件。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return Column(
                children: files
                    .map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AttachmentTile(
                          file: file,
                          selected: selectedIds.contains(file.id),
                          onToggle: () => onToggleSelected(file),
                          onRemove: () => onRemove(file),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickExisting,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('选择已有'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('上传新文件'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.file,
    required this.selected,
    required this.onToggle,
    required this.onRemove,
  });

  final AttachmentDto file;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${file.displaySize}${file.mimeType != null ? ' · ${file.mimeType}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '删除附件',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickExistingSheet extends StatefulWidget {
  const _PickExistingSheet({
    required this.files,
    required this.initiallySelected,
  });

  final List<AttachmentDto> files;
  final Set<int> initiallySelected;

  @override
  State<_PickExistingSheet> createState() => _PickExistingSheetState();
}

class _PickExistingSheetState extends State<_PickExistingSheet> {
  late final Set<int> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择已有附件', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: widget.files
                    .map(
                      (file) => CheckboxListTile(
                        value: _selected.contains(file.id),
                        onChanged: (value) => setState(() {
                          if (value ?? false) {
                            _selected.add(file.id);
                          } else {
                            _selected.remove(file.id);
                          }
                        }),
                        title: Text(file.filename),
                        subtitle: Text(file.displaySize),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
