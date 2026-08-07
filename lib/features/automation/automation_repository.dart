// 自动化规则仓储接口：推送时间的用户自配置（复用 automation-rules API）。

class AutomationRuleDto {
  const AutomationRuleDto({
    required this.id,
    required this.name,
    required this.triggerConfig,
    required this.actions,
    required this.rowVersion,
    this.enabled = true,
  });

  factory AutomationRuleDto.fromJson(Map<String, dynamic> json) {
    final trigger = json['TriggerConfig'] ?? json['triggerConfig'];
    final actions = json['Actions'] ?? json['actions'];
    return AutomationRuleDto(
      id: (json['Id'] ?? json['id'] as num?)?.toInt() ?? 0,
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      triggerConfig: trigger is Map
          ? trigger.cast<String, dynamic>()
          : <String, dynamic>{},
      actions: actions is List ? actions : const [],
      rowVersion:
          (json['RowVersion'] ?? json['rowVersion'] as num?)?.toInt() ?? 1,
      enabled: (json['Enabled'] ?? json['enabled'] ?? true) == true,
    );
  }

  final int id;
  final String name;
  final Map<String, dynamic> triggerConfig;
  final List<dynamic> actions;
  final int rowVersion;
  final bool enabled;
}

abstract class AutomationRepository {
  Future<List<AutomationRuleDto>> list();
  Future<void> create({
    required String name,
    required Map<String, dynamic> trigger,
    required List<dynamic> actions,
    String approvalPolicy = 'auto_execute',
  });
  Future<void> patch({
    required int id,
    required int rowVersion,
    Map<String, dynamic>? trigger,
    List<dynamic>? actions,
    bool? enabled,
  });
}
