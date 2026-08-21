import 'dto.dart';

abstract class PetRepository {
  Future<List<PetDto>> listPets();
  Future<PetDto> createPet(PetCreateDto request);
  Future<List<PetCareEventDto>> listCareEvents(int petId);
  Future<PetCareEventDto> addCareEvent(
    int petId,
    PetCareEventCreateDto request,
  );
  Future<List<PetSupplyDto>> listSupplies(int petId);
  Future<PetSupplyDto> upsertSupply(int petId, PetSupplyUpsertDto request);
  Future<List<PetAlertDto>> listAlerts({DateTime? asOf});
}
