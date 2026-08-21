import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/pet/dto.dart';
import 'package:nexus_mind_mobile/features/pet/http_pet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('maps pet API responses and camelCase requests', () async {
    SharedPreferences.setMockInitialValues({});
    final paths = <String>[];
    Map<String, dynamic>? body;
    final api = ApiClient(tokenStorage: _Tokens(), env: await EnvConfig.init());
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          paths.add(o.path);
          if (o.data is Map) body = (o.data as Map).cast<String, dynamic>();
          final data = o.path.endsWith('/alerts')
              ? [_alert()]
              : o.path.endsWith('/supplies')
              ? [_supply()]
              : o.path.endsWith('/care-events')
              ? [_care()]
              : [_pet()];
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: {'Code': 0, 'Msg': 'ok', 'Data': data},
            ),
          );
        },
      ),
    );
    final repo = HttpPetRepository(api, homeIdOf: () => 42);
    expect((await repo.listPets()).single.name, 'Mochi');
    expect((await repo.listAlerts()).single.confirmationId, 8);
    expect((await repo.listSupplies(3)).single.daysRemaining, 4);
    await repo.createPet(const PetCreateDto(name: 'Mochi', species: 'cat'));
    expect(paths, contains('/homes/42/pets/3/supplies'));
    expect(body, containsPair('species', 'cat'));
  });
}

Map<String, dynamic> _pet() => {
  'Id': 3,
  'Name': 'Mochi',
  'Species': 'cat',
  'IsActive': true,
};
Map<String, dynamic> _care() => {
  'Id': 1,
  'PetId': 3,
  'CareType': 'vaccine',
  'Title': 'Annual vaccine',
  'DueDate': '2026-08-22T00:00:00Z',
};
Map<String, dynamic> _supply() => {
  'Id': 1,
  'PetId': 3,
  'ItemName': 'Food',
  'Quantity': 4,
  'DailyUsage': 1,
  'Unit': 'bag',
  'DaysRemaining': 4,
};
Map<String, dynamic> _alert() => {
  'Type': 'supply_low',
  'PetId': 3,
  'Title': 'Food runs low',
  'DaysRemaining': 4,
  'ConfirmationId': 8,
};

class _Tokens implements TokenStorage {
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
