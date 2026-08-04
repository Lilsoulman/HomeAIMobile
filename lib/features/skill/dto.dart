class SkillDto {
  SkillDto({
    required this.id,
    required this.name,
    required this.prompt,
    required this.scopes,
    required this.isBuiltin,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SkillDto.fromJson(Map<String, dynamic> json) => SkillDto(
    id: (json['id'] as num).toInt(),
    name: (json['name'] ?? '').toString(),
    prompt: (json['prompt'] ?? '').toString(),
    scopes: (json['scopes'] ?? '[]').toString(),
    isBuiltin: (json['IsBuiltin'] as bool?) ?? false,
    isActive: (json['IsActive'] as bool?) ?? true,
    createdAt: DateTime.parse(json['CreatedAt'] as String),
    updatedAt: DateTime.parse(json['UpdatedAt'] as String),
  );

  final int id;
  final String name;
  final String prompt;
  final String scopes;
  final bool isBuiltin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
