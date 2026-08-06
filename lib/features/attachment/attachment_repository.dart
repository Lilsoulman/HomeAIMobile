// 执行模式 20：附件仓储接口。

import 'dart:typed_data';

import 'dto.dart';

abstract class AttachmentRepository {
  Future<List<AttachmentDto>> listFiles();
  Future<AttachmentDto> uploadFile({
    required String filename,
    required Uint8List bytes,
    String? mimeType,
    String? role,
  });
  Future<void> deleteFile(int id);

  /// 下载文件字节流（服务端生成文件下载通道）。
  Future<Uint8List> downloadFile(int id);
}
