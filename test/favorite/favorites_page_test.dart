// P5b 我的收藏页：列表渲染 / 分类筛选 / 新建与编辑表单 / 删除二次确认 / 导入 / 错误重试。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/favorite/dto.dart';
import 'package:nexus_mind_mobile/features/favorite/favorite_repository.dart';
import 'package:nexus_mind_mobile/pages/profile/favorites_page.dart';
import 'package:provider/provider.dart';

final _now = DateTime.now();

void main() {
  testWidgets('shows empty state', (tester) async {
    final stub = _StubFavoriteRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('还没有收藏，点击右下角新建，或从对话导入。'), findsOneWidget);
  });

  testWidgets('renders items with category, visibility and detail summary', (
    tester,
  ) async {
    final stub = _StubFavoriteRepo(
      items: [
        _favorite(
          id: 1,
          category: FavoriteCategory.restaurant,
          name: '老王面馆',
          visibility: FavoriteVisibility.private,
          detailJson: '{"cuisine":"面食","address":"城西","tags":["面"]}',
        ),
        _favorite(
          id: 2,
          category: FavoriteCategory.travel,
          name: '西湖',
          visibility: FavoriteVisibility.family,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('老王面馆'), findsOneWidget);
    expect(find.text('西湖'), findsOneWidget);
    // 「餐厅/旅行」同时出现在筛选 chip 与列表项分类标签。
    expect(find.text('餐厅'), findsWidgets);
    expect(find.text('旅行'), findsWidgets);
    expect(find.text('仅本人可见'), findsOneWidget);
    expect(find.text('家庭共享'), findsOneWidget);
    expect(find.textContaining('cuisine'), findsOneWidget);
  });

  testWidgets('filters by category', (tester) async {
    final stub = _StubFavoriteRepo(
      items: [
        _favorite(id: 1, category: FavoriteCategory.restaurant, name: '老王面馆'),
        _favorite(id: 2, category: FavoriteCategory.travel, name: '西湖'),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilterChip, '旅行'));
    await tester.pump();

    expect(find.text('西湖'), findsOneWidget);
    expect(find.text('老王面馆'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, '全部'));
    await tester.pump();

    expect(find.text('老王面馆'), findsOneWidget);
  });

  testWidgets('creates favorite via form', (tester) async {
    final stub = _StubFavoriteRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '名称'), '老王面馆');
    await tester.enterText(
      find.widgetWithText(TextField, '详情（可选）'),
      '{"cuisine":"面食"}',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump();

    expect(stub.createCalls, hasLength(1));
    expect(stub.createCalls.single.$1, FavoriteCategory.restaurant);
    expect(stub.createCalls.single.$2, '老王面馆');
    expect(stub.createCalls.single.$3, '{"cuisine":"面食"}');
    expect(stub.createCalls.single.$4, FavoriteVisibility.private);
  });

  testWidgets('rejects invalid detail json', (tester) async {
    final stub = _StubFavoriteRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '名称'), '老王面馆');
    await tester.enterText(find.widgetWithText(TextField, '详情（可选）'), '{bad');
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(find.text('详情必须是合法 JSON 或留空'), findsOneWidget);
    expect(stub.createCalls, isEmpty);
  });

  testWidgets('edits existing favorite with prefilled form', (tester) async {
    final stub = _StubFavoriteRepo(
      items: [
        _favorite(id: 1, category: FavoriteCategory.restaurant, name: '老王面馆'),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('老王面馆'));
    await tester.pump();
    await tester.pump();

    expect(find.text('编辑收藏'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '名称'), '老王面馆（新址）');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump();

    expect(stub.updateCalls, hasLength(1));
    expect(stub.updateCalls.single.$1, 1);
    expect(stub.updateCalls.single.$2.$2, '老王面馆（新址）');
  });

  testWidgets('delete requires confirmation', (tester) async {
    final stub = _StubFavoriteRepo(
      items: [_favorite(id: 1, category: FavoriteCategory.travel, name: '西湖')],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    await tester.pump();

    expect(find.text('删除收藏'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pump();
    await tester.pump();

    expect(stub.deleteIds, [1]);
  });

  testWidgets('imports favorite with source and conversation', (tester) async {
    final stub = _StubFavoriteRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.byTooltip('导入'));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '名称'), '灵感笔记');
    await tester.enterText(find.widgetWithText(TextField, '来源（必填）'), '小红书');
    await tester.enterText(find.widgetWithText(TextField, '对话原文（可选）'), '这家店不错');
    await tester.tap(find.text('导入'));
    await tester.pump();
    await tester.pump();

    expect(stub.importCalls, hasLength(1));
    expect(stub.importCalls.single.$2, '灵感笔记');
    expect(stub.importCalls.single.$3, '小红书');
    expect(stub.importCalls.single.$4, '这家店不错');
  });

  testWidgets('shows error state and retries loading', (tester) async {
    final stub = _StubFavoriteRepo(items: [], failList: true);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('收藏暂时无法加载。'), findsOneWidget);

    stub.failList = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(find.text('还没有收藏，点击右下角新建，或从对话导入。'), findsOneWidget);
  });
}

Widget _wrap(FavoriteRepository repository) =>
    Provider<FavoriteRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: NexusTheme.light(NexusPalette.aiAccent),
        home: const FavoritesPage(),
      ),
    );

FavoriteDto _favorite({
  required int id,
  required FavoriteCategory category,
  required String name,
  FavoriteVisibility visibility = FavoriteVisibility.private,
  String? detailJson,
}) => FavoriteDto(
  id: id,
  ownerMemberId: 1,
  category: category,
  name: name,
  detailJson: detailJson,
  visibility: visibility,
  createdAt: _now,
  updatedAt: _now,
);

typedef _FormCall = (FavoriteCategory, String, String?, FavoriteVisibility);

class _StubFavoriteRepo implements FavoriteRepository {
  _StubFavoriteRepo({required this.items, this.failList = false});

  List<FavoriteDto> items;
  bool failList;
  final createCalls = <_FormCall>[];
  final updateCalls = <(int, _FormCall)>[];
  final deleteIds = <int>[];
  final importCalls = <(FavoriteCategory, String, String, String?)>[];

  @override
  Future<List<FavoriteDto>> list({String? category, String? visibility}) async {
    if (failList) throw StateError('unavailable');
    return items;
  }

  @override
  Future<FavoriteDto> create({
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    FavoriteVisibility visibility = FavoriteVisibility.private,
  }) async {
    createCalls.add((category, name, detailJson, visibility));
    return _favorite(
      id: 99,
      category: category,
      name: name,
      detailJson: detailJson,
      visibility: visibility,
    );
  }

  @override
  Future<FavoriteDto> update(
    int id, {
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    required FavoriteVisibility visibility,
  }) async {
    updateCalls.add((id, (category, name, detailJson, visibility)));
    return _favorite(
      id: id,
      category: category,
      name: name,
      detailJson: detailJson,
      visibility: visibility,
    );
  }

  @override
  Future<void> delete(int id) async {
    deleteIds.add(id);
    items = items.where((item) => item.id != id).toList();
  }

  @override
  Future<FavoriteDto> import({
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    FavoriteVisibility visibility = FavoriteVisibility.private,
    required String source,
    String? conversationText,
  }) async {
    importCalls.add((category, name, source, conversationText));
    return _favorite(id: 100, category: category, name: name);
  }
}
