// P2 家庭协同数据层：Dashboard 仓储接口。

import 'dto.dart';

abstract class DashboardRepository {
  Future<DashboardDto> list();
}
