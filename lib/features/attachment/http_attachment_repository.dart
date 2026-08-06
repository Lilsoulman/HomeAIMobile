// 执行模式 22：附件 HTTP 实现。
//
// 复用 ApiClient.upload（保留 401 拦截器 + multipart 透传）。

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'attachment_repository.dart';
import 'dto.dart';

class HttpAttachmentRepository implements AttachmentRepository {
  HttpAttachmentRepository(this._api);
  final ApiClient _api;

  @override
  Future<AttachmentDto> deleteFile(int id) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/expert-files/$id',
      parseData: (_) => null,
    );
    // 后端 DELETE 通常只返回 {id}，构造回显 DTO
    return AttachmentDto(
      id: id,
      filename: '',
      sizeBytes: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<AttachmentDto>> listFiles() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/expert-files',
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map(
          (item) =>
              AttachmentDto.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<Uint8List> downloadFile(int id) =>
      _api.download('/expert-files/$id/content');

  @override
  Future<AttachmentDto> uploadFile({
    required String filename,
    required Uint8List bytes,
    String? mimeType,
    String? role,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: mimeType == null ? null : DioMediaType.parse(mimeType),
      ),
      if (role != null) 'role': role,
    });
    final raw = await _api.upload<dynamic>(
      path: '/expert-files',
      formData: formData,
      parseData: (raw) => raw,
    );
    if (raw is! Map) {
      throw ApiException(-1, '附件上传失败：后端未返回文件详情');
    }
    return AttachmentDto.fromJson(raw.cast<String, dynamic>());
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const [];
  }
}
