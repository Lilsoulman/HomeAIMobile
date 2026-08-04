import 'domain.dart';
import 'expert_repository.dart';

class MockExpertRepository implements ExpertRepository {
  static const _experts = [
    Expert(
      id: '1',
      sourceType: ExpertSourceType.expert,
      name: '家庭管家',
      category: 'home',
      description: '结合家庭计划与设备状态，整理清晰、可确认的生活建议。',
      estimatedCredits: 1,
    ),
  ];

  @override
  Future<List<Expert>> listExperts({String query = ''}) async {
    final keyword = query.trim().toLowerCase();
    return _experts
        .where(
          (expert) =>
              keyword.isEmpty ||
              '${expert.name} ${expert.category} ${expert.description}'
                  .toLowerCase()
                  .contains(keyword),
        )
        .toList(growable: false);
  }

  @override
  Future<Expert?> getExpert(
    String id, {
    required ExpertSourceType sourceType,
  }) async => _experts
      .where((expert) => expert.id == id && expert.sourceType == sourceType)
      .cast<Expert?>()
      .firstOrNull;
}
