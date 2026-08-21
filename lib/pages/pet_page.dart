import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/pet/dto.dart';
import '../features/pet/pet_repository.dart';

class PetPage extends StatefulWidget {
  const PetPage({super.key});
  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  late Future<_PetData> _future;
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

  Future<_PetData> _load() async {
    final repo = context.read<PetRepository>();
    final pets = await repo.listPets();
    final alerts = await repo.listAlerts();
    final details = await Future.wait(
      pets.map(
        (pet) async => _PetDetails(
          pet: pet,
          care: await repo.listCareEvents(pet.id),
          supplies: await repo.listSupplies(pet.id),
        ),
      ),
    );
    return _PetData(details: details, alerts: alerts);
  }

  Future<void> _createPet() async {
    final request = await showDialog<PetCreateDto>(
      context: context,
      builder: (_) => const _PetDialog(),
    );
    if (request == null || !mounted) return;
    await _run(() async {
      await context.read<PetRepository>().createPet(request);
      _reload();
    });
  }

  Future<void> _addCare(PetDto pet) async {
    final request = await showDialog<PetCareEventCreateDto>(
      context: context,
      builder: (_) => const _CareDialog(),
    );
    if (request == null || !mounted) return;
    await _run(() async {
      await context.read<PetRepository>().addCareEvent(pet.id, request);
      _reload();
    });
  }

  Future<void> _updateSupply(PetDto pet) async {
    final request = await showDialog<PetSupplyUpsertDto>(
      context: context,
      builder: (_) => const _SupplyDialog(),
    );
    if (request == null || !mounted) return;
    await _run(() async {
      await context.read<PetRepository>().upsertSupply(pet.id, request);
      _reload();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) _message(e.msg);
    } catch (_) {
      if (mounted) _message('Pet service unavailable. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pet steward'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : _createPet,
      icon: const Icon(Icons.add),
      label: const Text('Add pet'),
    ),
    body: FutureBuilder<_PetData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Load failed, retry'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.details.isEmpty && data.alerts.isEmpty) {
          return const Center(child: Text('No pets yet.'));
        }
        return ListView(
          padding: NexusLayout.pagePadding.copyWith(bottom: 100),
          children: [
            if (data.alerts.isNotEmpty) ...[
              Text(
                'Upcoming reminders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...data.alerts.map(
                (a) => NexusSurface(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(a.title),
                    subtitle: Text(
                      a.daysRemaining == null
                          ? 'Within 7 days'
                          : '${a.daysRemaining!.toStringAsFixed(0)} days remaining',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text('Pets', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...data.details.map(
              (item) => _PetCard(
                item: item,
                onAddCare: () => _addCare(item.pet),
                onUpdateSupply: () => _updateSupply(item.pet),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PetData {
  const _PetData({required this.details, required this.alerts});
  final List<_PetDetails> details;
  final List<PetAlertDto> alerts;
}

class _PetDetails {
  const _PetDetails({
    required this.pet,
    required this.care,
    required this.supplies,
  });
  final PetDto pet;
  final List<PetCareEventDto> care;
  final List<PetSupplyDto> supplies;
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.item,
    required this.onAddCare,
    required this.onUpdateSupply,
  });
  final _PetDetails item;
  final VoidCallback onAddCare;
  final VoidCallback onUpdateSupply;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.pet.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(item.pet.species),
            ],
          ),
          if (item.pet.breed?.isNotEmpty == true) Text(item.pet.breed!),
          const SizedBox(height: 12),
          if (item.care.isNotEmpty)
            Text('Care: ${item.care.map((e) => e.title).join(', ')}'),
          if (item.supplies.isNotEmpty)
            ...item.supplies.map(
              (s) => Text(
                '${s.itemName}: ${s.quantity.toStringAsFixed(1)} ${s.unit}${s.daysRemaining == null ? '' : ' (${s.daysRemaining!.toStringAsFixed(0)} days)'}',
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onAddCare,
                icon: const Icon(Icons.event_note_outlined),
                label: const Text('Add care'),
              ),
              TextButton.icon(
                onPressed: onUpdateSupply,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Update supply'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PetDialog extends StatefulWidget {
  const _PetDialog();
  @override
  State<_PetDialog> createState() => _PetDialogState();
}

class _CareDialog extends StatefulWidget {
  const _CareDialog();
  @override
  State<_CareDialog> createState() => _CareDialogState();
}

class _CareDialogState extends State<_CareDialog> {
  final _title = TextEditingController();
  String _type = 'vaccine';
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add care reminder'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _type,
          items: const [
            DropdownMenuItem(value: 'vaccine', child: Text('Vaccine')),
            DropdownMenuItem(value: 'deworming', child: Text('Deworming')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _type = value);
          },
        ),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_title.text.trim().isNotEmpty) {
            Navigator.pop(
              context,
              PetCareEventCreateDto(
                careType: _type,
                title: _title.text.trim(),
                dueDate: DateTime.now().add(const Duration(days: 1)),
              ),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _SupplyDialog extends StatefulWidget {
  const _SupplyDialog();
  @override
  State<_SupplyDialog> createState() => _SupplyDialogState();
}

class _SupplyDialogState extends State<_SupplyDialog> {
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _daily = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _daily.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Update supply'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Item'),
        ),
        TextField(
          controller: _quantity,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        TextField(
          controller: _daily,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Daily usage'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final quantity = double.tryParse(_quantity.text);
          final daily = double.tryParse(_daily.text);
          if (_name.text.trim().isNotEmpty &&
              quantity != null &&
              daily != null &&
              daily > 0) {
            Navigator.pop(
              context,
              PetSupplyUpsertDto(
                itemName: _name.text.trim(),
                quantity: quantity,
                dailyUsage: daily,
              ),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _PetDialogState extends State<_PetDialog> {
  final _name = TextEditingController();
  final _species = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add pet'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: _species,
          decoration: const InputDecoration(labelText: 'Species'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_name.text.trim().isNotEmpty && _species.text.trim().isNotEmpty) {
            Navigator.pop(
              context,
              PetCreateDto(
                name: _name.text.trim(),
                species: _species.text.trim(),
              ),
            );
          }
        },
        child: const Text('Create'),
      ),
    ],
  );
}
