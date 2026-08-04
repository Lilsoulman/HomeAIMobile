import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/ai/local_ai_repository.dart';
import 'package:nexus_mind_mobile/features/auth/local_auth_repository.dart';
import 'package:nexus_mind_mobile/features/calendar/local_calendar_repository.dart';
import 'package:nexus_mind_mobile/features/connector/dto.dart';
import 'package:nexus_mind_mobile/features/connector/local_connector_repository.dart';
import 'package:nexus_mind_mobile/features/skill/local_skill_repository.dart';
import 'package:nexus_mind_mobile/features/smart_home/local_smart_home_repository.dart';
import 'package:nexus_mind_mobile/features/todo/dto.dart';
import 'package:nexus_mind_mobile/features/todo/local_todo_repository.dart';

void main() {
  group('LocalAuthRepository', () {
    test(
      'creates a local session and exposes the registered profile',
      () async {
        final repository = LocalAuthRepository();
        final session = await repository.register(
          phone: '13800138000',
          password: 'ignored-offline',
          displayName: 'Local tester',
        );

        expect(session.userId, 1);
        expect((await repository.me()).displayName, 'Local tester');
      },
    );
  });

  group('LocalTodoRepository', () {
    test(
      'persists edits and subtask completion for the current session',
      () async {
        final repository = LocalTodoRepository();
        final todo = await repository.create(
          title: 'Write local repository tests',
        );
        final subtask = await repository.addSubtask(
          todo.id,
          text: 'Cover create',
        );
        expect((await repository.listSubtasks(todo.id)).single.id, subtask.id);

        await repository.update(todo.id, {'status': 'completed'});
        final updatedSubtask = await repository.updateSubtask(
          todo.id,
          subtask.id,
          {'done': true},
        );
        final todos = await repository.list(status: 'completed');

        expect(todos.map((item) => item.id), contains(todo.id));
        expect(
          todos.singleWhere((item) => item.id == todo.id).status,
          TodoStatus.completed,
        );
        expect(updatedSubtask.done, isTrue);
      },
    );
  });

  group('LocalCalendarRepository', () {
    test(
      'filters events by the requested time window and validates subscriptions',
      () async {
        final repository = LocalCalendarRepository();
        final start = DateTime(2030, 1, 2, 9);
        final event = await repository.createEvent(
          title: 'Local calendar event',
          startAt: start,
          endAt: start.add(const Duration(hours: 1)),
        );

        final matching = await repository.listEvents(
          from: start.subtract(const Duration(minutes: 1)),
          to: start.add(const Duration(minutes: 1)),
        );
        expect(matching.map((item) => item.id), contains(event.id));
        await expectLater(
          repository.createSubscription(url: 'not-a-url'),
          throwsArgumentError,
        );
      },
    );
  });

  group('Local AI and Skills', () {
    test('returns deterministic import output and editable skills', () async {
      final ai = LocalAiRepository();
      final result = await ai.generate(
        scope: 'import',
        prompt: 'Extract todos',
        input: 'Prepare demo\n- Review release checklist',
      );
      final skills = LocalSkillRepository();
      final created = await skills.create(
        name: 'Project summary',
        prompt: 'Summarize the project.',
      );
      await skills.update(created.id, {'isActive': false});

      expect(result.content, contains('Prepare demo'));
      expect(
        (await skills.list())
            .singleWhere((item) => item.id == created.id)
            .isActive,
        isFalse,
      );
    });
  });

  group('LocalSmartHomeRepository', () {
    test('lists normalized spaces and records a scene execution', () async {
      final repository = LocalSmartHomeRepository();

      final spaces = await repository.listSpaces();
      final devices = await repository.listDevices(spaceId: spaces.first.id);
      final scene = await repository.runScene('sleep');

      expect(spaces.first.name, '客厅');
      expect(devices, isNotEmpty);
      expect(scene.lastRunAt, isNotNull);
      expect(
        (await repository.listScenes())
            .singleWhere((item) => item.key == 'sleep')
            .lastRunAt,
        isNotNull,
      );
    });
  });

  group('LocalConnectorRepository', () {
    test(
      'keeps connector commands within normalized connection states',
      () async {
        final repository = LocalConnectorRepository();

        final connectors = await repository.listConnectors();
        expect(
          connectors.map((connector) => connector.status),
          containsAll(ConnectorConnectionStatus.values),
        );

        final disconnected = connectors.singleWhere(
          (connector) => connector.id == 'weather',
        );
        final authorizing = await repository.beginAuthorization(
          disconnected.providerKey,
        );
        final reconnected = await repository.retry(authorizing.id);
        final discovering = await repository.discover(reconnected.id);
        final disconnectedAgain = await repository.disconnect(discovering.id);

        expect(authorizing.status, ConnectorConnectionStatus.authorizing);
        expect(reconnected.status, ConnectorConnectionStatus.online);
        expect(discovering.status, ConnectorConnectionStatus.discovering);
        expect(
          disconnectedAgain.status,
          ConnectorConnectionStatus.disconnected,
        );
        expect(
          (await repository.listProviders()).map((provider) => provider.key),
          contains('family-notes'),
        );
      },
    );
  });
}
