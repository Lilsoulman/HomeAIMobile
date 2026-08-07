// P5b 个人偏好收藏 DTO 契约说明（与后端 §8.20 对齐）：
// - category 值域 restaurant | travel | material，非法返回 422。
// - visibility 值域 private | family，默认 private；private 项仅归属成员本人可见。
// - detailJson 为可选 JSON 字符串，前端不解析内部结构，原样存取展示。
// - 家庭归属由 JWT 推导，客户端不得发送家庭 ID。

enum FavoriteCategory {
  restaurant,
  travel,
  material;

  String get apiValue => name;

  String get label => switch (this) {
    restaurant => '餐厅',
    travel => '旅行',
    material => '素材',
  };

  static FavoriteCategory fromApiValue(Object? value) =>
      switch (value?.toString()) {
        'travel' => travel,
        'material' => material,
        _ => restaurant,
      };
}

enum FavoriteVisibility {
  private,
  family;

  String get apiValue => name;

  String get label => switch (this) {
    private => '私密',
    family => '家庭共享',
  };

  static FavoriteVisibility fromApiValue(Object? value) =>
      value?.toString() == family.apiValue ? family : private;
}

class FavoriteDto {
  const FavoriteDto({
    required this.id,
    this.ownerMemberId,
    required this.category,
    required this.name,
    this.detailJson,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavoriteDto.fromJson(Map<String, dynamic> json) => FavoriteDto(
    id: _intOrZero(json['Id'] ?? json['id']),
    ownerMemberId: _intOrNull(json['OwnerMemberId'] ?? json['ownerMemberId']),
    category: FavoriteCategory.fromApiValue(
      json['Category'] ?? json['category'],
    ),
    name: (json['Name'] ?? json['name'] ?? '').toString(),
    detailJson: _stringOrNull(json['DetailJson'] ?? json['detailJson']),
    visibility: FavoriteVisibility.fromApiValue(
      json['Visibility'] ?? json['visibility'],
    ),
    createdAt: _date(json['CreatedAt'] ?? json['createdAt']),
    updatedAt: _date(json['UpdatedAt'] ?? json['updatedAt']),
  );

  final int id;
  final int? ownerMemberId;
  final FavoriteCategory category;
  final String name;
  final String? detailJson;
  final FavoriteVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;
}

int _intOrZero(Object? value) => _intOrNull(value) ?? 0;

int? _intOrNull(Object? value) => switch (value) {
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();
