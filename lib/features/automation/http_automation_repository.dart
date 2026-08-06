// 自动化规则 HTTP 实现：GET/POST/PATCH /api/v1/automation-rules。

import '../../../core/api/api_client.dart';
import 'automation_repository.dart';

class HttpAutomationRepository implements AutomationRepository {
  HttpAutomationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AutomationRuleDto>> list() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/automation-rules',
      parseData: (value) => value,
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => AutomationRuleDto.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> create({
    required String name,
    required Map<String, dynamic> trigger,
    required List<dynamic> actions,
    String approvalPolicy = 'auto_execute',
  }) async {
    await _api.request<dynamic>(
      method: 'POST',
      path: '/automation-rules',
      body: {
        'name': name,
        'triggerType': 'time_schedule',
        'trigger': trigger,
        'conditions': <dynamic>[],
        'actions': actions,
        'approvalPolicy': approvalPolicy,
        'enabled': true,
      },
      parseData: (_) => null,
    );
  }

  @override
  Future<void> patch({
    required int id,
    required int rowVersion,
    Map<String, dynamic>? trigger,
    List<dynamic>? actions,
    bool? enabled,
  }) async {
    await _api.request<dynamic>(
      method: 'PATCH',
      path: '/automation-rules/$id',
      body: {
        'rowVersion': rowVersion,
        if (trigger != null) 'trigger': trigger,
        if (actions != null) 'actions': actions,
        if (enabled != null) 'enabled': enabled,
      },
      parseData: (_) => null,
    );
  }
}
