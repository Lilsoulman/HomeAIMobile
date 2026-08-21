import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/finance/dto.dart';
import '../features/finance/finance_repository.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late Future<_FinanceData> _future;
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

  Future<_FinanceData> _load() async {
    final repo = context.read<FinanceRepository>();
    final values = await Future.wait<Object>([
      repo.summary(),
      repo.listTransactions(),
      repo.listAccounts(),
      repo.listReminders(),
      repo.annualTrend(),
    ]);
    return _FinanceData(
      summary: values[0] as FinanceSummaryDto,
      transactions: values[1] as List<FinanceTransactionDto>,
      accounts: values[2] as List<BillingAccountDto>,
      reminders: values[3] as List<BillingReminderDto>,
      trend: values[4] as BillingAnnualTrendDto,
    );
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || !mounted) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      _message('Cannot read CSV');
      return;
    }
    final csv = utf8.decode(bytes);
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Preview CSV'),
        content: SingleChildScrollView(
          child: Text(csv.split('\n').take(10).join('\n')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    await _run(() async {
      final imported = await context.read<FinanceRepository>().importCsv(csv);
      _message('Imported ${imported.imported}, skipped ${imported.skipped}');
      _reload();
    });
  }

  Future<void> _addAccount() async {
    final data = await showDialog<_AccountInput>(
      context: context,
      builder: (_) => const _AccountDialog(),
    );
    if (data == null || !mounted) return;
    await _run(() async {
      await context.read<FinanceRepository>().createAccount(
        billingType: data.type,
        provider: data.provider,
        label: data.label,
        nextDueDate: data.dueDate,
        expectedAmount: data.amount,
      );
      _message('Account created');
      _reload();
    });
  }

  Future<void> _record(BillingAccountDto account) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _PaymentDialog(initial: account.expectedAmount),
    );
    if (amount == null || !mounted) return;
    await _run(() async {
      await context.read<FinanceRepository>().recordPayment(
        account.id,
        amount: amount,
      );
      _message('Payment recorded');
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
      if (mounted) _message('Network unavailable');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family finance'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_FinanceData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _Failure(onRetry: _reload);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: NexusLayout.pagePadding.copyWith(bottom: 36),
              children: [
                _SummaryCard(summary: data.summary),
                const SizedBox(height: 20),
                _BillingTrendCard(trend: data.trend),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _importCsv,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Import CSV'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _addAccount,
                        icon: const Icon(Icons.add_card_outlined),
                        label: const Text('New account'),
                      ),
                    ),
                  ],
                ),
                if (data.reminders.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _ReminderCard(
                    reminders: data.reminders,
                    onOpen: () => context.push('/plan/confirmations'),
                  ),
                ],
                const _Title('Billing accounts'),
                if (data.accounts.isEmpty)
                  const NexusSurface(child: Text('No billing accounts'))
                else
                  ...data.accounts.map(
                    (account) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AccountCard(
                        account: account,
                        busy: _busy,
                        onPay: () => _record(account),
                      ),
                    ),
                  ),
                const _Title('Recent transactions'),
                if (data.transactions.isEmpty)
                  const NexusSurface(child: Text('No transactions yet'))
                else
                  ...data.transactions
                      .take(20)
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.merchant),
                          subtitle: Text(
                            '${item.category} · ${_date(item.date)}',
                          ),
                          trailing: Text(
                            '${item.amount.toStringAsFixed(2)} ${item.currency}',
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FinanceData {
  const _FinanceData({
    required this.summary,
    required this.transactions,
    required this.accounts,
    required this.reminders,
    required this.trend,
  });
  final FinanceSummaryDto summary;
  final List<FinanceTransactionDto> transactions;
  final List<BillingAccountDto> accounts;
  final List<BillingReminderDto> reminders;
  final BillingAnnualTrendDto trend;
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final FinanceSummaryDto summary;
  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 30 days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'CNY ${summary.totalAmount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        Text(
          '${summary.transactionCount} transactions',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (summary.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(summary.suggestions.first),
        ],
      ],
    ),
  );
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminders, required this.onOpen});
  final List<BillingReminderDto> reminders;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: Text('${reminders.length} billing reminders'),
      subtitle: Text(
        reminders.map((e) => '${e.label}: ${e.daysUntilDue} days').join(', '),
      ),
      trailing: TextButton(onPressed: onOpen, child: const Text('Review')),
    ),
  );
}

class _BillingTrendCard extends StatelessWidget {
  const _BillingTrendCard({required this.trend});

  final BillingAnnualTrendDto trend;

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${trend.year} billing total',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'CNY ${trend.totalAmount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          trend.months.isEmpty
              ? 'No recorded payments this year'
              : trend.months
                    .map(
                      (month) =>
                          '${month.month}月 ${month.amount.toStringAsFixed(2)}',
                    )
                    .join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.busy,
    required this.onPay,
  });
  final BillingAccountDto account;
  final bool busy;
  final VoidCallback onPay;
  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Row(
      children: [
        const Icon(Icons.receipt_long_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${account.provider} · due ${_date(account.nextDueDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        TextButton(onPressed: busy ? null : onPay, child: const Text('Record')),
      ],
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Finance data unavailable'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class _AccountInput {
  const _AccountInput(
    this.type,
    this.provider,
    this.label,
    this.dueDate,
    this.amount,
  );
  final String type;
  final String provider;
  final String label;
  final DateTime dueDate;
  final double? amount;
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog();
  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final provider = TextEditingController();
  final label = TextEditingController();
  final amount = TextEditingController();
  String type = 'electricity';
  final due = DateTime.now().add(const Duration(days: 30));
  @override
  void dispose() {
    provider.dispose();
    label.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New billing account'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: type,
            items: const [
              DropdownMenuItem(value: 'water', child: Text('Water')),
              DropdownMenuItem(
                value: 'electricity',
                child: Text('Electricity'),
              ),
              DropdownMenuItem(value: 'gas', child: Text('Gas')),
              DropdownMenuItem(value: 'property', child: Text('Property')),
              DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => type = v ?? type),
          ),
          TextField(
            controller: provider,
            decoration: const InputDecoration(labelText: 'Provider'),
          ),
          TextField(
            controller: label,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Expected amount (optional)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (provider.text.trim().isEmpty || label.text.trim().isEmpty) return;
          Navigator.pop(
            context,
            _AccountInput(
              type,
              provider.text.trim(),
              label.text.trim(),
              due,
              double.tryParse(amount.text),
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({this.initial});
  final double? initial;
  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController amount = TextEditingController(
    text: widget.initial?.toString(),
  );
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record payment'),
    content: TextField(
      controller: amount,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Amount'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final value = double.tryParse(amount.text);
          if (value != null && value > 0) Navigator.pop(context, value);
        },
        child: const Text('Record'),
      ),
    ],
  );
}

String _date(DateTime value) => '${value.month}/${value.day}';
