import 'dto.dart';

abstract class FavoriteRepository {
  /// 收藏列表；category / visibility 可过滤。private 项仅归属成员本人可见，
  /// 过滤由服务端按 JWT 完成，客户端不做二次透出。
  Future<List<FavoriteDto>> list({String? category, String? visibility});

  Future<FavoriteDto> create({
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    FavoriteVisibility visibility,
  });

  /// 更新；仅本人或家庭管理员，否则 403。
  Future<FavoriteDto> update(
    int id, {
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    required FavoriteVisibility visibility,
  });

  /// 软删除；破坏性操作，UI 须二次确认。
  Future<void> delete(int id);

  /// 对话导入；Source 必填并留痕入审计。
  Future<FavoriteDto> import({
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    FavoriteVisibility visibility,
    required String source,
    String? conversationText,
  });
}
