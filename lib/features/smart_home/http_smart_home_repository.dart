import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import 'dto.dart';
import 'smart_home_repository.dart';

class HttpSmartHomeRepository implements SmartHomeRepository {
  HttpSmartHomeRepository(this._api, {Uuid? uuid}) : _uuid = uuid ?? Uuid();

  final ApiClient _api;
  final Uuid _uuid;

  @override
  Future<List<SmartHomeSpaceDto>> listSpaces() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/smart-home/spaces',
      parseData: (value) => value,
    );
    return _asList(raw).map(SmartHomeSpaceDto.fromJson).toList();
  }

  @override
  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId}) async {
    final query = <String, dynamic>{};
    if (spaceId != null && spaceId.isNotEmpty) query['spaceId'] = spaceId;
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/smart-home/devices',
      query: query,
      parseData: (value) => value,
    );
    return _asList(raw).map(SmartHomeDeviceDto.fromJson).toList();
  }

  @override
  Future<List<SmartSceneDto>> listScenes() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/smart-home/scenes',
      parseData: (value) => value,
    );
    return _asList(raw).map(SmartSceneDto.fromJson).toList();
  }

  @override
  Future<DeviceHealthSummaryDto> fetchDeviceHealthSummary({
    String? spaceId,
  }) async {
    final query = <String, dynamic>{};
    if (spaceId != null && spaceId.isNotEmpty) query['spaceId'] = spaceId;
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/smart-home/devices/health',
      query: query,
      parseData: (value) => value,
    );
    return DeviceHealthSummaryDto.fromJson(_asMap(raw));
  }

  @override
  Future<DeviceHealthDetailDto> fetchDeviceHealth(int deviceId) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/smart-home/devices/$deviceId/health',
      parseData: (value) => value,
    );
    return DeviceHealthDetailDto.fromJson(_asMap(raw));
  }

  @override
  Future<SmartSceneDto> runScene(String key) async {
    await _api.request<dynamic>(
      method: 'POST',
      path: '/smart-home/scenes/$key/run',
      body: {'idempotencyKey': _uuid.v4()},
      parseData: (value) => value,
    );
    final scenes = await listScenes();
    return scenes.firstWhere(
      (scene) => scene.key == key,
      orElse: () => throw StateError('未找到场景'),
    );
  }

  static List<Map<String, dynamic>> _asList(dynamic raw) {
    final items = raw is List
        ? raw
        : raw is Map && raw['items'] is List
        ? raw['items'] as List
        : const [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  static Map<String, dynamic> _asMap(dynamic raw) =>
      (raw as Map).cast<String, dynamic>();
}
