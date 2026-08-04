import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/expert/dto.dart';

void main() {
  group('ExpertRunActionType 四种枚举', () {
    test('apiValue 与后端契约一致', () {
      expect(ExpertRunActionType.plan.apiValue, 'plan');
      expect(ExpertRunActionType.todos.apiValue, 'todos');
      expect(ExpertRunActionType.calendarEvents.apiValue, 'calendar_events');
      expect(
        ExpertRunActionType.smartHomeDevices.apiValue,
        'smart_home_device',
      );
    });

    test('label 提供可读中文', () {
      expect(ExpertRunActionType.plan.label, '加入计划');
      expect(ExpertRunActionType.todos.label, '创建任务');
      expect(ExpertRunActionType.calendarEvents.label, '创建日程');
      expect(ExpertRunActionType.smartHomeDevices.label, '设备行动');
    });

    test('fromApiValue 兼容 PascalCase 与 camelCase', () {
      expect(
        ExpertRunActionType.fromApiValue('smart_home_device'),
        ExpertRunActionType.smartHomeDevices,
      );
      expect(
        ExpertRunActionType.fromApiValue('smartHomeDevices'),
        ExpertRunActionType.smartHomeDevices,
      );
      expect(
        ExpertRunActionType.fromApiValue('calendar_events'),
        ExpertRunActionType.calendarEvents,
      );
      expect(
        ExpertRunActionType.fromApiValue('calendarEvents'),
        ExpertRunActionType.calendarEvents,
      );
    });

    test('未知值降级为 plan', () {
      expect(
        ExpertRunActionType.fromApiValue('unknown'),
        ExpertRunActionType.plan,
      );
    });
  });
}
