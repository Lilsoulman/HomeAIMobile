import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/courier/dto.dart';
import 'package:nexus_mind_mobile/features/courier/http_courier_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps masked courier responses and request fields', () async {
    SharedPreferences.setMockInitialValues({});
    final paths = <String>[];
    Map<String, dynamic>? requestBody;
    final api = ApiClient(tokenStorage: _Tokens(), env: await EnvConfig.init());
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add(options.path);
          requestBody = options.data is Map
              ? (options.data as Map).cast<String, dynamic>()
              : requestBody;
          final data = switch (options.path) {
            '/homes/42/courier/shipments' when options.method == 'GET' => [
              _shipment(),
            ],
            '/homes/42/courier/shipments' => _shipment(),
            '/homes/42/courier/shipments/9/refresh' => {
              'Shipment': _shipment(),
              'NewEvents': [
                {
                  'Status': 'in_transit',
                  'Description': '运输中',
                  'Location': '杭州',
                  'OccurredAt': '2026-08-20T08:00:00Z',
                },
              ],
              'Anomalies': [_anomaly()],
            },
            _ => [_anomaly()],
          };
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'Code': 0, 'Msg': 'ok', 'Data': data},
            ),
          );
        },
      ),
    );
    final repository = HttpCourierRepository(api, homeIdOf: () => 42);

    expect(
      (await repository.listShipments()).single.trackingNumberMasked,
      '******6789',
    );
    await repository.createShipment(
      const CourierShipmentCreateDto(
        trackingNumber: 'SF123456789',
        isFreshFood: true,
      ),
    );
    final refresh = await repository.refreshShipment(9);
    expect(refresh.newEvents.single.location, '杭州');
    expect(refresh.anomalies.single.confirmationId, 4);
    expect((await repository.listAnomalies()).single.type, 'stagnant');
    expect(paths, contains('/homes/42/courier/shipments/9/refresh'));
    expect(requestBody, containsPair('trackingNumber', 'SF123456789'));
    expect(requestBody, containsPair('isFreshFood', true));
  });
}

Map<String, dynamic> _shipment() => {
  'Id': 9,
  'TrackingNumberMasked': '******6789',
  'Carrier': '顺丰',
  'Label': '生鲜',
  'IsFreshFood': true,
  'LatestStatus': 'in_transit',
  'LatestDescription': '运输中',
  'LatestLocation': '杭州',
  'LatestEventAt': '2026-08-20T08:00:00Z',
};

Map<String, dynamic> _anomaly() => {
  'ShipmentId': 9,
  'Type': 'stagnant',
  'Title': '物流长时间未更新',
  'Description': '超过 48 小时没有新记录。',
  'SuggestedAction': '联系承运商催件',
  'ConfirmationId': 4,
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
