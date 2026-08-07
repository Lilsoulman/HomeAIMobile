import 'domain.dart';

abstract class ExpertRepository {
  /// 专家目录；[scope] 缺省不传（basic），B21 起可选 mine/all。
  Future<List<Expert>> listExperts({String query = '', String? scope});

  Future<Expert?> getExpert(String id, {required ExpertSourceType sourceType});

  /// B21 自建专家详情（表单编辑回填；他人/已软删返回 null）。
  Future<ExpertDetail?> getExpertDetail(
    String id, {
    required ExpertSourceType sourceType,
  });

  /// B21 创建自建专家；name/category/persona/promptTemplate 必填。
  Future<Expert> createExpert({
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  });

  /// B21 更新自建专家；RowVersion 冲突 409（刷新后重试）。
  Future<Expert> updateExpert({
    required String id,
    required int rowVersion,
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  });

  /// B21 软删除（200）；删除后从目录（mine/all）、运行与会话全部消失。
  Future<void> deleteExpert(String id);
}
