enum ExpertSourceType {
  expert,
  group;

  String get apiValue => name;

  static ExpertSourceType fromApiValue(Object? value) =>
      value?.toString() == group.apiValue ? group : expert;
}

class Expert {
  const Expert({
    required this.id,
    required this.sourceType,
    required this.name,
    required this.category,
    required this.description,
    required this.estimatedCredits,
  });

  final String id;
  final ExpertSourceType sourceType;
  final String name;
  final String category;
  final String description;
  final int estimatedCredits;
}
