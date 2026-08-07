// B20 专家会话 HTTP：会话/消息游标分页、创建/更新/删除请求体、
// 发送消息幂等键、422/409 错误传递。

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/conversation/dto.dart';
import 'package:nexus_mind_mobile/features/conversation/http_conversation_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpConversationRepository conversations', () {
    test('listConversations sends cursor query and parses page', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Items': [
            {
              'Id': 5,
              'Title': '杭州周末行程',
              'ExpertId': 2,
              'ExpertVersionId': 21,
              'WorkspaceConnectorId': null,
              'CreatedAt': '2026-08-07T09:00:00Z',
              'UpdatedAt': '2026-08-07T09:30:00Z',
              'RowVersion': 1,
            },
          ],
          'Cursor': null,
        },
      ]);

      final page = await repository.listConversations(limit: 20);

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/conversations');
      expect(requests.single.queryParameters['limit'], 20);
      expect(requests.single.queryParameters.containsKey('cursor'), isFalse);
      expect(page.items, hasLength(1));
      final item = page.items.single;
      expect(item.id, 5);
      expect(item.title, '杭州周末行程');
      expect(item.expertId, 2);
      expect(item.expertVersionId, 21);
      expect(item.workspaceConnectorId, isNull);
      expect(item.rowVersion, 1);
      expect(page.cursor, isNull);
    });

    test('listConversations forwards cursor', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {'Items': <Object>[], 'Cursor': 'abc123'},
      ]);

      final page = await repository.listConversations(
        limit: 20,
        cursor: 'abc123',
      );

      expect(requests.single.queryParameters['cursor'], 'abc123');
      expect(page.cursor, 'abc123');
    });

    test('createConversation posts title and expertId', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Id': 6,
          'Title': '旅行计划',
          'ExpertId': 2,
          'ExpertVersionId': 21,
          'WorkspaceConnectorId': null,
          'CreatedAt': '2026-08-07T10:00:00Z',
          'UpdatedAt': '2026-08-07T10:00:00Z',
          'RowVersion': 1,
        },
      ]);

      final conversation = await repository.createConversation(
        title: '旅行计划',
        expertId: 2,
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/conversations');
      expect(requests.single.data, {'title': '旅行计划', 'expertId': 2});
      expect(conversation.id, 6);
    });

    test('createConversation without expertId keeps body minimal', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Id': 7,
          'Title': '未命名',
          'ExpertId': null,
          'ExpertVersionId': null,
          'WorkspaceConnectorId': null,
          'CreatedAt': '2026-08-07T10:00:00Z',
          'UpdatedAt': '2026-08-07T10:00:00Z',
          'RowVersion': 1,
        },
      ]);

      await repository.createConversation(title: '', expertId: null);

      expect(requests.single.data, isEmpty);
    });

    test(
      'updateConversation unbinds expert with null and sends rowVersion',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          {
            'Id': 5,
            'Title': '新标题',
            'ExpertId': null,
            'ExpertVersionId': null,
            'WorkspaceConnectorId': null,
            'CreatedAt': '2026-08-07T09:00:00Z',
            'UpdatedAt': '2026-08-07T10:00:00Z',
            'RowVersion': 2,
          },
        ]);

        final updated = await repository.updateConversation(
          id: 5,
          title: '新标题',
          expertId: null,
          rowVersion: 1,
        );

        expect(requests.single.method, 'PUT');
        expect(requests.single.path, '/conversations/5');
        expect(requests.single.data, {
          'title': '新标题',
          'expertId': null,
          'workspaceConnectorId': null,
          'rowVersion': 1,
        });
        expect(updated.rowVersion, 2);
      },
    );

    test('deleteConversation issues DELETE', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [null]);

      await repository.deleteConversation(5);

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/conversations/5');
    });

    test('propagates a 409 row-version conflict', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(
        requests,
        const [],
        code: 409,
        msg: '版本冲突',
      );

      await expectLater(
        repository.updateConversation(
          id: 5,
          title: '新标题',
          expertId: null,
          rowVersion: 1,
        ),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '版本冲突'),
        ),
      );
    });
  });

  group('HttpConversationRepository messages', () {
    test('listMessages parses history page', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Items': [
            {
              'Id': 101,
              'Role': 'user',
              'Content': '帮我规划周末去杭州',
              'RunId': 901,
              'CreatedAt': '2026-08-07T09:30:00Z',
            },
          ],
          'Cursor': null,
        },
      ]);

      final page = await repository.listMessages(conversationId: 5);

      expect(requests.single.path, '/conversations/5/messages');
      expect(page.items, hasLength(1));
      final message = page.items.single;
      expect(message.role, ConversationMessageRole.user);
      expect(message.content, '帮我规划周末去杭州');
      expect(message.runId, 901);
    });

    test(
      'sendMessage posts content and idempotencyKey, parses result',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          {'RunId': 901, 'Status': 'queued', 'MessageId': 101},
        ]);

        final result = await repository.sendMessage(
          conversationId: 5,
          content: '继续',
          idempotencyKey: '9c1f-uuid',
        );

        expect(requests.single.method, 'POST');
        expect(requests.single.path, '/conversations/5/messages');
        expect(requests.single.data, {
          'content': '继续',
          'idempotencyKey': '9c1f-uuid',
        });
        expect(result.runId, 901);
        expect(result.status, 'queued');
        expect(result.messageId, 101);
      },
    );

    test('propagates a 422 unbounded-expert rejection', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(
        requests,
        const [],
        code: 422,
        msg: '该会话尚未绑定专家',
      );

      await expectLater(
        repository.sendMessage(
          conversationId: 5,
          content: '你好',
          idempotencyKey: 'k',
        ),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '该会话尚未绑定专家'),
        ),
      );
    });
  });
}

Future<HttpConversationRepository> _repository(
  List<RequestOptions> requests,
  List<Object?> responses, {
  int code = 0,
  String msg = 'ok',
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
              'Msg': msg,
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpConversationRepository(api);
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
