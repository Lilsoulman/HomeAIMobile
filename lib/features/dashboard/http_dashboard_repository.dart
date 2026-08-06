// P2 家庭协同数据层：Dashboard HTTP 实现。
// 路由 `api/v1/dashboard`，租户由 JWT 推导，客户端不发送家庭 ID。

import '../../../core/api/api_client.dart';
import 'dashboard_repository.dart';
import 'dto.dart';

class HttpDashboardRepository implements DashboardRepository {
  HttpDashboardRepository(this._api);
  final ApiClient _api;

  @override
  Future<DashboardDto> list() async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/dashboard',
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return DashboardDto.fromJson(json);
  }
}
