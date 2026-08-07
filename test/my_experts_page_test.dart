// B21 我的专家页：scope=mine 列表状态、新建/编辑表单校验与保存、删除确认。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/experts/domain.dart';
import 'package:nexus_mind_mobile/experts/expert_repository.dart';
import 'package:nexus_mind_mobile/pages/my_experts_page.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('我的专家', () {
    testWidgets('renders mine list', (tester) async {
      final repo = _StubExpertRepo()..mine = [_expert('3', '我的助手', 'travel')];
      await _pump(tester, repo);

      expect(find.text('我的专家'), findsOneWidget);
      expect(find.text('我的助手'), findsOneWidget);
      expect(find.text('travel'), findsOneWidget);
    });

    testWidgets('shows empty and error with retry', (tester) async {
      final repo = _StubExpertRepo();
      await _pump(tester, repo);

      expect(find.text('还没有自建专家，点击「新建专家」创建。'), findsOneWidget);
    });

    testWidgets('shows error with retry', (tester) async {
      final repo = _StubExpertRepo()..failList = true;
      await _pump(tester, repo);

      expect(find.text('自建专家暂时无法加载。'), findsOneWidget);

      repo.failList = false;
      repo.mine = [_expert('3', '我的助手', 'travel')];
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('我的助手'), findsOneWidget);
    });

    testWidgets('creates expert with form validation and save', (tester) async {
      final repo = _StubExpertRepo();
      await _pump(tester, repo);

      await tester.tap(find.text('新建专家'));
      await tester.pumpAndSettle();

      // 必填校验：直接点保存应提示。
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请填写名称'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '名称').first,
        '我的助手',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '分类').first,
        'travel',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '人格设定').first,
        '你是我的旅行助手',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '提示词模板').first,
        '请按模板回答',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(repo.createdName, '我的助手');
      expect(find.text('我的助手'), findsOneWidget);
    });

    testWidgets('validates tool policy JSON locally', (tester) async {
      final repo = _StubExpertRepo();
      await _pump(tester, repo);

      await tester.tap(find.text('新建专家'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称').first,
        'x',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '分类').first,
        'travel',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '人格设定').first,
        'p',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '提示词模板').first,
        't',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '工具策略（JSON）').first,
        'not-json',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('工具策略必须是合法 JSON'), findsOneWidget);
      expect(repo.createdName, isNull);
    });

    testWidgets('deletes expert after confirmation', (tester) async {
      final repo = _StubExpertRepo()..mine = [_expert('3', '我的助手', 'travel')];
      await _pump(tester, repo);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(repo.deletedIds, ['3']);
      expect(find.text('还没有自建专家，点击「新建专家」创建。'), findsOneWidget);
    });

    testWidgets('edits expert with detail prefilled', (tester) async {
      final repo = _StubExpertRepo()..mine = [_expert('3', '我的助手', 'travel')];
      await _pump(tester, repo);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('编辑专家'), findsOneWidget);
      // 详情回填。
      expect(find.widgetWithText(TextFormField, '人格设定').first, findsOneWidget);
      final persona = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, '人格设定').first,
      );
      expect(persona.controller?.text, '你是我的旅行助手…');
    });
  });
}

Future<void> _pump(WidgetTester tester, _StubExpertRepo repo) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MultiProvider(
      providers: [Provider<ExpertRepository>.value(value: repo)],
      child: const MaterialApp(home: MyExpertsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Expert _expert(String id, String name, String category) => Expert(
  id: id,
  sourceType: ExpertSourceType.expert,
  name: name,
  category: category,
  description: '',
  estimatedCredits: 1,
  source: ExpertSource.mine,
);

class _StubExpertRepo implements ExpertRepository {
  List<Expert> mine = [];
  bool failList = false;
  String? createdName;
  List<String> deletedIds = [];
  int updateRowVersion = -1;

  @override
  Future<List<Expert>> listExperts({String query = '', String? scope}) async {
    if (failList) throw Exception('network');
    return scope == 'mine' ? mine : [];
  }

  @override
  Future<Expert?> getExpert(
    String id, {
    required ExpertSourceType sourceType,
  }) async => null;

  @override
  Future<ExpertDetail?> getExpertDetail(
    String id, {
    required ExpertSourceType sourceType,
  }) async => ExpertDetail(
    id: id,
    name: '我的助手',
    category: 'travel',
    description: '',
    estimatedCredits: 1,
    source: ExpertSource.mine,
    persona: '你是我的旅行助手…',
    methodology: '分步给出方案',
    promptTemplate: '请按模板回答',
    rowVersion: 2,
  );

  @override
  Future<Expert> createExpert({
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  }) async {
    createdName = name;
    return _expert('99', name, category);
  }

  @override
  Future<Expert> updateExpert({
    required String id,
    required int rowVersion,
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  }) async {
    updateRowVersion = rowVersion;
    return _expert(id, name, category);
  }

  @override
  Future<void> deleteExpert(String id) async => deletedIds.add(id);
}
