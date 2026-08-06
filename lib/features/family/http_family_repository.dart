// P2 家庭协同数据层：Family HTTP 实现。
// 路由 `api/v1/homes/{homeId}/...`；homeId 必须等于 JWT tenant_id，由服务端校验。

import '../../../core/api/api_client.dart';
import 'family_repository.dart';
import 'dto.dart';

class HttpFamilyRepository implements FamilyRepository {
  HttpFamilyRepository(this._api, {required this.homeIdOf});

  final ApiClient _api;
  final int Function() homeIdOf;

  int get _homeId => homeIdOf();

  @override
  Future<List<FamilyMemberDto>> listMembers() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/members',
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map(
          (entry) =>
              FamilyMemberDto.fromJson((entry as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<FamilyMemberDto> createMember({
    required String name,
    required String relation,
    DateTime? birthday,
    bool? isElderly,
    bool? isChild,
    bool? isPrimary,
    String? memberStatus,
    String? preferences,
  }) async {
    final body = <String, dynamic>{'name': name, 'relation': relation};
    if (birthday != null) {
      body['birthday'] = birthday.toUtc().toIso8601String();
    }
    if (isElderly != null) body['isElderly'] = isElderly;
    if (isChild != null) body['isChild'] = isChild;
    if (isPrimary != null) body['isPrimary'] = isPrimary;
    if (memberStatus != null) body['memberStatus'] = memberStatus;
    if (preferences != null) body['preferences'] = preferences;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/members',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return FamilyMemberDto.fromJson(json);
  }

  @override
  Future<FamilyMemberDto> updateMember(
    int id,
    Map<String, dynamic> patch,
  ) async {
    final body = <String, dynamic>{};
    if (patch.containsKey('name')) body['name'] = patch['name'];
    if (patch.containsKey('relation')) body['relation'] = patch['relation'];
    if (patch.containsKey('birthday')) {
      final v = patch['birthday'];
      body['birthday'] = v is DateTime ? v.toUtc().toIso8601String() : v;
    }
    if (patch.containsKey('isElderly')) body['isElderly'] = patch['isElderly'];
    if (patch.containsKey('isChild')) body['isChild'] = patch['isChild'];
    if (patch.containsKey('isPrimary')) body['isPrimary'] = patch['isPrimary'];
    if (patch.containsKey('memberStatus')) {
      body['memberStatus'] = patch['memberStatus'];
    }
    if (patch.containsKey('preferences')) {
      body['preferences'] = patch['preferences'];
    }
    final json = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/homes/$_homeId/members/$id',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return FamilyMemberDto.fromJson(json);
  }

  @override
  Future<FamilyMemberDto> correctMember(
    int id, {
    required String memberStatus,
    String? reason,
  }) async {
    final body = <String, dynamic>{'memberStatus': memberStatus};
    if (reason != null) body['reason'] = reason;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/members/$id/correction',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return FamilyMemberDto.fromJson(json);
  }

  @override
  Future<List<FamilyKnowledgeDto>> listKnowledge({String? category}) async {
    final query = <String, dynamic>{};
    if (category != null) query['category'] = category;
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/knowledge',
      query: query,
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map(
          (entry) => FamilyKnowledgeDto.fromJson(
            (entry as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<FamilyKnowledgeWriteResultDto> writeKnowledge({
    required String category,
    required String key,
    required String value,
    String? notes,
    String? sourceType,
    int? sourceMemberId,
    double? confidenceScore,
    String? conflictResolutionStrategy,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'key': key,
      'value': value,
    };
    if (notes != null) body['notes'] = notes;
    if (sourceType != null) body['sourceType'] = sourceType;
    if (sourceMemberId != null) body['sourceMemberId'] = sourceMemberId;
    if (confidenceScore != null) body['confidenceScore'] = confidenceScore;
    if (conflictResolutionStrategy != null) {
      body['conflictResolutionStrategy'] = conflictResolutionStrategy;
    }
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/knowledge',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return FamilyKnowledgeWriteResultDto.fromJson(json);
  }

  @override
  Future<void> deleteKnowledge(int id) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/homes/$_homeId/knowledge/$id',
      parseData: (_) => null,
    );
  }

  @override
  Future<FamilyDecisionPageDto> listDecisions({
    int? memberId,
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (memberId != null) query['memberId'] = memberId;
    if (cursor != null) query['cursor'] = cursor;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/homes/$_homeId/decisions',
      query: query,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return FamilyDecisionPageDto.fromJson(json);
  }

  @override
  Future<FamilyDecisionDto> recordDecision({
    required String scenario,
    required String decisionMade,
    String? rationale,
    String? alternatives,
    int? madeByMemberId,
    DateTime? decidedAt,
  }) async {
    final body = <String, dynamic>{
      'scenario': scenario,
      'decisionMade': decisionMade,
    };
    if (rationale != null) body['rationale'] = rationale;
    if (alternatives != null) body['alternatives'] = alternatives;
    if (madeByMemberId != null) body['madeByMemberId'] = madeByMemberId;
    if (decidedAt != null) {
      body['decidedAt'] = decidedAt.toUtc().toIso8601String();
    }
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/decisions',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return FamilyDecisionDto.fromJson(json);
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const [];
  }
}
