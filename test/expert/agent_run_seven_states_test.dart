import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/expert/dto.dart';

void main() {
  group('ExpertRunStatus seven states', () {
    test('maps every contract state without collapsing it', () {
      expect(ExpertRunStatus.fromApiValue('draft'), ExpertRunStatus.draft);
      expect(ExpertRunStatus.fromApiValue('queued'), ExpertRunStatus.queued);
      expect(
        ExpertRunStatus.fromApiValue('planning'),
        ExpertRunStatus.planning,
      );
      expect(ExpertRunStatus.fromApiValue('running'), ExpertRunStatus.running);
      expect(
        ExpertRunStatus.fromApiValue('completed'),
        ExpertRunStatus.completed,
      );
      expect(ExpertRunStatus.fromApiValue('failed'), ExpertRunStatus.failed);
      expect(
        ExpertRunStatus.fromApiValue('cancelled'),
        ExpertRunStatus.cancelled,
      );
    });

    test('uses the compatible UI labels for active states', () {
      expect(ExpertRunStatus.draft.label, '准备中');
      expect(ExpertRunStatus.queued.label, '准备中');
      expect(ExpertRunStatus.planning.label, '处理中');
      expect(ExpertRunStatus.running.label, '处理中');
    });

    test('only completed, failed, and cancelled are terminal', () {
      expect(ExpertRunStatus.draft.isTerminal, isFalse);
      expect(ExpertRunStatus.queued.isTerminal, isFalse);
      expect(ExpertRunStatus.planning.isTerminal, isFalse);
      expect(ExpertRunStatus.running.isTerminal, isFalse);
      expect(ExpertRunStatus.completed.isTerminal, isTrue);
      expect(ExpertRunStatus.failed.isTerminal, isTrue);
      expect(ExpertRunStatus.cancelled.isTerminal, isTrue);
    });
  });
}
