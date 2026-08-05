import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/experts/domain.dart';
import 'package:nexus_mind_mobile/experts/expert_repository.dart';
import 'package:nexus_mind_mobile/features/auth/auth_controller.dart';
import 'package:nexus_mind_mobile/features/auth/http_auth_repository.dart';
import 'package:nexus_mind_mobile/features/calendar/calendar_repository.dart';
import 'package:nexus_mind_mobile/features/calendar/dto.dart';
import 'package:nexus_mind_mobile/features/smart_home/dto.dart';
import 'package:nexus_mind_mobile/features/smart_home/smart_home_repository.dart';
import 'package:nexus_mind_mobile/features/todo/dto.dart';
import 'package:nexus_mind_mobile/features/todo/todo_repository.dart';
import 'package:nexus_mind_mobile/pages/dashboard_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.now();

void main() {
  testWidgets(
    'keeps plan data available when the home card fails and retries it independently',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final env = await EnvConfig.init(
        fileValues: const {'API_BASE_URL': 'https://api.example.com'},
      );
      final smartHome = _RetryingSmartHomeRepo();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(
              value: await _signedInAuth(env),
            ),
            Provider<TodoRepository>.value(value: _StubTodoRepo()),
            Provider<CalendarRepository>.value(value: _StubCalendarRepo()),
            Provider<SmartHomeRepository>.value(value: smartHome),
            Provider<ExpertRepository>.value(value: _StubExpertRepo()),
          ],
          child: MaterialApp(
            theme: NexusTheme.light(NexusPalette.aiAccent),
            home: const NexusHomePage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('家庭状态暂时无法加载'), findsOneWidget);
      expect(find.text('今日计划'), findsOneWidget);
      expect(find.textContaining('更新于'), findsOneWidget);

      smartHome.shouldFail = false;
      await tester.tap(find.byTooltip('重试').first);
      await tester.pump();
      await tester.pump();

      expect(find.text('家庭状态暂时无法加载'), findsNothing);
      expect(find.textContaining('更新于'), findsNWidgets(2));
    },
  );
}

Future<AuthController> _signedInAuth(EnvConfig env) async {
  final storage = _MemTokens();
  final api = ApiClient(tokenStorage: storage, env: env);
  api.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'Code': 0,
              'Msg': 'ok',
              'Data': {'Id': 1, 'DisplayName': 'Tester'},
            },
          ),
        );
      },
    ),
  );
  final auth = AuthController(
    apiClient: api,
    tokenStorage: storage,
    repository: HttpAuthRepository(api),
  );
  storage.access = 'a';
  storage.refresh = 'r';
  api.setAccessToken('a');
  return auth;
}

class _StubTodoRepo implements TodoRepository {
  @override
  Future<List<TodoDto>> list({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async => [
    TodoDto(
      id: 1,
      title: '整理',
      status: TodoStatus.pending,
      pinned: false,
      sortOrder: 0,
      createdAt: _now,
      updatedAt: _now,
    ),
    TodoDto(
      id: 2,
      title: '确认',
      status: TodoStatus.pending,
      pinned: false,
      sortOrder: 0,
      createdAt: _now,
      updatedAt: _now,
    ),
  ];
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
  }) async => TodoDto(
    id: 3,
    title: title,
    status: TodoStatus.pending,
    pinned: false,
    sortOrder: 0,
    createdAt: _now,
    updatedAt: _now,
  );
  @override
  Future<TodoDto> update(int id, Map<String, dynamic> patch) async => TodoDto(
    id: id,
    title: '',
    status: TodoStatus.pending,
    pinned: false,
    sortOrder: 0,
    createdAt: _now,
    updatedAt: _now,
  );
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<SubtaskDto>> listSubtasks(int todoId) async => [];
  @override
  Future<SubtaskDto> addSubtask(
    int todoId, {
    required String text,
    int? seq,
  }) async => SubtaskDto(id: 1, text: text, done: false, seq: 0);
  @override
  Future<SubtaskDto> updateSubtask(
    int todoId,
    int subId,
    Map<String, dynamic> patch,
  ) async => SubtaskDto(id: subId, text: '', done: false, seq: 0);
  @override
  Future<void> deleteSubtask(int todoId, int subId) async {}
}

class _StubCalendarRepo implements CalendarRepository {
  @override
  Future<List<CalendarEventDto>> listEvents({
    DateTime? from,
    DateTime? to,
  }) async => [];
  @override
  Future<CalendarEventDto> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startAt,
    DateTime? endAt,
    String? timezone,
    bool? allDay,
    String? color,
    double? opacity,
    String? repeatRule,
  }) async => CalendarEventDto(
    id: 1,
    title: title,
    startAt: startAt,
    endAt: endAt,
    timezone: 'UTC',
    allDay: allDay ?? false,
    opacity: 1.0,
    createdAt: _now,
    updatedAt: _now,
  );
  @override
  Future<CalendarEventDto> updateEvent(
    int id,
    Map<String, dynamic> patch,
  ) async => CalendarEventDto(
    id: id,
    title: '',
    startAt: _now,
    endAt: _now,
    timezone: 'UTC',
    allDay: false,
    opacity: 1.0,
    createdAt: _now,
    updatedAt: _now,
  );
  @override
  Future<void> deleteEvent(int id) async {}
  @override
  Future<List<CalendarSubscriptionDto>> listSubscriptions() async => [];
  @override
  Future<CalendarSubscriptionDto> createSubscription({
    required String url,
    String? name,
    bool? enabled,
    int? refreshIntervalMin,
  }) async => CalendarSubscriptionDto(
    id: 1,
    name: name ?? url,
    enabled: enabled ?? true,
    refreshIntervalMin: refreshIntervalMin ?? 60,
    createdAt: _now,
  );
  @override
  Future<CalendarSubscriptionDto> updateSubscription(
    int id,
    Map<String, dynamic> patch,
  ) async => CalendarSubscriptionDto(
    id: id,
    name: '',
    enabled: false,
    refreshIntervalMin: 60,
    createdAt: _now,
  );
  @override
  Future<void> deleteSubscription(int id) async {}
}

class _StubExpertRepo implements ExpertRepository {
  @override
  Future<Expert?> getExpert(
    String id, {
    required ExpertSourceType sourceType,
  }) async => null;
  @override
  Future<List<Expert>> listExperts({String query = ''}) async => [];
}

class _MemTokens implements TokenStorage {
  String? access, refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }

  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }
}

class _RetryingSmartHomeRepo implements SmartHomeRepository {
  bool shouldFail = true;
  void _throw() {
    if (shouldFail) throw StateError('unavailable');
  }

  @override
  Future<List<SmartHomeSpaceDto>> listSpaces() async {
    _throw();
    return [
      SmartHomeSpaceDto(
        id: '1',
        name: '客厅',
        type: 'room',
        summary: '25°C',
        sortOrder: 0,
      ),
      SmartHomeSpaceDto(
        id: '2',
        name: '主卧',
        type: 'room',
        summary: '灯光开',
        sortOrder: 1,
      ),
    ];
  }

  @override
  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId}) async {
    _throw();
    return [];
  }

  @override
  Future<List<SmartSceneDto>> listScenes() async {
    _throw();
    return [
      SmartSceneDto(
        key: 'sleep',
        name: '睡眠',
        description: '',
        requiresConfirmation: true,
      ),
    ];
  }

  @override
  Future<SmartSceneDto> runScene(String key) async => SmartSceneDto(
    key: key,
    name: key,
    description: '',
    requiresConfirmation: true,
  );
}
