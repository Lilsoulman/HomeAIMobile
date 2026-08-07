import 'dto.dart';

abstract class SmartHomeRepository {
  Future<List<SmartHomeSpaceDto>> listSpaces();

  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId});

  Future<List<SmartSceneDto>> listScenes();

  Future<SmartSceneDto> runScene(String key);

  /// 设备健康聚合（B10 发布），可按空间筛选。
  Future<DeviceHealthSummaryDto> fetchDeviceHealthSummary({String? spaceId});

  /// 单台设备健康详情（B14 发布）。
  Future<DeviceHealthDetailDto> fetchDeviceHealth(int deviceId);
}
