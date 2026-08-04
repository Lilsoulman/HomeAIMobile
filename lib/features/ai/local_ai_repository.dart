import 'ai_repository.dart';

class LocalAiRepository implements AiRepository {
  AiConfig _config = const AiConfig(
    endpoint: 'local://nexus-mind',
    model: 'offline-preview',
    hasApiKey: true,
  );

  @override
  Future<AiConfig> getConfig() async => _config;

  @override
  Future<AiGenerateResult> generate({
    required String scope,
    required String prompt,
    required String input,
  }) async {
    final normalized = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(3)
        .join('\n');
    final content = switch (scope) {
      'import' => _importResult(input),
      'week' =>
        '## 本周复盘\n\n- 完成事项：请根据待办记录补充。\n- 风险：优先处理临近截止项。\n- 下周行动：确定三项最重要成果。',
      'day' =>
        '## 今日日报\n\n- 完成事项：请记录今天已完成的工作。\n- 阻塞：标记需要协助的事项。\n- 明日行动：选择一个明确的下一步。',
      'expert_workspace' => _expertWorkspaceResult(input),
      _ => '本地预览结果\n\n$normalized',
    };
    return AiGenerateResult(content: content, totalTokens: content.length);
  }

  String _importResult(String input) {
    final items = input
        .split(RegExp(r'\r?\n|[；;]'))
        .map((line) => line.replaceFirst(RegExp(r'^[-*•\d.\s]+'), '').trim())
        .where((line) => line.isNotEmpty)
        .take(20)
        .map((line) => '- $line')
        .join('\n');
    return items.isEmpty ? '未从输入中提取到待办。' : items;
  }

  String _expertWorkspaceResult(String input) {
    final latest = input
        .split(RegExp(r'\r?\n'))
        .lastWhere((line) => line.startsWith('用户：'), orElse: () => input)
        .replaceFirst('用户：', '')
        .trim();
    return '我已结合当前人设、资料夹和对话记录理解你的需求。\n\n'
        '关于“$latest”，建议先明确目标读者、想传递的一个核心信息和本次内容的行动目标。\n\n'
        '你可以把相关草稿放进资料夹，我会继续帮你逐段编辑与优化。';
  }

  @override
  Future<void> testConnection() async {}

  @override
  Future<AiConfig> updateConfig({
    required String endpoint,
    required String model,
    required double temperature,
    String? apiKey,
  }) async {
    _config = AiConfig(
      endpoint: endpoint,
      model: model,
      temperature: temperature,
      hasApiKey: apiKey?.trim().isNotEmpty ?? _config.hasApiKey,
    );
    return _config;
  }
}
