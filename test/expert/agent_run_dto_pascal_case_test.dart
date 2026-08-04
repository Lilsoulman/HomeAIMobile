import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/expert/dto.dart';

void main() {
  group('ExpertRunDto PascalCase / camelCase 兼容', () {
    test('Run 字段兼容 PascalCase', () {
      final dto = ExpertRunDto.fromJson({
        'Id': 9,
        'SourceType': 'expert',
        'Status': 'queued',
        'Mode': 'single',
        'InputJson': '{"request":"hi"}',
        'CreatedAt': '2026-08-04T10:00:00Z',
        'Actions': [
          {
            'Id': 78,
            'Status': 'pending',
            'ActionType': 'smart_home_device',
            'DeviceId': 34,
          },
        ],
      });
      expect(dto.id, 9);
      expect(dto.sourceType, ExpertRunSourceType.expert);
      expect(dto.status, ExpertRunStatus.queued);
      expect(dto.mode, 'single');
      expect(dto.inputJson, '{"request":"hi"}');
      expect(dto.isTeam, isFalse);
      expect(dto.actions, hasLength(1));
      expect(dto.actions.single.deviceId, 34);
    });

    test('Run 字段兼容 camelCase', () {
      final dto = ExpertRunDto.fromJson({
        'id': 9,
        'sourceType': 'group',
        'status': 'planning',
        'mode': 'team',
        'inputJson': '{}',
        'createdAt': '2026-08-04T10:00:00Z',
      });
      expect(dto.sourceType, ExpertRunSourceType.group);
      expect(dto.status, ExpertRunStatus.planning);
      expect(dto.isTeam, isTrue);
    });
  });

  group('ExpertRunActionDto 设备行动字段', () {
    test('PascalCase 解析 device 字段', () {
      final action = ExpertRunActionDto.fromJson({
        'Id': 78,
        'Status': 'pending',
        'ActionType': 'smart_home_device',
        'DeviceId': 34,
        'DeviceName': '卧室主灯',
        'Capability': 'power',
        'TargetValue': false,
        'SpaceName': '主卧',
        'Title': '关闭卧室照明',
        'Description': '睡眠准备建议关闭卧室照明。',
      });
      expect(action.id, 78);
      expect(action.status, 'pending');
      expect(action.actionType, ExpertRunActionType.smartHomeDevices);
      expect(action.deviceId, 34);
      expect(action.deviceName, '卧室主灯');
      expect(action.capability, 'power');
      expect(action.targetValue, false);
      expect(action.spaceName, '主卧');
      expect(action.actionTitle, '关闭卧室照明');
      expect(action.actionDescription, contains('睡眠准备'));
      expect(action.isDeviceAction, isTrue);
    });

    test('camelCase 解析 device 字段', () {
      final action = ExpertRunActionDto.fromJson({
        'id': 1,
        'status': 'pending',
        'actionType': 'smart_home_device',
        'deviceId': 5,
        'deviceName': '客厅主灯',
        'capability': 'brightness',
        'targetValue': 60,
        'spaceName': '客厅',
        'actionTitle': '调暗客厅灯',
        'actionDescription': '观影准备建议调暗客厅灯。',
      });
      expect(action.deviceId, 5);
      expect(action.deviceName, '客厅主灯');
      expect(action.targetValue, 60);
    });
  });
}
