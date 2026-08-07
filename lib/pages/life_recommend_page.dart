// P5c 探店翻牌页（B16，Intent: recommend，只读 L1 无确认动作）。
// time 快捷值对齐契约 morning/noon/evening；每次提交使用新的幂等键；
// 不渲染提示、思考链、Events 时间线或 FavoriteId。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/life/dto.dart';
import '../features/life/life_expert_repository.dart';

class LifeRecommendPage extends StatefulWidget {
  const LifeRecommendPage({super.key});

  @override
  State<LifeRecommendPage> createState() => _LifeRecommendPageState();
}

class _LifeRecommendPageState extends State<LifeRecommendPage> {
  static const _timePresets = [
    ('morning', '早上'),
    ('noon', '中午'),
    ('evening', '傍晚'),
  ];

  final _time = TextEditingController();
  final _location = TextEditingController();
  final _taste = TextEditingController();
  bool _loading = false;
  String? _error;
  LifeRecommendResultDto? _result;

  @override
  void dispose() {
    _time.dispose();
    _location.dispose();
    _taste.dispose();
    super.dispose();
  }

  Future<void> _flip() async {
    final time = _time.text.trim();
    final location = _location.text.trim();
    final taste = _taste.text.trim();
    if (time.isEmpty || location.isEmpty || taste.isEmpty) {
      _showError('请填写时间、位置与口味');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await context.read<LifeExpertRepository>().recommend(
        time: time,
        location: location,
        taste: taste,
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendly(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _result?.recommendations ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('探店翻牌')),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: NexusLayout.pagePadding.copyWith(
            bottom: NexusLayout.bottomContentPadding,
          ),
          children: [
            NexusPageHeader(
              title: '探店翻牌',
              description: '告诉我时间、位置与口味，为你翻出合适的店。',
            ),
            const SizedBox(height: NexusLayout.sectionGap),
            NexusSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _time,
                    decoration: const InputDecoration(
                      labelText: '时间',
                      hintText: '例如：evening',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (value, label) in _timePresets)
                        ActionChip(
                          label: Text(label),
                          onPressed: () => setState(() => _time.text = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _location,
                    decoration: const InputDecoration(labelText: '位置'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _taste,
                    decoration: const InputDecoration(labelText: '口味'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _flip,
                      child: Text(_loading ? '翻牌中…' : '翻一张'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NexusLayout.sectionGap),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              NexusSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: _flip, child: const Text('重试')),
                  ],
                ),
              )
            else if (_result != null && recommendations.isEmpty)
              NexusSurface(
                padding: const EdgeInsets.all(20),
                child: const Text('没有翻到合适的店，换个条件再试试。'),
              )
            else if (_result != null) ...[
              ...recommendations.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: NexusLayout.itemGap),
                  child: _RecommendationCard(item: item),
                ),
              ),
              const SizedBox(height: NexusLayout.itemGap),
              OutlinedButton.icon(
                onPressed: _loading ? null : _flip,
                icon: const Icon(Icons.style_outlined),
                label: const Text('再翻一张'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final LifeRecommendationDto item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name, style: theme.textTheme.titleLarge),
              ),
              Icon(Icons.storefront_outlined, color: theme.colorScheme.primary),
            ],
          ),
          if (item.reason != null && item.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.reason!),
          ],
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in item.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _friendly(Object error) =>
    error is ApiException && error.msg.isNotEmpty ? error.msg : '$error';
