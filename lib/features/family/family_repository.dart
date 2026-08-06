// P2 家庭协同数据层：Family 仓储接口（成员 / 知识库 / 决策历史）。

import 'dto.dart';

abstract class FamilyRepository {
  Future<List<FamilyMemberDto>> listMembers();

  Future<FamilyMemberDto> createMember({
    required String name,
    required String relation,
    DateTime? birthday,
    bool? isElderly,
    bool? isChild,
    bool? isPrimary,
    String? memberStatus,
    String? preferences,
  });

  Future<FamilyMemberDto> updateMember(int id, Map<String, dynamic> patch);

  Future<FamilyMemberDto> correctMember(
    int id, {
    required String memberStatus,
    String? reason,
  });

  Future<List<FamilyKnowledgeDto>> listKnowledge({String? category});

  Future<FamilyKnowledgeWriteResultDto> writeKnowledge({
    required String category,
    required String key,
    required String value,
    String? notes,
    String? sourceType,
    int? sourceMemberId,
    double? confidenceScore,
    String? conflictResolutionStrategy,
  });

  Future<void> deleteKnowledge(int id);

  Future<FamilyDecisionPageDto> listDecisions({
    int? memberId,
    int limit = 20,
    String? cursor,
  });

  Future<FamilyDecisionDto> recordDecision({
    required String scenario,
    required String decisionMade,
    String? rationale,
    String? alternatives,
    int? madeByMemberId,
    DateTime? decidedAt,
  });
}
