import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/auth/dto.dart';

void main() {
  test('maps PascalCase user profile response', () {
    final profile = UserProfile.fromJson({
      'Id': 1,
      'DisplayName': 'dd',
      'AvatarUrl': null,
      'Status': 'active',
      'Timezone': 'Asia/Shanghai',
      'Locale': 'zh-CN',
      'CreatedAt': '2026-08-03T22:11:41.662',
    });

    expect(profile.id, 1);
    expect(profile.displayName, 'dd');
    expect(profile.avatarUrl, isNull);
    expect(profile.status, 'active');
    expect(profile.timezone, 'Asia/Shanghai');
    expect(profile.locale, 'zh-CN');
  });
}
