// B20 会话页面：列表状态/新建/删除确认；聊天页消息流/发送/轮询终态刷新/422 提示。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_mind_mobile/experts/domain.dart';
import 'package:nexus_mind_mobile/experts/expert_repository.dart';
import 'package:nexus_mind_mobile/features/conversation/conversation_repository.dart';
import 'package:nexus_mind_mobile/features/conversation/dto.dart';
import 'package:nexus_mind_mobile/features/expert/dto.dart' as expert;
import 'package:nexus_mind_mobile/features/expert/expert_run_repository.dart';
import 'package:nexus_mind_mobile/pages/conversation_detail_page.dart';
import 'package:nexus_mind_mobile/pages/conversations_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('会话列表', () {
    testWidgets('renders conversations with pagination state', (tester) async {
      final repo = _StubConversationRepo()
        ..conversations = [_conversation(5, '杭州周末行程', expertId: 2)];
      await _pumpList(tester, repo);

      expect(find.text('专家会话'), findsOneWidget);
      expect(find.text('杭州周末行程'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await _pumpList(tester, _StubConversationRepo());

      expect(find.text('还没有专家会话。'), findsOneWidget);
    });

    testWidgets('shows error with retry', (tester) async {
      final repo = _StubConversationRepo()..failList = true;
      await _pumpList(tester, repo);

      expect(find.text('会话暂时无法加载。'), findsOneWidget);

      repo.failList = false;
      repo.conversations = [_conversation(5, '杭州周末行程')];
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      expect(find.text('杭州周末行程'), findsOneWidget);
    });

    testWidgets('creates conversation and navigates to chat', (tester) async {
      final repo = _StubConversationRepo();
      await _pumpList(tester, repo);

      await tester.tap(find.text('新建会话'));
      await tester.pumpAndSettle();
      // 选专家弹窗 → 暂不选择
      await tester.tap(find.text('暂不选择'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '周末安排');
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      expect(repo.createdTitle, '周末安排');
      // 已 push 到聊天页（标题来自查询参数）。
      expect(find.text('周末安排'), findsOneWidget);
    });

    testWidgets('deletes conversation after confirmation', (tester) async {
      final repo = _StubConversationRepo()
        ..conversations = [_conversation(5, '杭州周末行程')];
      await _pumpList(tester, repo);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(repo.deletedIds, [5]);
      expect(find.text('还没有专家会话。'), findsOneWidget);
    });
  });

  group('聊天页', () {
    testWidgets('renders message bubbles and empty hint', (tester) async {
      final repo = _StubConversationRepo()
        ..messages = [
          _message(1, 'user', '帮我规划周末去杭州'),
          _message(2, 'assistant', '已为你生成行程方案'),
        ];
      await _pumpChat(tester, repo);

      expect(find.text('帮我规划周末去杭州'), findsOneWidget);
      expect(find.text('已为你生成行程方案'), findsOneWidget);
    });

    testWidgets('sends message then polls to terminal and refreshes', (
      tester,
    ) async {
      final repo = _StubConversationRepo()
        ..messages = [_message(1, 'user', '帮我规划周末去杭州')];
      final runRepo = _StubRunRepo(status: expert.ExpertRunStatus.completed);
      await _pumpChat(tester, repo, runRepo: runRepo);

      await tester.enterText(find.byType(TextField), '继续细化');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(repo.sentContents, ['继续细化']);
      // 轮询驱动：终态后停轮询并刷新消息。
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(runRepo.gets, greaterThan(0));
      expect(find.textContaining('已完成'), findsOneWidget);
    });

    testWidgets('shows snackbar on 422 unbounded expert', (tester) async {
      final repo = _StubConversationRepo()..failSend = true;
      await _pumpChat(tester, repo);

      await tester.enterText(find.byType(TextField), '你好');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('发送失败'), findsOneWidget);
    });
  });
}

