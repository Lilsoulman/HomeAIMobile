// 执行模式 21：附件本地实现（内存存储）。

import 'dart:typed_data';

import 'attachment_repository.dart';
import 'dto.dart';

class LocalAttachmentRepository implements AttachmentRepository {
  LocalAttachmentRepository() {
    final now = DateTime.now();
    _files.addAll([
      _FileRecord(
        id: _nextId++,
        filename: '本周计划.pdf',
        bytes: Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]),
        mimeType: 'application/pdf',
        role: 'context',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      _FileRecord(
        id: _nextId++,
        filename: '家庭设备清单.md',
        bytes: Uint8List.fromList(const [0x23, 0x20]),
        mimeType: 'text/markdown',
        role: 'reference',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  final List<_FileRecord> _files = [];
  int _nextId = 1;

  @override
  Future<AttachmentDto> deleteFile(int id) async {
    final index = _files.indexWhere((file) => file.id == id);
    if (index < 0) throw StateError('未找到附件');
    final removed = _files.removeAt(index);
    return removed.toDto();
  }

  @override
  Future<List<AttachmentDto>> listFiles() async =>
      _files.map((file) => file.toDto()).toList(growable: false);

  @override
  Future<AttachmentDto> uploadFile({
    required String filename,
    required Uint8List bytes,
    String? mimeType,
    String? role,
  }) async {
    final record = _FileRecord(
      id: _nextId++,
      filename: filename.trim(),
      bytes: bytes,
      mimeType: mimeType,
      role: role,
      createdAt: DateTime.now(),
    );
    _files.add(record);
    return record.toDto();
  }
}

class _FileRecord {
  _FileRecord({
    required this.id,
    required this.filename,
    required this.bytes,
    this.mimeType,
    this.role,
    required this.createdAt,
  });

  final int id;
  final String filename;
  final Uint8List bytes;
  final String? mimeType;
  final String? role;
  final DateTime createdAt;

  AttachmentDto toDto() => AttachmentDto(
    id: id,
    filename: filename,
    sizeBytes: bytes.length,
    mimeType: mimeType,
    role: role,
    createdAt: createdAt,
  );
}
