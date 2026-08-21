import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/courier/courier_repository.dart';
import 'package:nexus_mind_mobile/features/courier/dto.dart';
import 'package:nexus_mind_mobile/pages/courier_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows a masked shipment and anomaly suggestion', (tester) async {
    await tester.pumpWidget(
      Provider<CourierRepository>.value(
        value: _Repository(),
        child: const MaterialApp(home: CourierPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('快递管家'), findsOneWidget);
    expect(find.text('生鲜'), findsOneWidget);
    expect(find.text('物流长时间未更新'), findsOneWidget);
    expect(find.textContaining('******6789'), findsNothing);
  });
}

class _Repository implements CourierRepository {
  @override
  Future<CourierShipmentDto> createShipment(CourierShipmentCreateDto request) =>
      throw UnimplementedError();

  @override
  Future<List<CourierAnomalyDto>> listAnomalies() async => const [
    CourierAnomalyDto(
      shipmentId: 9,
      type: 'stagnant',
      title: '物流长时间未更新',
      description: '超过 48 小时没有新记录。',
      suggestedAction: '联系承运商催件',
      confirmationId: 4,
    ),
  ];

  @override
  Future<List<CourierShipmentDto>> listShipments() async => const [
    CourierShipmentDto(
      id: 9,
      trackingNumberMasked: '******6789',
      carrier: '顺丰',
      label: '生鲜',
      isFreshFood: true,
      expectedDeliveryAt: null,
      latestStatus: 'in_transit',
      latestDescription: '运输中',
      latestLocation: null,
      latestEventAt: null,
      lastCheckedAt: null,
    ),
  ];

  @override
  Future<CourierRefreshDto> refreshShipment(int shipmentId) =>
      throw UnimplementedError();
}
