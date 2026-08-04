import 'dto.dart';
import 'skill_repository.dart';

class LocalSkillRepository implements SkillRepository {
  LocalSkillRepository() {
    final now = DateTime.now();
    _skills.addAll([
      _SkillRecord(
        id: _nextId++,
        name: '每日日报',
        prompt: '生成简洁的今日日报，包含完成事项、阻塞和明日行动。',
        scopes: '["day"]',
        isBuiltin: true,
        createdAt: now,
      ),
      _SkillRecord(
        id: _nextId++,
        name: '每周复盘',
        prompt: '生成本周工作复盘，包含成果、风险和下周行动。',
        scopes: '["week"]',
        isBuiltin: true,
        createdAt: now,
      ),
      _SkillRecord(
        id: _nextId++,
        name: '待办导入',
        prompt: '从文本中提取可以执行的待办事项。',
        scopes: '["import"]',
        isBuiltin: true,
        createdAt: now,
      ),
    ]);
  }

  final List<_SkillRecord> _skills = [];
  int _nextId = 1;

  @override
  Future<SkillDto> create({
    required String name,
    required String prompt,
    String? scopes,
    bool? isActive,
  }) async {
    final now = DateTime.now();
    final skill = _SkillRecord(
      id: _nextId++,
      name: name.trim(),
      prompt: prompt.trim(),
      scopes: scopes?.trim().isEmpty ?? true ? '[]' : scopes!.trim(),
      isBuiltin: false,
      isActive: isActive ?? true,
      createdAt: now,
    );
    _skills.add(skill);
    return skill.toDto();
  }

  @override
  Future<void> delete(int id) async {
    final index = _skills.indexWhere((skill) => skill.id == id);
    if (index < 0) return;
    if (_skills[index].isBuiltin) {
      throw StateError('内置 Skill 不能删除');
    }
    _skills.removeAt(index);
  }

  @override
  Future<List<SkillDto>> list() async =>
      _skills.map((skill) => skill.toDto()).toList(growable: false);

  @override
  Future<SkillDto> update(int id, Map<String, dynamic> patch) async {
    final skill = _skills.where((item) => item.id == id).firstOrNull;
    if (skill == null) throw StateError('未找到 Skill');
    skill.name = patch['name']?.toString().trim() ?? skill.name;
    skill.prompt = patch['prompt']?.toString().trim() ?? skill.prompt;
    skill.scopes = patch['scopes']?.toString().trim() ?? skill.scopes;
    skill.isActive = patch['isActive'] as bool? ?? skill.isActive;
    skill.updatedAt = DateTime.now();
    return skill.toDto();
  }
}

class _SkillRecord {
  _SkillRecord({
    required this.id,
    required this.name,
    required this.prompt,
    required this.scopes,
    required this.isBuiltin,
    this.isActive = true,
    required this.createdAt,
  }) : updatedAt = createdAt;

  final int id;
  String name;
  String prompt;
  String scopes;
  final bool isBuiltin;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  SkillDto toDto() => SkillDto(
    id: id,
    name: name,
    prompt: prompt,
    scopes: scopes,
    isBuiltin: isBuiltin,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
