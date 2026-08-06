import 'package:flutter_test/flutter_test.dart';

import 'package:nexus_mind_mobile/features/ai/ai_repository.dart';

void main() {
  group('AiConfig.fromJson', () {
    test('解析 PascalCase 契约字段（8.14 后端返回）', () {
      final config = AiConfig.fromJson(const {
        'Endpoint': 'https://api.deepseek.com/',
        'Model': 'deepseek-v4-flash',
        'Temperature': 0.7,
        'HasApiKey': true,
      });
      expect(config.endpoint, 'https://api.deepseek.com/');
      expect(config.model, 'deepseek-v4-flash');
      expect(config.temperature, 0.7);
      expect(config.hasApiKey, isTrue);
      expect(config.enabled, isTrue);
    });

    test('兼容 camelCase 字段兜底', () {
      final config = AiConfig.fromJson(const {
        'endpoint': 'https://api.openai.com/v1',
        'model': 'gpt-4.1-mini',
        'temperature': 0.3,
        'hasApiKey': true,
        'enabled': false,
      });
      expect(config.endpoint, 'https://api.openai.com/v1');
      expect(config.model, 'gpt-4.1-mini');
      expect(config.temperature, 0.3);
      expect(config.hasApiKey, isTrue);
      expect(config.enabled, isFalse);
    });

    test('空 JSON 使用默认值', () {
      final config = AiConfig.fromJson(const {});
      expect(config.endpoint, isNull);
      expect(config.model, isNull);
      expect(config.temperature, 0.7);
      expect(config.hasApiKey, isFalse);
      expect(config.enabled, isTrue);
    });
  });
}
