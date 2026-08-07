import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/experts/domain.dart';
import 'package:nexus_mind_mobile/experts/expert_repository.dart';
import 'package:nexus_mind_mobile/features/attachment/attachment_repository.dart';
import 'package:nexus_mind_mobile/features/attachment/dto.dart';
import 'package:nexus_mind_mobile/features/expert/dto.dart';
import 'package:nexus_mind_mobile/features/expert/expert_run_repository.dart';
import 'package:nexus_mind_mobile/pages/expert_workbench_page.dart';

const _testViewSize = Size(430, 932);

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = _testViewSize;
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    FilePicker.platform = _FakeFilePicker(result: null);
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('a completed run requires confirmation before creating a todo', (
    tester,
  ) async {
    final runRepo = _StubRunRepo(
      ExpertRunDto(
        id: 1,
        sourceType: ExpertRunSourceType.expert,
        status: ExpertRunStatus.completed,
        createdAt: DateTime(2026),
        resultSummary: 'ok',
        estimatedCredits: 1,
        actions: [
          ExpertRunActionDto(
            id: 11,
            status: 'pending',
            actionType: ExpertRunActionType.todos,
            actionTitle: '创建任务',
            actionDescription: '建立今晚的待办',
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: _StubExpertRepo(),
          runRepository: runRepo,
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
    final runRepo = _ConfirmingRunRepo(
      ExpertRunDto(
        id: 1,
        sourceType: ExpertRunSourceType.expert,
        status: ExpertRunStatus.completed,
        createdAt: DateTime(2026),
        resultSummary: 'ok',
        estimatedCredits: 1,
        actions: [
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
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: _StubExpertRepo(),
          runRepository: runRepo,
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
    // 确认进行中：按钮仍在但已禁用，防止重复提交
    expect(tester.widget<OutlinedButton>(deviceButton).onPressed, isNull);
    runRepo.completePending();
    await tester.pumpAndSettle();
    expect(find.text('设备行动已提交'), findsOneWidget);
  });

  testWidgets('workspace lists attachments and toggles selection', (
    tester,
  ) async {
    final capturedInputs = <String>[];
    final runRepo = _CapturingRunRepo(
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
          repository: _StubExpertRepo(),
          runRepository: runRepo,
          attachmentRepository: _StubAttachmentRepository(),
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

  testWidgets('uploading a new file adds it to the workspace list', (
    tester,
  ) async {
    FilePicker.platform = _FakeFilePicker(
      result: FilePickerResult([
        PlatformFile(
          name: '新笔记.md',
          size: 6,
          bytes: Uint8List.fromList('abc123'.codeUnits),
        ),
      ]),
    );
    final attachments = _StubAttachmentRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: _StubExpertRepo(),
          runRepository: _CapturingRunRepo(
            onStart: (inputJson) => ExpertRunDto(
              id: 1,
              sourceType: ExpertRunSourceType.expert,
              status: ExpertRunStatus.queued,
              createdAt: DateTime(2026),
            ),
          ),
          attachmentRepository: attachments,
          expertId: '1',
          sourceType: ExpertSourceType.expert,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('上传新文件'));
    await tester.pumpAndSettle();

    expect(attachments.uploaded, hasLength(1));
    expect(attachments.uploaded.single.filename, '新笔记.md');
    expect(attachments.uploaded.single.mimeType, 'text/markdown');
    expect(find.text('新笔记.md'), findsOneWidget);
    expect(find.text('已上传：新笔记.md'), findsOneWidget);
  });

  testWidgets('picking existing files via the bottom sheet updates selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: _StubExpertRepo(),
          runRepository: _CapturingRunRepo(
            onStart: (inputJson) => ExpertRunDto(
              id: 1,
              sourceType: ExpertRunSourceType.expert,
              status: ExpertRunStatus.queued,
              createdAt: DateTime(2026),
            ),
          ),
          attachmentRepository: _StubAttachmentRepository(),
          expertId: '1',
          sourceType: ExpertSourceType.expert,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('选择已有'));
    await tester.pumpAndSettle();
    expect(find.text('选择已有附件'), findsOneWidget);

    await tester.tap(find.widgetWithText(CheckboxListTile, '设备清单.md'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('已选 1'), findsOneWidget);
  });

  testWidgets('removing an attachment deletes it and clears selection', (
    tester,
  ) async {
    final attachments = _StubAttachmentRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertWorkspacePage(
          repository: _StubExpertRepo(),
          runRepository: _CapturingRunRepo(
            onStart: (inputJson) => ExpertRunDto(
              id: 1,
              sourceType: ExpertRunSourceType.expert,
              status: ExpertRunStatus.queued,
              createdAt: DateTime(2026),
            ),
          ),
          attachmentRepository: attachments,
          expertId: '1',
          sourceType: ExpertSourceType.expert,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('本周计划.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('已选 1'), findsOneWidget);

    await tester.tap(find.byTooltip('删除附件').first);
    await tester.pumpAndSettle();

    expect(attachments.deletedIds, [1]);
    expect(find.text('本周计划.pdf'), findsNothing);
    expect(find.text('已选 1'), findsNothing);
  });
}

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker({required this.result});

  final FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => result;
}

class _StubExpertRepo implements ExpertRepository {
  @override
  Future<Expert?> getExpert(
    String id, {
    required ExpertSourceType sourceType,
  }) async => Expert(
    id: id,
    sourceType: sourceType,
    name: '家庭管家',
    category: 'household',
    description: '',
    estimatedCredits: 0,
  );

  @override
  Future<List<Expert>> listExperts({String query = '', String? scope}) async =>
      [];

  @override
  Future<ExpertDetail?> getExpertDetail(
    String id, {
    required ExpertSourceType sourceType,
  }) async => null;

  @override
  Future<Expert> createExpert({
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  }) async => throw UnimplementedError();

  @override
  Future<Expert> updateExpert({
    required String id,
    required int rowVersion,
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteExpert(String id) async {}
}

class _StubRunRepo implements ExpertRunRepository {
  _StubRunRepo(this._run);
  final ExpertRunDto _run;

  @override
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) async => _run;
  @override
  Future<ExpertRunDto> get(int runId) async => _run;
  @override
  Future<List<ExpertRunDto>> listRuns({int? expertId, int limit = 10}) async =>
      [];
  @override
  Future<List<ExpertRunEventDto>> listEvents(int runId) async => [];
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
  }) async =>
      ExpertRunActionDto(id: 99, status: 'completed', actionType: actionType);
}

class _ConfirmingRunRepo implements ExpertRunRepository {
  _ConfirmingRunRepo(this._run);
  final ExpertRunDto _run;
  final List<String> keys = [];
  Completer<ExpertRunActionDto>? _pending;
  ExpertRunActionType? _pendingActionType;

  /// 完成当前挂起的确认，模拟服务端返回确认结果。
  void completePending() {
    final pending = _pending;
    final actionType = _pendingActionType;
    _pending = null;
    _pendingActionType = null;
    pending?.complete(
      ExpertRunActionDto(id: 99, status: 'completed', actionType: actionType!),
    );
  }

  @override
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) async => _run;
  @override
  Future<ExpertRunDto> get(int runId) async => _run;
  @override
  Future<List<ExpertRunDto>> listRuns({int? expertId, int limit = 10}) async =>
      [];
  @override
  Future<List<ExpertRunEventDto>> listEvents(int runId) async => [];
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
    keys.add(idempotencyKey);
    _pendingActionType = actionType;
    final completer = Completer<ExpertRunActionDto>();
    _pending = completer;
    return completer.future;
  }
}

class _CapturingRunRepo implements ExpertRunRepository {
  _CapturingRunRepo({required this.onStart});
  final ExpertRunDto Function(String) onStart;

  @override
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) async => onStart(inputJson);
  @override
  Future<ExpertRunDto> get(int runId) async => ExpertRunDto(
    id: runId,
    sourceType: ExpertRunSourceType.expert,
    status: ExpertRunStatus.queued,
    createdAt: DateTime(2026),
  );
  @override
  Future<List<ExpertRunDto>> listRuns({int? expertId, int limit = 10}) async =>
      [];
  @override
  Future<List<ExpertRunEventDto>> listEvents(int runId) async => [];
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
  }) async =>
      ExpertRunActionDto(id: 0, status: 'completed', actionType: actionType);
}

class _StubAttachmentRepository implements AttachmentRepository {
  final List<AttachmentDto> _files = [
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
  final List<AttachmentDto> uploaded = [];
  final List<int> deletedIds = [];

  @override
  Future<List<AttachmentDto>> listFiles() async => List.of(_files);

  @override
  Future<AttachmentDto> uploadFile({
    required String filename,
    required Uint8List bytes,
    String? mimeType,
    String? role,
  }) async {
    final file = AttachmentDto(
      id: 99,
      filename: filename,
      sizeBytes: bytes.length,
      mimeType: mimeType,
      role: role,
      createdAt: DateTime.now(),
    );
    uploaded.add(file);
    _files.add(file);
    return file;
  }

  @override
  Future<Uint8List> downloadFile(int id) async => Uint8List(0);

  @override
  Future<AttachmentDto> deleteFile(int id) async {
    deletedIds.add(id);
    _files.removeWhere((file) => file.id == id);
    return AttachmentDto(
      id: id,
      filename: '',
      sizeBytes: 0,
      createdAt: DateTime.now(),
    );
  }
}
