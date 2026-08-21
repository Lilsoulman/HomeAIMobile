import '../../../core/api/api_client.dart';
import 'courier_repository.dart';
import 'dto.dart';

class HttpCourierRepository implements CourierRepository {
  HttpCourierRepository(this._api, {required this.homeIdOf});

  final ApiClient _api;
  final int Function() homeIdOf;
  int get _homeId => homeIdOf();

  Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};

  List<Map<String, dynamic>> _items(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
    }
    if (raw is Map) {
      final value =
          raw['Items'] ?? raw['items'] ?? raw['Shipments'] ?? raw['shipments'];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(growable: false);
      }
    }
    return const [];
  }

  @override
  Future<List<CourierShipmentDto>> listShipments() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/courier/shipments',
      parseData: (value) => value,
    );
    return _items(raw).map(CourierShipmentDto.fromJson).toList(growable: false);
  }

  @override
  Future<CourierShipmentDto> createShipment(
    CourierShipmentCreateDto request,
  ) async {
    final raw = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/courier/shipments',
      body: request.toJson(),
      parseData: (value) => _map(value),
    );
    return CourierShipmentDto.fromJson(raw);
  }

  @override
  Future<CourierRefreshDto> refreshShipment(int shipmentId) async {
    final raw = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/courier/shipments/$shipmentId/refresh',
      parseData: (value) => _map(value),
    );
    return CourierRefreshDto.fromJson(raw);
  }

  @override
  Future<List<CourierAnomalyDto>> listAnomalies() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/courier/anomalies',
      parseData: (value) => value,
    );
    return _items(raw).map(CourierAnomalyDto.fromJson).toList(growable: false);
  }
}
