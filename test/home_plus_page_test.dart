import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/smart_home/local_smart_home_repository.dart';
import 'package:nexus_mind_mobile/features/smart_home/smart_home_repository.dart';
import 'package:nexus_mind_mobile/pages/home_plus_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('home scene requires confirmation before it runs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = LocalSmartHomeRepository();

    await tester.pumpWidget(
      Provider<SmartHomeRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: NexusTheme.light(NexusPalette.aiAccent),
          home: const HomePlusPage(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('执行睡眠'));
    await tester.pumpAndSettle();
    expect(find.text('确认执行“睡眠”'), findsOneWidget);

    await tester.tap(find.text('确认执行'));
    await tester.pumpAndSettle();

    expect(
      (await repository.listScenes())
          .singleWhere((scene) => scene.key == 'sleep')
          .lastRunAt,
      isNotNull,
    );
  });
}
