import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads API configuration from environment values', () async {
    SharedPreferences.setMockInitialValues({});

    final env = await EnvConfig.init(
      fileValues: const {'API_BASE_URL': 'http://localhost:5280/'},
    );

    expect(env.baseUrl, 'http://localhost:5280');
    expect(env.apiPrefix, 'http://localhost:5280/api/v1');
  });

  test('loads the bundled environment configuration by default', () async {
    SharedPreferences.setMockInitialValues({});

    final env = await EnvConfig.init();

    expect(env.baseUrl, 'http://150.158.106.238');
  });

  test('parses comments, whitespace, and quoted dotenv values', () {
    final values = EnvConfig.parseDotEnv('''
# Connection settings
API_BASE_URL = "http://192.168.1.10:5280"
IGNORED_LINE
''');

    expect(values, {'API_BASE_URL': 'http://192.168.1.10:5280'});
  });
}
