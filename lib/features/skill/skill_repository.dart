import 'dto.dart';

abstract class SkillRepository {
  Future<List<SkillDto>> list();
  Future<SkillDto> create({
    required String name,
    required String prompt,
    String? scopes,
    bool? isActive,
  });
  Future<SkillDto> update(int id, Map<String, dynamic> patch);
  Future<void> delete(int id);
}
