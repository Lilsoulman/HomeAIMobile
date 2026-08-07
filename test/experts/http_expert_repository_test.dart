// B21 自建专家 HTTP：scope 参数透传、create/update/delete 请求体、
// ExpertDetailDto 映射（含 RowVersion 可空）、409 错误传递。

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/experts/domain.dart';
import 'package:nexus_mind_mobile/features/expert/http_expert_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpExpertRepository B21', () {
    test('listExperts forwards scope=mine and parses Source', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        [
          {
            'Id': 3,
            'CatalogType': 'expert',
            'Source': 'mine',
            'Code': 'custom-a1b2c3d4',
            'Name': '我的助手',
            'Category': 'travel',
            'Description': '…',
            'EstimatedCredits': 1,
          },
        ],
      ]);

      final experts = await repository.listExperts(scope: 'mine');

      expect(requests.single.path, '/experts');
      expect(requests.single.queryParameters['scope'], 'mine');
      expect(experts, hasLength(1));
      expect(experts.single.source, ExpertSource.mine);
    });

    test('listExperts omits scope when null', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [<Object>[]]);

      await repository.listExperts();

      expect(requests.single.queryParameters.containsKey('scope'), isFalse);
    });

    test('getExpertDetail maps B21 fields with rowVersion nullable', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Id': 3,
          'Code': 'custom-a1b2c3d4',
          'Name': '我的助手',
          'Category': 'travel',
          'Description': '…',
          'Source': 'mine',
          'VersionId': 4,
          'Version': 2,
          'Persona': '你是我的旅行助手…',
          'Methodology': '分步给出方案',
          'PromptTemplate': '请按模板回答',
          'ToolPolicy': '{"skills":[]}',
          'OutputSchema': '{"type":"object"}',
          'EstimatedCredits': 1,
        },
      ]);

      final detail = await repository.getExpertDetail(
        '3',
        sourceType: ExpertSourceType.expert,
      );

      expect(requests.single.path, '/experts/3');
      expect(detail, isNotNull);
      expect(detail!.source, ExpertSource.mine);
      expect(detail.persona, '你是我的旅行助手…');
      expect(detail.methodology, '分步给出方案');
      expect(detail.promptTemplate, '请按模板回答');
      expect(detail.toolPolicy, '{"skills":[]}');
      expect(detail.version, 2);
      expect(detail.versionId, 4);
      expect(detail.rowVersion, isNull); // 详情未列 RowVersion 时不猜测
    });

    test('createExpert posts full body and parses 201', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Id': 3,
          'Code': 'custom-a1b2c3d4',
          'Name': '我的助手',
          'Category': 'travel',
          'Source': 'mine',
          'Version': 1,
          'EstimatedCredits': 1,
        },
      ]);

      final expert = await repository.createExpert(
        name: '我的助手',
        category: 'travel',
        persona: '你是我的旅行助手…',
        promptTemplate: '请按模板回答',
        estimatedCredits: 1,
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/experts');
      expect(requests.single.data, {
        'name': '我的助手',
        'category': 'travel',
        'persona': '你是我的旅行助手…',
        'promptTemplate': '请按模板回答',
        'toolPolicyJson': '{"skills":[]}',
        'estimatedCredits': 1,
      });
      expect(expert.id, '3');
      expect(expert.source, ExpertSource.mine);
      expect(expert.sourceType, ExpertSourceType.expert);
    });

    test('updateExpert sends rowVersion and 409 propagates', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, const [], code: 409);

      await expectLater(
        repository.updateExpert(
          id: '3',
          rowVersion: 2,
          name: '新名字',
          category: 'travel',
          persona: 'p',
          promptTemplate: 't',
        ),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '版本冲突'),
        ),
      );

      expect(requests.single.method, 'PUT');
      expect(requests.single.path, '/experts/3');
      expect(requests.single.data['rowVersion'], 2);
    });

    test('deleteExpert issues DELETE', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [null]);

      await repository.deleteExpert('3');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/experts/3');
    });
  });
}

Future<HttpExpertRepository> _repository(
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
              'Msg': code == 0 ? 'ok' : '版本冲突',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpExpertRepository(api);
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
