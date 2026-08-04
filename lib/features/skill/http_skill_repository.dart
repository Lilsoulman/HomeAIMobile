// 执行模式 19：Skill DTO + HTTP 仓库。

import '../../../core/api/api_client.dart';
import 'dto.dart';
import 'skill_repository.dart';

class HttpSkillRepository implements SkillRepository {
  HttpSkillRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<SkillDto>> list() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/skills',
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map((e) => SkillDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<SkillDto> create({
    required String name,
    required String prompt,
    String? scopes,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{'name': name, 'prompt': prompt};
    if (scopes != null) body['scopes'] = scopes;
    if (isActive != null) body['isActive'] = isActive;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/skills',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return SkillDto.fromJson(json);
  }

  @override
  Future<SkillDto> update(int id, Map<String, dynamic> patch) async {
    final body = <String, dynamic>{};
    if (patch.containsKey('name')) body['name'] = patch['name'];
    if (patch.containsKey('prompt')) body['prompt'] = patch['prompt'];
    if (patch.containsKey('scopes')) body['scopes'] = patch['scopes'];
    if (patch.containsKey('isActive')) body['isActive'] = patch['isActive'];
    final json = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/skills/$id',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return SkillDto.fromJson(json);
  }

  @override
  Future<void> delete(int id) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/skills/$id',
      parseData: (_) => null,
    );
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const [];
  }
}
