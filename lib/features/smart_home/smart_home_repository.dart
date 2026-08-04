import 'dto.dart';

abstract class SmartHomeRepository {
  Future<List<SmartHomeSpaceDto>> listSpaces();

  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId});

  Future<List<SmartSceneDto>> listScenes();

  Future<SmartSceneDto> runScene(String key);
}
