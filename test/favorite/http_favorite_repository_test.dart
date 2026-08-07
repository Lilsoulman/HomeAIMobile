// P5b 个人偏好收藏 HTTP：路径 / 请求体 / PascalCase 映射 / 错误传递。

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/favorite/dto.dart';
import 'package:nexus_mind_mobile/features/favorite/http_favorite_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpFavoriteRepository', () {
    test(
      'maps list / create / update / delete / import with contract paths',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          [_favoriteJson()],
          _favoriteJson(),
          _favoriteJson(visibility: 'family'),
          _favoriteJson(),
          null,
        ]);

        final items = await repository.list(
          category: 'restaurant',
          visibility: 'private',
        );
        final created = await repository.create(
          category: FavoriteCategory.restaurant,
          name: '老王面馆',
          detailJson: '{"cuisine":"面食"}',
        );
        final updated = await repository.update(
          501,
          category: FavoriteCategory.travel,
          name: '西湖',
          visibility: FavoriteVisibility.family,
        );
        final imported = await repository.import(
          category: FavoriteCategory.material,
          name: '灵感笔记',
          source: '小红书',
          conversationText: '这家店不错',
        );
        await repository.delete(501);

        expect(items, hasLength(1));
        expect(items.single.category, FavoriteCategory.restaurant);
        expect(items.single.visibility, FavoriteVisibility.private);
        expect(
          items.single.detailJson,
          '{"cuisine":"面食","address":"城西","tags":["面"],"source":"小红书"}',
        );
        expect(created.name, '老王面馆');
        expect(updated.visibility, FavoriteVisibility.family);
        expect(imported.ownerMemberId, 3);

        expect(requests.map((request) => request.path), [
          '/life/favorites',
          '/life/favorites',
          '/life/favorites/501',
          '/life/favorites/import',
          '/life/favorites/501',
        ]);
        expect(requests[0].queryParameters, {
          'category': 'restaurant',
          'visibility': 'private',
        });
        expect(requests[1].data, {
          'category': 'restaurant',
          'name': '老王面馆',
          'detailJson': '{"cuisine":"面食"}',
          'visibility': 'private',
        });
        expect(requests[2].data, {
          'category': 'travel',
          'name': '西湖',
          'visibility': 'family',
        });
        expect(requests[3].data, {
          'category': 'material',
          'name': '灵感笔记',
          'visibility': 'private',
          'source': '小红书',
          'conversationText': '这家店不错',
        });
        expect(requests[4].method, 'DELETE');
      },
    );

    test('omits optional fields when absent', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [_favoriteJson()]);

      await repository.create(
        category: FavoriteCategory.restaurant,
        name: '老王面馆',
      );

      expect(requests.single.data, {
        'category': 'restaurant',
        'name': '老王面馆',
        'visibility': 'private',
      });
    });

    test('propagates a 422 API failure', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, const [], code: 422);

      await expectLater(
        repository.list(),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '无效请求'),
        ),
      );
    });
  });
}

Map<String, dynamic> _favoriteJson({String visibility = 'private'}) => {
  'Id': 501,
  'OwnerMemberId': 3,
  'Category': 'restaurant',
  'Name': '老王面馆',
  'DetailJson': '{"cuisine":"面食","address":"城西","tags":["面"],"source":"小红书"}',
  'Visibility': visibility,
  'CreatedAt': '2026-08-06T02:00:00Z',
  'UpdatedAt': '2026-08-06T02:00:00Z',
};

Future<HttpFavoriteRepository> _repository(
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
  return HttpFavoriteRepository(api);
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
