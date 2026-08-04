import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/experts/domain.dart';
import 'package:nexus_mind_mobile/experts/mock_expert_repository.dart';
import 'package:nexus_mind_mobile/features/attachment/attachment_repository.dart';
import 'package:nexus_mind_mobile/features/attachment/dto.dart';
import 'package:nexus_mind_mobile/features/expert/dto.dart';
import 'package:nexus_mind_mobile/features/expert/expert_run_repository.dart';
import 'package:nexus_mind_mobile/features/expert/local_expert_run_repository.dart';
import 'package:nexus_mind_mobile/pages/expert_workbench_page.dart';

void main() {
  testWidgets('a completed run requires confirmation before creating a todo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: MockExpertRepository(),
          runRepository: LocalExpertRunRepository(),
          attachmentRepository: _StubAttachmentRepository(),
          expertId: '1',
          sourceType: ExpertSourceType.expert,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Create a lighter evening');
    await tester.tap(find.text('开始分析'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final createTask = find.widgetWithText(OutlinedButton, '创建任务');
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(createTask);
    await tester.pumpAndSettle();
    expect(find.text('确认'), findsOneWidget);

    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(find.text('创建任务已提交'), findsOneWidget);
  });

  testWidgets('device action shows its details and cannot be submitted twice', (
    tester,
  ) async {
    final runRepository = _DeviceRunRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: MockExpertRepository(),
          runRepository: runRepository,
          attachmentRepository: _StubAttachmentRepository(),
          expertId: '1',
          sourceType: ExpertSourceType.expert,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Prepare the home for sleep',
    );
    await tester.tap(find.text('开始分析'));
    await tester.pumpAndSettle();

    final deviceButton = find.widgetWithText(OutlinedButton, '设备行动');
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(deviceButton);
    await tester.pumpAndSettle();

    expect(find.text('空间'), findsOneWidget);
    expect(find.text('设备'), findsOneWidget);
    expect(find.text('能力'), findsOneWidget);
    expect(find.text('目标值'), findsOneWidget);
    expect(find.text('主卧'), findsOneWidget);
    expect(find.text('卧室主灯'), findsOneWidget);
    expect(find.text('power'), findsOneWidget);
    expect(find.text('false'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    expect(tester.widget<OutlinedButton>(deviceButton).onPressed, isNull);

    runRepository.completeConfirmation();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '设备行动'), findsNothing);

    final todoButton = find.widgetWithText(OutlinedButton, '创建任务');
    await tester.tap(todoButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    runRepository.completeConfirmation();
    await tester.pumpAndSettle();

    await tester.tap(todoButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    runRepository.completeConfirmation();
    await tester.pumpAndSettle();

    expect(runRepository.confirmationKeys, hasLength(3));
    expect(runRepository.confirmationKeys.toSet(), hasLength(3));
  });

  testWidgets('workspace lists attachments and toggles selection', (
    tester,
  ) async {
    final attachmentRepository = _StubAttachmentRepository();
    final capturedInputs = <String>[];
    final runRepository = _CapturingRunRepository(
      onStart: (inputJson) {
        capturedInputs.add(inputJson);
        return ExpertRunDto(
          id: 1,
          sourceType: ExpertRunSourceType.expert,
          status: ExpertRunStatus.queued,
          createdAt: DateTime(2026),
          inputJson: inputJson,
        );
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: MockExpertRepository(),
          runRepository: runRepository,
          attachmentRepository: attachmentRepository,
          expertId: '1',
          sourceType: ExpertSourceType.expert,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本次附件'), findsOneWidget);
    expect(find.text('本周计划.pdf'), findsOneWidget);

    await tester.tap(find.text('本周计划.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('已选 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '结合资料夹整理今晚');
    await tester.tap(find.text('开始分析'));
    await tester.pump();

    expect(capturedInputs, hasLength(1));
    final decoded = jsonDecode(capturedInputs.single) as Map<String, dynamic>;
    expect(decoded['request'], '结合资料夹整理今晚');
    expect(decoded['fileRefs'], hasLength(1));
    expect(decoded['fileRefs'].first, {'id': 1, 'role': 'context'});
  });
}

class _DeviceRunRepository implements ExpertRunRepository {
  final List<String> confirmationKeys = [];
  Completer<ExpertRunActionDto>? _pendingConfirmation;
  ExpertRunActionType? _pendingActionType;

  @override
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) async => _run(ExpertRunStatus.queued);

  @override
  Future<ExpertRunDto> get(int runId) async => _run(ExpertRunStatus.completed);

  @override
  Future<List<ExpertRunEventDto>> listEvents(int runId) async => const [];

  @override
  Future<void> cancel(int runId) async {}

  @override
  Future<void> retry(int runId) async {}

  @override
  Future<ExpertRunActionDto> confirmAction({
    required int runId,
    required ExpertRunActionType actionType,
    required String idempotencyKey,
    int? deviceId,
    String? deviceName,
    String? capability,
    Object? targetValue,
    String? spaceName,
    String? actionTitle,
    String? actionDescription,
  }) {
    confirmationKeys.add(idempotencyKey);
    _pendingActionType = actionType;
    final completer = Completer<ExpertRunActionDto>();
    _pendingConfirmation = completer;
    return completer.future;
  }

  void completeConfirmation() {
    final completer = _pendingConfirmation;
    final actionType = _pendingActionType;
    if (completer == null || actionType == null || completer.isCompleted) {
      return;
    }
    completer.complete(
      ExpertRunActionDto(
        id: actionType == ExpertRunActionType.smartHomeDevices ? 78 : 0,
        status: 'completed',
        actionType: actionType,
      ),
    );
    _pendingConfirmation = null;
    _pendingActionType = null;
  }

  ExpertRunDto _run(ExpertRunStatus status) => ExpertRunDto(
    id: 1,
    sourceType: ExpertRunSourceType.expert,
    status: status,
    resultSummary: 'A confirmable household recommendation is ready.',
    estimatedCredits: 1,
    actualCredits: 1,
    createdAt: DateTime(2026),
    mode: 'single',
    inputJson: '{}',
    actions: const [
      ExpertRunActionDto(
        id: 78,
        status: 'pending',
        actionType: ExpertRunActionType.smartHomeDevices,
        deviceId: 34,
        deviceName: '卧室主灯',
        capability: 'power',
        targetValue: false,
        spaceName: '主卧',
        actionTitle: '关闭卧室照明',
        actionDescription: '睡眠准备建议关闭卧室照明。',
      ),
    ],
  );
}

class _StubAttachmentRepository implements AttachmentRepository {
  @override
  Future<AttachmentDto> deleteFile(int id) async {
    final remaining = await listFiles();
    remaining.removeWhere((file) => file.id == id);
    return AttachmentDto(
      id: id,
      filename: '',
      sizeBytes: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<AttachmentDto>> listFiles() async => [
    AttachmentDto(
      id: 1,
      filename: '本周计划.pdf',
      sizeBytes: 2048,
      mimeType: 'application/pdf',
      role: 'context',
      createdAt: DateTime(2026, 8, 4, 9),
    ),
    AttachmentDto(
      id: 2,
      filename: '设备清单.md',
      sizeBytes: 512,
      mimeType: 'text/markdown',
      role: 'reference',
      createdAt: DateTime(2026, 8, 4, 8),
    ),
  ];

  @override
  Future<AttachmentDto> uploadFile({
    required String filename,
    required Uint8List bytes,
    String? mimeType,
    String? role,
  }) async {
    return AttachmentDto(
      id: DateTime.now().millisecondsSinceEpoch,
      filename: filename,
      sizeBytes: bytes.length,
      mimeType: mimeType,
      role: role,
      createdAt: DateTime.now(),
    );
  }
}

class _CapturingRunRepository implements ExpertRunRepository {
  _CapturingRunRepository({required this.onStart});
  final ExpertRunDto Function(String inputJson) onStart;
  final List<String> startedInputs = [];

  @override
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) async {
    startedInputs.add(inputJson);
    return onStart(inputJson);
  }

  @override
  Future<ExpertRunDto> get(int runId) async => ExpertRunDto(
    id: runId,
    sourceType: ExpertRunSourceType.expert,
    status: ExpertRunStatus.queued,
    createdAt: DateTime(2026),
  );

  @override
  Future<List<ExpertRunEventDto>> listEvents(int runId) async => const [];

  @override
  Future<void> cancel(int runId) async {}

  @override
  Future<void> retry(int runId) async {}

  @override
  Future<ExpertRunActionDto> confirmAction({
    required int runId,
    required ExpertRunActionType actionType,
    required String idempotencyKey,
    int? deviceId,
    String? deviceName,
    String? capability,
    Object? targetValue,
    String? spaceName,
    String? actionTitle,
    String? actionDescription,
  }) async {
    return ExpertRunActionDto(
      id: 0,
      status: 'completed',
      actionType: actionType,
    );
  }
}
