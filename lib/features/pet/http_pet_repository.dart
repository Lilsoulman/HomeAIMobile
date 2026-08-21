import '../../../core/api/api_client.dart';
import 'dto.dart';
import 'pet_repository.dart';

class HttpPetRepository implements PetRepository {
  HttpPetRepository(this._api, {required this.homeIdOf});
  final ApiClient _api;
  final int Function() homeIdOf;
  int get _homeId => homeIdOf();
  Map<String, dynamic> _map(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
  List<Map<String, dynamic>> _list(dynamic v) => v is List
      ? v
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(growable: false)
      : const [];
  Future<dynamic> _request({
    required String method,
    required String path,
    Object? body,
    Map<String, dynamic>? query,
  }) => _api.request<dynamic>(
    method: method,
    path: path,
    body: body,
    query: query,
    parseData: (v) => v,
  );
  @override
  Future<List<PetDto>> listPets() async => _list(
    await _request(method: 'GET', path: '/homes/$_homeId/pets'),
  ).map(PetDto.fromJson).toList(growable: false);
  @override
  Future<PetDto> createPet(PetCreateDto request) async => PetDto.fromJson(
    _map(
      await _request(
        method: 'POST',
        path: '/homes/$_homeId/pets',
        body: request.toJson(),
      ),
    ),
  );
  @override
  Future<List<PetCareEventDto>> listCareEvents(int petId) async => _list(
    await _request(
      method: 'GET',
      path: '/homes/$_homeId/pets/$petId/care-events',
    ),
  ).map(PetCareEventDto.fromJson).toList(growable: false);
  @override
  Future<PetCareEventDto> addCareEvent(
    int petId,
    PetCareEventCreateDto request,
  ) async => PetCareEventDto.fromJson(
    _map(
      await _request(
        method: 'POST',
        path: '/homes/$_homeId/pets/$petId/care-events',
        body: request.toJson(),
      ),
    ),
  );
  @override
  Future<List<PetSupplyDto>> listSupplies(int petId) async => _list(
    await _request(method: 'GET', path: '/homes/$_homeId/pets/$petId/supplies'),
  ).map(PetSupplyDto.fromJson).toList(growable: false);
  @override
  Future<PetSupplyDto> upsertSupply(
    int petId,
    PetSupplyUpsertDto request,
  ) async => PetSupplyDto.fromJson(
    _map(
      await _request(
        method: 'PUT',
        path: '/homes/$_homeId/pets/$petId/supplies',
        body: request.toJson(),
      ),
    ),
  );
  @override
  Future<List<PetAlertDto>> listAlerts({DateTime? asOf}) async => _list(
    await _request(
      method: 'GET',
      path: '/homes/$_homeId/pets/alerts',
      query: asOf == null ? null : {'asOf': asOf.toUtc().toIso8601String()},
    ),
  ).map(PetAlertDto.fromJson).toList(growable: false);
}
