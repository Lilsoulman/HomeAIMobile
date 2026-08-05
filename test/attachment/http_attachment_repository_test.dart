import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/attachment/http_attachment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpAttachmentRepository', () {
    test('maps listFiles and deleteFile endpoints', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        [
          _fileJson(id: 7, name: 'plan.pdf'),
          _fileJson(id: 8, name: 'notes.md'),
        ],
        null,
      ]);

      final files = await repository.listFiles();
      await repository.deleteFile(7);

      expect(files, hasLength(2));
      expect(files.first.filename, 'plan.pdf');
      expect(requests.map((request) => request.path), [
        '/expert-files',
        '/expert-files/7',
      ]);
    });

    test(
      'uploadFile uses FormData with MultipartFile and parses response',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          _fileJson(id: 9, name: 'uploaded.txt'),
        ]);

        final bytes = Uint8List.fromList('abc'.codeUnits);
        final uploaded = await repository.uploadFile(
          filename: 'uploaded.txt',
          bytes: bytes,
          mimeType: 'text/plain',
          role: 'context',
        );

        expect(uploaded.id, 9);
        expect(uploaded.filename, 'uploaded.txt');
        expect(requests, hasLength(1));
        expect(requests.single.path, '/expert-files');
        final form = requests.single.data as FormData;
        expect(form.files, hasLength(1));
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.filename, 'uploaded.txt');
      },
    );

    test('propagates a 422 API failure', () async {
      final repository = await _repository(
        <RequestOptions>[],
        const [],
        code: 422,
      );

      await expectLater(
        repository.listFiles(),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '无效文件'),
        ),
      );
    });
  });
}

Map<String, dynamic> _fileJson({required int id, required String name}) => {
  'id': id,
  'filename': name,
  'sizeBytes': 1024,
  'mimeType': 'application/octet-stream',
  'role': 'context',
  'createdAt': '2026-08-04T09:00:00Z',
};

Future<HttpAttachmentRepository> _repository(
  List<RequestOptions> requests,
  List<Object?> responses, {
  int code = 0,
}) async {
  SharedPreferences.setMockInitialValues({});
  final api = ApiClient(
    tokenStorage: _MemoryTokens(),
    env: await EnvConfig.init(),
  );
  api.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: {
              'Code': code,
              'Msg': code == 0 ? 'ok' : '无效文件',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpAttachmentRepository(api);
}

class _MemoryTokens implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {}
}
