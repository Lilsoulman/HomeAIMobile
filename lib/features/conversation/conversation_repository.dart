import 'dto.dart';

abstract class ConversationRepository {
  /// 会话列表，按 updatedAt 倒序游标分页（B20）。
  Future<ConversationPageDto> listConversations({
    int limit = 20,
    String? cursor,
  });

  /// 创建会话；title/expertId 均可空（expertId 空即未绑定专家）。
  Future<ConversationDto> createConversation({String? title, int? expertId});

  /// 全量更新：重命名/重绑。expertId 传 null 即解绑专家；RowVersion 冲突 409。
  Future<ConversationDto> updateConversation({
    required int id,
    String? title,
    int? expertId,
    required int rowVersion,
  });

  /// 软删除（200）；重复删除 404。
  Future<void> deleteConversation(int id);

  /// 消息历史，按主键倒序游标分页（B20）。
  Future<MessagePageDto> listMessages({
    required int conversationId,
    int limit = 20,
    String? cursor,
  });

  /// 发送消息；服务端按会话历史拼接 inputJson 创建 Expert Run，客户端不缓存上下文。
  /// 幂等键仅限本会话复用；重复用于其他会话返回 409。
  Future<SendMessageResultDto> sendMessage({
    required int conversationId,
    required String content,
    required String idempotencyKey,
  });
}
