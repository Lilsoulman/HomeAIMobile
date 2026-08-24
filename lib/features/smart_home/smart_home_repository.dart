import 'dto.dart';

abstract class SmartHomeRepository {
  Future<List<SmartHomeSpaceDto>> listSpaces();

  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId});

  Future<List<SmartSceneDto>> listScenes();

  Future<SmartSceneDto> runScene(String key);

  Future<DeviceHealthSummaryDto> fetchDeviceHealthSummary({String? spaceId});

  Future<DeviceHealthDetailDto> fetchDeviceHealth(int deviceId);
}

/// Optional aggregate capability for the development mock bootstrap.
abstract class SmartHomeBootstrapRepository {
  Future<SmartHomeBootstrapDto> loadBootstrap();
}
