import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'dto.dart';
import 'smart_home_repository.dart';

class HttpSmartHomeRepository
    implements SmartHomeRepository, SmartHomeBootstrapRepository {
  HttpSmartHomeRepository(
    this._api, {
    Uuid? uuid,
    this.useMockBootstrap = false,
  }) : _uuid = uuid ?? Uuid();

  final ApiClient _api;
  final Uuid _uuid;
  final bool useMockBootstrap;

  @override
  Future<SmartHomeBootstrapDto> loadBootstrap() async {
    if (!useMockBootstrap) return _loadFromReadEndpoints();
    try {
      final raw = await _api.request<dynamic>(
        method: 'GET',
        path: '/smart-home/mock/bootstrap',
        parseData: (value) => value,
      );
      return SmartHomeBootstrapDto.fromJson(_asMap(raw));
    } on ApiException catch (error) {
      if (error.code != 503) rethrow;
      return _loadFromReadEndpoints();
    }
  }

  Future<SmartHomeBootstrapDto> _loadFromReadEndpoints() async {
    final spaces = await listSpaces();
    final results = await Future.wait<Object>([
      listDevices(),
      listScenes(),
      Future.wait(
        spaces.map(
          (space) async => MapEntry(space.id, await _safeHealth(space.id)),
        ),
      ),
    ]);
    final healthBySpace =
        results[2] as List<MapEntry<String, DeviceHealthSummaryDto>>;
    return SmartHomeBootstrapDto(
      isMock: false,
      disclaimer: null,
      generatedAt: DateTime.now().toUtc(),
      spaces: spaces,
      devices: results[0] as List<SmartHomeDeviceDto>,
      scenes: results[1] as List<SmartSceneDto>,
      deviceHealth: _sumHealth(healthBySpace.map((entry) => entry.value)),
    );
  }

  Future<DeviceHealthSummaryDto> _safeHealth(String spaceId) async {
    try {
      return await fetchDeviceHealthSummary(spaceId: spaceId);
    } catch (_) {
      return const DeviceHealthSummaryDto(
        total: 0,
        healthy: 0,
        degraded: 0,
        offline: 0,
        lowBattery: 0,
      );
    }
  }

  DeviceHealthSummaryDto _sumHealth(Iterable<DeviceHealthSummaryDto> values) {
    var total = 0;
    var healthy = 0;
    var degraded = 0;
    var offline = 0;
    var lowBattery = 0;
    for (final value in values) {
      total += value.total;
      healthy += value.healthy;
      degraded += value.degraded;
      offline += value.offline;
      lowBattery += value.lowBattery;
    }
    return DeviceHealthSummaryDto(
      total: total,
      healthy: healthy,
      degraded: degraded,
      offline: offline,
      lowBattery: lowBattery,
    );
  }

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
