// 执行模式 19：附件 DTO。
//
// 字段映射：后端 PascalCase 与前端 camelCase 双兼容。

class AttachmentDto {
  AttachmentDto({
    required this.id,
    required this.filename,
    required this.sizeBytes,
    this.mimeType,
    this.role,
    required this.createdAt,
  });

  factory AttachmentDto.fromJson(Map<String, dynamic> json) => AttachmentDto(
    id: _intOrZero(json['id'] ?? json['Id']),
    filename: (json['filename'] ?? json['Filename'] ?? '').toString(),
    sizeBytes: _intOrZero(json['sizeBytes'] ?? json['SizeBytes']),
    mimeType: _stringOrNull(json['mimeType'] ?? json['MimeType']),
    role: _stringOrNull(json['role'] ?? json['Role']),
    createdAt: _dateOrNow(json['createdAt'] ?? json['CreatedAt']),
  );

  final int id;
  final String filename;
  final int sizeBytes;
  final String? mimeType;
  final String? role;
  final DateTime createdAt;

  String get displaySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

int _intOrZero(Object? value) => switch (value) {
  num number => number.toInt(),
  String text => int.tryParse(text) ?? 0,
  _ => 0,
};

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

DateTime _dateOrNow(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();
