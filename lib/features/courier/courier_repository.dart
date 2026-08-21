import 'dto.dart';

abstract class CourierRepository {
  Future<List<CourierShipmentDto>> listShipments();
  Future<CourierShipmentDto> createShipment(CourierShipmentCreateDto request);
  Future<CourierRefreshDto> refreshShipment(int shipmentId);
  Future<List<CourierAnomalyDto>> listAnomalies();
}
