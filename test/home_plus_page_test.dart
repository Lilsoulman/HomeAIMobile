import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/smart_home/dto.dart';
import 'package:nexus_mind_mobile/features/smart_home/smart_home_repository.dart';
import 'package:nexus_mind_mobile/pages/home_plus_page.dart';
import 'package:provider/provider.dart';

class _Repo implements SmartHomeRepository {
  DateTime? _lastRun;
  List<SmartSceneDto> _scenes = [
    SmartSceneDto(
      key: 'sleep',
      name: '睡眠',
      description: '关闭所有灯光，启动睡眠模式',
      requiresConfirmation: true,
    ),
  ];

  @override
  Future<List<SmartHomeSpaceDto>> listSpaces() async => [
    SmartHomeSpaceDto(
      id: '1',
      name: '客厅',
      type: 'room',
      summary: '灯光舒适',
      sortOrder: 0,
    ),
  ];
  @override
  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId}) async => [];
  @override
  Future<List<SmartSceneDto>> listScenes() async => _scenes;
  @override
  Future<SmartSceneDto> runScene(String key) async {
    _lastRun = DateTime.now();
    return _scenes
        .singleWhere((s) => s.key == key)
        .copyWith(lastRunAt: _lastRun);
  }
}

void main() {
  testWidgets('home scene requires confirmation before it runs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Repo();

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
    await tester.pump(const Duration(milliseconds: 100));

    // 先确认场景"睡眠"在页面上
    expect(find.text('睡眠'), findsOneWidget);

    await tester.tap(find.byTooltip('执行睡眠'));
    await tester.pumpAndSettle();
    expect(find.text('确认执行"睡眠"'), findsOneWidget);

    await tester.tap(find.text('确认执行'));
    await tester.pumpAndSettle();

    expect(repository._lastRun, isNotNull);
  });
}
