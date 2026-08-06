import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/family/http_family_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpFamilyRepository', () {
    test(
      'maps member and knowledge endpoints with PascalCase fields',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          [_memberJson()],
          _memberJson(),
          _memberJson(),
          _memberJson(),
          [_knowledgeJson()],
          {'Knowledge': _knowledgeJson()},
          null,
          {
            'Items': [_decisionJson()],
            'Cursor': null,
          },
          _decisionJson(),
        ]);

        final members = await repository.listMembers();
        final created = await repository.createMember(
          name: '外婆',
          relation: '外祖母',
          birthday: DateTime.utc(1950, 1, 1),
          isElderly: true,
          memberStatus: 'active',
        );
        await repository.updateMember(1, {'name': '外婆 2', 'isChild': true});
        await repository.correctMember(
          1,
          memberStatus: 'permanently_left',
          reason: '迁居',
        );

        final knowledge = await repository.listKnowledge(category: 'wifi');
        final written = await repository.writeKnowledge(
          category: 'wifi',
          key: 'router',
          value: 'tp-link',
          confidenceScore: 0.9,
        );
        await repository.deleteKnowledge(7);

        final page = await repository.listDecisions(limit: 20);
        final decision = await repository.recordDecision(
          scenario: '装修',
          decisionMade: '采用方案 B',
        );

        expect(members, hasLength(1));
        expect(members.single.isElderly, isTrue);
        expect(created.id, 1);
        expect(knowledge.single.sourceType, 'member');
        expect(written.knowledge.key, 'router');
        expect(written.resolution, isNull);
        expect(page.items, hasLength(1));
        expect(decision.scenario, '装修');

        expect(requests.map((request) => request.path), [
          '/homes/1234/members',
          '/homes/1234/members',
          '/homes/1234/members/1',
          '/homes/1234/members/1/correction',
          '/homes/1234/knowledge',
          '/homes/1234/knowledge',
          '/homes/1234/knowledge/7',
          '/homes/1234/decisions',
          '/homes/1234/decisions',
        ]);
        expect(requests[1].data, {
          'name': '外婆',
          'relation': '外祖母',
          'birthday': '1950-01-01T00:00:00.000Z',
          'isElderly': true,
          'memberStatus': 'active',
        });
        expect(requests[3].data, {
          'memberStatus': 'permanently_left',
          'reason': '迁居',
        });
        expect(requests[4].queryParameters, {'category': 'wifi'});
        expect(requests[7].queryParameters, {'limit': 20});
      },
    );

    test('maps knowledge conflict resolution summary', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Knowledge': _knowledgeJson(),
          'Resolution': {
            'KnowledgeId': 7,
            'ConflictKey': 'router',
            'Strategy': 'latest',
            'ResolutionSummary': '以最新写入为准',
            'ConflictingIds': [1, 2],
          },
        },
      ]);

      final written = await repository.writeKnowledge(
        category: 'wifi',
        key: 'router',
        value: 'tp-link',
      );

      expect(written.resolution, isNotNull);
      expect(written.resolution!.strategy, 'latest');
      expect(written.resolution!.conflictingIds, [1, 2]);
    });

    test('propagates a 422 API failure', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, const [], code: 422);

      await expectLater(
        repository.listMembers(),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '无效请求'),
        ),
      );
    });
  });
}

Map<String, dynamic> _memberJson() => {
  'Id': 1,
  'Name': '外婆',
  'Relation': '外祖母',
  'Birthday': '1950-01-01T00:00:00Z',
  'IsElderly': true,
  'IsChild': false,
  'IsPrimary': false,
  'MemberStatus': 'active',
  'Preferences': null,
  'CreatedAt': '2026-08-05T10:00:00Z',
  'UpdatedAt': '2026-08-05T10:00:00Z',
};

Map<String, dynamic> _knowledgeJson() => {
  'Id': 7,
  'Category': 'wifi',
  'Key': 'router',
  'Value': 'tp-link',
  'Notes': null,
  'SourceType': 'member',
  'SourceMemberId': 1,
  'ConfidenceScore': 0.9,
  'ConflictResolutionStrategy': 'latest',
  'ResolutionSummary': null,
  'CreatedAt': '2026-08-05T10:00:00Z',
  'UpdatedAt': '2026-08-05T10:00:00Z',
};

Map<String, dynamic> _decisionJson() => {
  'Id': 3,
  'Scenario': '装修',
  'DecisionMade': '采用方案 B',
  'Rationale': '预算更可控',
  'Alternatives': null,
  'MadeByMemberId': 1,
  'DecidedAt': '2026-08-05T10:00:00Z',
  'UpdatedAt': '2026-08-05T10:00:00Z',
};

Future<HttpFamilyRepository> _repository(
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
              'Msg': code == 0 ? 'ok' : '无效请求',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpFamilyRepository(api, homeIdOf: () => 1234);
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
