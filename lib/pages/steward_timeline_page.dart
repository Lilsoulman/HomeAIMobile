// P5 管家动态时间线页：游标分页展示家庭级管家动态（loading/empty/error/retry）。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui/nexus_theme.dart';
import '../features/steward/dto.dart';
import '../features/steward/steward_repository.dart';
import '../widgets/steward_timeline_tile.dart';

class StewardTimelinePage extends StatefulWidget {
  const StewardTimelinePage({super.key});

  @override
  State<StewardTimelinePage> createState() => _StewardTimelinePageState();
}

class _StewardTimelinePageState extends State<StewardTimelinePage> {
  final List<StewardActivityDto> _items = [];
  String? _cursor;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _reload();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.removeListener(_maybeLoadMore);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<StewardRepository>().listActivities(
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _cursor = page.cursor;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _maybeLoadMore() {
    if (_cursor == null ||
        _loadingMore ||
        !_scroll.hasClients ||
        _scroll.position.extentAfter > 200) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await context.read<StewardRepository>().listActivities(
        limit: 20,
        cursor: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.cursor;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管家动态')),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36),
            const SizedBox(height: 12),
            const Text('管家动态暂时无法加载。'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('还没有管家动态。'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: NexusLayout.pagePadding.copyWith(bottom: 36),
        itemCount: _items.length + (_cursor != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final activity = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StewardTimelineTile(
              category: activity.category,
              title: activity.title,
              summary: activity.description ?? activity.resultSummary,
              time: activity.createdAt,
              riskLevel: activity.riskLevel,
            ),
          );
        },
      ),
    );
  }
}
