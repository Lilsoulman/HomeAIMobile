import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/courier/courier_repository.dart';
import '../features/courier/dto.dart';

class CourierPage extends StatefulWidget {
  const CourierPage({super.key});

  @override
  State<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends State<CourierPage> {
  late Future<_CourierData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<_CourierData> _load() async {
    final repository = context.read<CourierRepository>();
    final values = await Future.wait<Object>([
      repository.listShipments(),
      repository.listAnomalies(),
    ]);
    return _CourierData(
      shipments: values[0] as List<CourierShipmentDto>,
      anomalies: values[1] as List<CourierAnomalyDto>,
    );
  }

  Future<void> _create() async {
    final request = await showDialog<CourierShipmentCreateDto>(
      context: context,
      builder: (_) => const _CourierDialog(),
    );
    if (request == null || !mounted) return;
    await _run(() async {
      await context.read<CourierRepository>().createShipment(request);
      _message('运单已登记，稍后可刷新物流状态。');
      _reload();
    });
  }

  Future<void> _refresh(CourierShipmentDto shipment) async {
    await _run(() async {
      final result = await context.read<CourierRepository>().refreshShipment(
        shipment.id,
      );
      if (!mounted) return;
      _message(result.anomalies.isEmpty ? '物流状态已更新。' : '物流状态已更新，请查看异常建议。');
      _reload();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) _message(error.msg);
    } catch (_) {
      if (mounted) _message('快递服务暂时不可用，请稍后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('快递管家'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : _create,
      icon: const Icon(Icons.add),
      label: const Text('登记运单'),
    ),
    body: FutureBuilder<_CourierData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('加载失败，重试'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.shipments.isEmpty && data.anomalies.isEmpty) {
          return const Center(child: Text('还没有登记中的运单。'));
        }
        return ListView(
          padding: NexusLayout.pagePadding.copyWith(bottom: 100),
          children: [
            if (data.anomalies.isNotEmpty) ...[
              Text('异常建议', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...data.anomalies.map((item) => _AnomalyCard(item: item)),
              const SizedBox(height: 20),
            ],
            Text('我的运单', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...data.shipments.map(
              (item) => _ShipmentCard(
                item: item,
                busy: _busy,
                onRefresh: () => _refresh(item),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _CourierData {
  const _CourierData({required this.shipments, required this.anomalies});
  final List<CourierShipmentDto> shipments;
  final List<CourierAnomalyDto> anomalies;
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({
    required this.item,
    required this.busy,
    required this.onRefresh,
  });
  final CourierShipmentDto item;
  final bool busy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label?.isNotEmpty == true
                      ? item.label!
                      : '运单 ${item.trackingNumberMasked}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.sync_rounded),
              ),
            ],
          ),
          Text('${item.carrier ?? '未知承运商'} · ${_status(item.latestStatus)}'),
          if (item.latestDescription?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(item.latestDescription!),
          ],
          if (item.latestLocation?.isNotEmpty == true)
            Text('位置：${item.latestLocation}'),
          if (item.isFreshFood)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '生鲜包裹',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    ),
  );
}

class _AnomalyCard extends StatelessWidget {
  const _AnomalyCard({required this.item});
  final CourierAnomalyDto item;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.warning_amber_rounded),
      title: Text(item.title),
      subtitle: Text('${item.description}\n建议：${item.suggestedAction}'),
    ),
  );
}

class _CourierDialog extends StatefulWidget {
  const _CourierDialog();
  @override
  State<_CourierDialog> createState() => _CourierDialogState();
}

class _CourierDialogState extends State<_CourierDialog> {
  final _tracking = TextEditingController();
  final _carrier = TextEditingController();
  final _label = TextEditingController();
  bool _fresh = false;
  @override
  void dispose() {
    _tracking.dispose();
    _carrier.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('登记运单'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _tracking,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: '运单号'),
          ),
          TextField(
            controller: _carrier,
            decoration: const InputDecoration(labelText: '承运商（可选）'),
          ),
          TextField(
            controller: _label,
            decoration: const InputDecoration(labelText: '备注（可选）'),
          ),
          CheckboxListTile(
            value: _fresh,
            onChanged: (value) => setState(() => _fresh = value ?? false),
            title: const Text('生鲜包裹'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _tracking.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                context,
                CourierShipmentCreateDto(
                  trackingNumber: _tracking.text.trim(),
                  carrier: _carrier.text.trim().isEmpty
                      ? null
                      : _carrier.text.trim(),
                  label: _label.text.trim().isEmpty ? null : _label.text.trim(),
                  isFreshFood: _fresh,
                ),
              ),
        child: const Text('登记'),
      ),
    ],
  );
}

String _status(String status) => switch (status) {
  'delivered' => '已签收',
  'out_for_delivery' => '派送中',
  'exception' => '异常',
  _ => '运输中',
};
