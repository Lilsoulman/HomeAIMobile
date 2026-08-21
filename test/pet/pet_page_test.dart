import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/pet/dto.dart';
import 'package:nexus_mind_mobile/features/pet/pet_repository.dart';
import 'package:nexus_mind_mobile/pages/pet_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows pets and reminders', (tester) async {
    await tester.pumpWidget(
      Provider<PetRepository>.value(
        value: _Repo(),
        child: const MaterialApp(home: PetPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mochi'), findsOneWidget);
    expect(find.text('Food runs low'), findsOneWidget);
  });
}

class _Repo implements PetRepository {
  @override
  Future<PetDto> createPet(PetCreateDto request) async =>
      throw UnimplementedError();
  @override
  Future<PetCareEventDto> addCareEvent(
    int petId,
    PetCareEventCreateDto request,
  ) async => throw UnimplementedError();
  @override
  Future<PetSupplyDto> upsertSupply(
    int petId,
    PetSupplyUpsertDto request,
  ) async => throw UnimplementedError();
  @override
  Future<List<PetDto>> listPets() async => const [
    PetDto(id: 3, name: 'Mochi', species: 'cat', isActive: true),
  ];
  @override
  Future<List<PetAlertDto>> listAlerts({DateTime? asOf}) async => const [
    PetAlertDto(
      type: 'supply_low',
      petId: 3,
      title: 'Food runs low',
      daysRemaining: 4,
    ),
  ];
  @override
  Future<List<PetCareEventDto>> listCareEvents(int petId) async => const [];
  @override
  Future<List<PetSupplyDto>> listSupplies(int petId) async => const [
    PetSupplyDto(
      id: 1,
      petId: 3,
      itemName: 'Food',
      quantity: 4,
      dailyUsage: 1,
      unit: 'bag',
      daysRemaining: 4,
    ),
  ];
}
