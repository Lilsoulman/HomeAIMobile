// 知识条目仓储接口：每日知识管家的本地知识库（用户主动传入 + 预置）。

class KnowledgeItemDto {
  const KnowledgeItemDto({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    this.source,
    this.createdAt,
  });

  factory KnowledgeItemDto.fromJson(Map<String, dynamic> json) =>
      KnowledgeItemDto(
        id: (json['Id'] ?? json['id'] as num?)?.toInt() ?? 0,
        category: (json['Category'] ?? json['category'] ?? '').toString(),
        title: (json['Title'] ?? json['title'] ?? '').toString(),
        content: (json['Content'] ?? json['content'] ?? '').toString(),
        source: (json['Source'] ?? json['source'])?.toString(),
        createdAt: DateTime.tryParse(
          (json['CreatedAt'] ?? json['createdAt'] ?? '').toString(),
        ),
      );

  final int id;
  final String category;
  final String title;
  final String content;
  final String? source;
  final DateTime? createdAt;
}

abstract class KnowledgeRepository {
  Future<List<KnowledgeItemDto>> list({String? category});
  Future<void> create({
    required String category,
    required String title,
    required String content,
    String? source,
  });
  Future<void> delete(int id);
}
