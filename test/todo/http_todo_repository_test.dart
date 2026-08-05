import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/todo/dto.dart';
import 'package:nexus_mind_mobile/features/todo/http_todo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpTodoRepository', () {
    test('maps Todo endpoints and preserves request fields', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        [_todoJson()],
        _todoJson(),
        _todoJson(status: 'completed'),
        [
          {'id': 8, 'text': 'Pick up milk', 'done': true, 'seq': 1},
        ],
        {'id': 9, 'text': 'Open the door', 'done': 0, 'seq': 2},
        {'id': 9, 'text': 'Open the door', 'done': 1, 'seq': 3},
        null,
        null,
      ]);
      final from = DateTime.utc(2026, 8, 1);
      final to = DateTime.utc(2026, 8, 2);

      final todos = await repository.list(
        status: 'pending',
        from: from,
        to: to,
      );
      final created = await repository.create(
        title: 'Buy milk',
        description: 'low-fat',
        type: 'shopping',
        priority: 'p1',
        color: '#ff8800',
        status: 'pending',
        dueAt: to,
        remindAt: from,
        pinned: true,
        sortOrder: 10,
        repeatRule: 'FREQ=DAILY',
        parentId: 3,
      );
      final updated = await repository.update(1, {
        'type': 'task',
        'sortOrder': 11,
        'parentId': 4,
      });
      final subtasks = await repository.listSubtasks(1);
      final added = await repository.addSubtask(
        1,
        text: 'Open the door',
        seq: 2,
      );
      final changed = await repository.updateSubtask(1, 9, {
        'done': true,
        'seq': 3,
      });
      await repository.delete(1);
      await repository.deleteSubtask(1, 9);

      expect(todos.single.status, TodoStatus.pending);
      expect(created.id, 1);
      expect(updated.status, TodoStatus.completed);
      expect(subtasks.single.done, isTrue);
      expect(added.done, isFalse);
      expect(changed.done, isTrue);
      expect(requests.map((request) => request.path), [
        '/todos',
        '/todos',
        '/todos/1',
        '/todos/1/subtasks',
        '/todos/1/subtasks',
        '/todos/1/subtasks/9',
        '/todos/1',
        '/todos/1/subtasks/9',
      ]);
      expect(requests.first.queryParameters, {
        'status': 'pending',
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      });
      expect(requests[1].data, containsPair('parentId', 3));
      expect(requests[2].data, {
        'type': 'task',
        'sortOrder': 11,
        'parentId': 4,
      });
      expect(requests[5].data, {'done': true, 'seq': 3});
    });

    test(
      'propagates an API failure without converting it to empty data',
      () async {
        final repository = await _repository(
          <RequestOptions>[],
          const [],
          code: 422,
        );

        await expectLater(
          repository.list(),
          throwsA(
            isA<ApiException>().having((error) => error.msg, 'msg', '无效任务'),
          ),
        );
      },
    );
  });
}

Map<String, dynamic> _todoJson({String status = 'pending'}) => {
  'Id': 1,
  'Title': 'Buy milk',
  'Description': 'low-fat',
  'Type': 'shopping',
  'Priority': 'p1',
  'Color': '#ff8800',
  'Status': status,
  'DueAt': '2026-08-02T09:00:00Z',
  'RemindAt': '2026-08-02T08:30:00Z',
  'CompletedAt': null,
  'Pinned': true,
  'SortOrder': 10,
  'RepeatRule': null,
  'CreatedAt': '2026-08-01T03:11:22Z',
  'UpdatedAt': '2026-08-02T03:11:22Z',
};

Future<HttpTodoRepository> _repository(
  List<RequestOptions> requests,
  List<Object?> responses, {
  int code = 0,
}) async {
  SharedPreferences.setMockInitialValues({});
  final api = ApiClient(
    tokenStorage: _MemoryTokens(),
    env: await EnvConfig.init(),
  );
  api.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: {
              'Code': code,
              'Msg': code == 0 ? 'ok' : '无效任务',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpTodoRepository(api);
}

class _MemoryTokens implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {}
}