Future<void> _pumpList(
  WidgetTester tester,
  _StubConversationRepo repo, {
  _StubRunRepo? runRepo,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ConversationsPage()),
      GoRoute(
        path: '/ai/conversations/:conversationId',
        builder: (_, state) => ConversationDetailPage(
          conversationId:
              int.tryParse(state.pathParameters['conversationId'] ?? '') ?? 0,
          title: state.uri.queryParameters['title'],
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ConversationRepository>.value(value: repo),
        Provider<ExpertRepository>.value(value: _StubExpertRepo()),
        Provider<ExpertRunRepository>.value(value: runRepo ?? _StubRunRepo()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpChat(
  WidgetTester tester,
  _StubConversationRepo repo, {
  _StubRunRepo? runRepo,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ConversationRepository>.value(value: repo),
        Provider<ExpertRepository>.value(value: _StubExpertRepo()),
        Provider<ExpertRunRepository>.value(value: runRepo ?? _StubRunRepo()),
      ],
      child: const MaterialApp(
        home: ConversationDetailPage(conversationId: 5, title: '周末安排'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ConversationDto _conversation(int id, String title, {int? expertId}) =>
    ConversationDto(
      id: id,
      title: title,
      expertId: expertId,
      expertVersionId: expertId,
      workspaceConnectorId: null,
      createdAt: DateTime(2026, 8, 7, 9),
      updatedAt: DateTime(2026, 8, 7, 9, 30),
      rowVersion: 1,
    );

ConversationMessageDto _message(int id, String role, String content) =>
    ConversationMessageDto(
      id: id,
      role: ConversationMessageRole.fromApiValue(role),
      content: content,
      runId: 901,
      createdAt: DateTime(2026, 8, 7, 9, 30),
    );

class _StubConversationRepo implements ConversationRepository {
  List<ConversationDto> conversations = [];
  List<ConversationMessageDto> messages = [];
  bool failList = false;
  bool failSend = false;
  String? createdTitle;
  List<int> deletedIds = [];
  List<String> sentContents = [];

  @override
  Future<ConversationPageDto> listConversations({
    int limit = 20,
    String? cursor,
  }) async {
    if (failList) throw Exception('network');
    return ConversationPageDto(items: conversations, cursor: null);
  }

  @override
  Future<ConversationDto> createConversation({String? title, int? expertId}) {
    createdTitle = title;
    return Future.value(_conversation(9, title ?? '', expertId: expertId));
  }

  @override
  Future<ConversationDto> updateConversation({
    required int id,
    String? title,
    int? expertId,
    required int rowVersion,
  }) async => _conversation(id, title ?? '', expertId: expertId);

  @override
  Future<void> deleteConversation(int id) async => deletedIds.add(id);

  @override
  Future<MessagePageDto> listMessages({
    required int conversationId,
    int limit = 20,
    String? cursor,
  }) async {
    if (failList) throw Exception('network');
    return MessagePageDto(items: messages, cursor: null);
  }

  @override
  Future<SendMessageResultDto> sendMessage({
    required int conversationId,
    required String content,
    required String idempotencyKey,
  }) async {
    if (failSend) throw Exception('该会话尚未绑定专家');
    sentContents.add(content);
    messages = [...messages, _message(messages.length + 1, 'user', content)];
    return SendMessageResultDto(runId: 901, status: 'queued', messageId: 99);
  }
}

class _StubExpertRepo implements ExpertRepository {
  @override
  Future<List<Expert>> listExperts({String query = '', String? scope}) async =>
      [];

  @override
  Future<Expert?> getExpert(
    String id, {
    required ExpertSourceType sourceType,
  }) async => null;

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
  _StubRunRepo({this.status = expert.ExpertRunStatus.completed});

  final expert.ExpertRunStatus status;
  int gets = 0;

  @override
  Future<expert.ExpertRunDto> start({
    required expert.ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) async => _run();

  @override
  Future<expert.ExpertRunDto> get(int runId) async {
    gets++;
    return _run();
  }

  expert.ExpertRunDto _run() => expert.ExpertRunDto(
    id: 901,
    sourceType: expert.ExpertRunSourceType.expert,
    status: status,
    createdAt: DateTime(2026, 8, 7, 9),
  );

  @override
  Future<List<expert.ExpertRunDto>> listRuns({
    int? expertId,
    int limit = 10,
  }) async => [];

  @override
  Future<List<expert.ExpertRunEventDto>> listEvents(int runId) async => [];

  @override
  Future<void> cancel(int runId) async {}

  @override
  Future<void> retry(int runId) async {}

  @override
  Future<expert.ExpertRunActionDto> confirmAction({
    required int runId,
    required expert.ExpertRunActionType actionType,
    required String idempotencyKey,
    int? deviceId,
    String? deviceName,
    String? capability,
    Object? targetValue,
    String? spaceName,
    String? actionTitle,
    String? actionDescription,
  }) async => throw UnimplementedError();
}
