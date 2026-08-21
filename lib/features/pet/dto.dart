class PetCreateDto {
  const PetCreateDto({
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.notes,
  });
  final String name;
  final String species;
  final String? breed;
  final DateTime? birthDate;
  final String? notes;
  Map<String, dynamic> toJson() => {
    'name': name,
    'species': species,
    if (breed?.trim().isNotEmpty == true) 'breed': breed,
    if (birthDate != null) 'birthDate': birthDate!.toUtc().toIso8601String(),
    if (notes?.trim().isNotEmpty == true) 'notes': notes,
  };
}

class PetDto {
  const PetDto({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.notes,
    required this.isActive,
  });
  factory PetDto.fromJson(Map<String, dynamic> j) => PetDto(
    id: _int(j['Id'] ?? j['id']),
    name: _str(j['Name'] ?? j['name']),
    species: _str(j['Species'] ?? j['species']),
    breed: _opt(j['Breed'] ?? j['breed']),
    birthDate: _date(j['BirthDate'] ?? j['birthDate']),
    notes: _opt(j['Notes'] ?? j['notes']),
    isActive: _bool(j['IsActive'] ?? j['isActive'], true),
  );
  final int id;
  final String name;
  final String species;
  final String? breed;
  final DateTime? birthDate;
  final String? notes;
  final bool isActive;
}

class PetCareEventCreateDto {
  const PetCareEventCreateDto({
    required this.careType,
    required this.title,
    required this.dueDate,
    this.notes,
  });
  final String careType;
  final String title;
  final DateTime dueDate;
  final String? notes;
  Map<String, dynamic> toJson() => {
    'careType': careType,
    'title': title,
    'dueDate': dueDate.toUtc().toIso8601String(),
    if (notes?.trim().isNotEmpty == true) 'notes': notes,
  };
}

class PetCareEventDto {
  const PetCareEventDto({
    required this.id,
    required this.petId,
    required this.careType,
    required this.title,
    required this.dueDate,
    this.completedAt,
    this.notes,
  });
  factory PetCareEventDto.fromJson(Map<String, dynamic> j) => PetCareEventDto(
    id: _int(j['Id'] ?? j['id']),
    petId: _int(j['PetId'] ?? j['petId']),
    careType: _str(j['CareType'] ?? j['careType']),
    title: _str(j['Title'] ?? j['title']),
    dueDate:
        _date(j['DueDate'] ?? j['dueDate']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    completedAt: _date(j['CompletedAt'] ?? j['completedAt']),
    notes: _opt(j['Notes'] ?? j['notes']),
  );
  final int id;
  final int petId;
  final String careType;
  final String title;
  final DateTime dueDate;
  final DateTime? completedAt;
  final String? notes;
}

class PetSupplyUpsertDto {
  const PetSupplyUpsertDto({
    required this.itemName,
    required this.quantity,
    required this.dailyUsage,
    this.unit = '份',
    this.measuredAt,
    this.sourceType = 'manual',
  });
  final String itemName;
  final double quantity;
  final double dailyUsage;
  final String unit;
  final DateTime? measuredAt;
  final String sourceType;
  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'quantity': quantity,
    'dailyUsage': dailyUsage,
    'unit': unit,
    if (measuredAt != null) 'measuredAt': measuredAt!.toUtc().toIso8601String(),
    'sourceType': sourceType,
  };
}

class PetSupplyDto {
  const PetSupplyDto({
    required this.id,
    required this.petId,
    required this.itemName,
    required this.quantity,
    required this.dailyUsage,
    required this.unit,
    required this.daysRemaining,
    this.confirmationId,
  });
  factory PetSupplyDto.fromJson(Map<String, dynamic> j) => PetSupplyDto(
    id: _int(j['Id'] ?? j['id']),
    petId: _int(j['PetId'] ?? j['petId']),
    itemName: _str(j['ItemName'] ?? j['itemName']),
    quantity: _num(j['Quantity'] ?? j['quantity']),
    dailyUsage: _num(j['DailyUsage'] ?? j['dailyUsage']),
    unit: _str(j['Unit'] ?? j['unit']),
    daysRemaining: _nullableNum(j['DaysRemaining'] ?? j['daysRemaining']),
    confirmationId: _nullableInt(j['ConfirmationId'] ?? j['confirmationId']),
  );
  final int id;
  final int petId;
  final String itemName;
  final double quantity;
  final double dailyUsage;
  final String unit;
  final double? daysRemaining;
  final int? confirmationId;
}

class PetAlertDto {
  const PetAlertDto({
    required this.type,
    required this.petId,
    required this.title,
    required this.daysRemaining,
    this.confirmationId,
  });
  factory PetAlertDto.fromJson(Map<String, dynamic> j) => PetAlertDto(
    type: _str(j['Type'] ?? j['type']),
    petId: _int(j['PetId'] ?? j['petId']),
    title: _str(j['Title'] ?? j['title']),
    daysRemaining: _nullableNum(j['DaysRemaining'] ?? j['daysRemaining']),
    confirmationId: _nullableInt(j['ConfirmationId'] ?? j['confirmationId']),
  );
  final String type;
  final int petId;
  final String title;
  final double? daysRemaining;
  final int? confirmationId;
}

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
int? _nullableInt(dynamic v) => v == null ? null : _int(v);
double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
double? _nullableNum(dynamic v) => v == null ? null : _num(v);
String _str(dynamic v) => v?.toString() ?? '';
String? _opt(dynamic v) => v?.toString();
bool _bool(dynamic v, [bool fallback = false]) => v is bool
    ? v
    : v == null
    ? fallback
    : v.toString() == 'true';
DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());
