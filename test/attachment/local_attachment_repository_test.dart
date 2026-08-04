import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/attachment/local_attachment_repository.dart';

void main() {
  group('LocalAttachmentRepository', () {
    test('exposes seeded samples and accepts uploads', () async {
      final repository = LocalAttachmentRepository();
      final initial = await repository.listFiles();
      expect(initial.length, 2);

      final created = await repository.uploadFile(
        filename: 'note.txt',
        bytes: Uint8List.fromList('hello'.codeUnits),
        mimeType: 'text/plain',
        role: 'context',
      );
      final after = await repository.listFiles();
      expect(after.length, initial.length + 1);
      expect(created.filename, 'note.txt');
      expect(created.sizeBytes, 5);
      expect(created.displaySize, contains('B'));
    });

    test('deleteFile removes the file by id', () async {
      final repository = LocalAttachmentRepository();
      final first = (await repository.listFiles()).first;
      await repository.deleteFile(first.id);
      final remaining = await repository.listFiles();
      expect(remaining.any((file) => file.id == first.id), isFalse);
    });

    test('displaySize formats larger files in KB', () async {
      final repository = LocalAttachmentRepository();
      final big = await repository.uploadFile(
        filename: 'big.bin',
        bytes: Uint8List(2048),
        mimeType: 'application/octet-stream',
      );
      expect(big.displaySize, contains('KB'));
    });
  });
}
