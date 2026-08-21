import '../../../core/api/api_client.dart';
import 'dto.dart';
import 'finance_repository.dart';

class HttpFinanceRepository implements FinanceRepository {
  HttpFinanceRepository(this._api, {required this.homeIdOf});
  final ApiClient _api;
  final int Function() homeIdOf;
  int get _homeId => homeIdOf();
  Map<String, dynamic> _map(dynamic raw) =>
      (raw as Map).cast<String, dynamic>();
  List<dynamic> _items(dynamic raw) => raw is List
      ? raw
      : raw is Map && raw['Items'] is List
      ? raw['Items'] as List
      : raw is Map && raw['items'] is List
      ? raw['items'] as List
      : const [];

  @override
  Future<List<FinanceTransactionDto>> listTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    final query = <String, dynamic>{
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
    if (category != null) query['category'] = category;
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/finance/transactions',
      query: query,
      parseData: (raw) => raw,
    );
    return _items(raw)
        .map((e) => FinanceTransactionDto.fromJson(_map(e)))
        .toList(growable: false);
  }

  @override
  Future<FinanceSummaryDto> summary({DateTime? from, DateTime? to}) async {
    final raw = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/homes/$_homeId/finance/summary',
      query: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
      parseData: (raw) => _map(raw),
    );
    return FinanceSummaryDto.fromJson(raw);
  }

  @override
  Future<({int imported, int skipped})> importCsv(String csv) async {
    final raw = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/finance/transactions/import',
      body: {'csv': csv, 'sourceType': 'csv'},
      parseData: (raw) => _map(raw),
    );
    return (
      imported: _number(raw['Imported'] ?? raw['imported']),
      skipped: _number(raw['Skipped'] ?? raw['skipped']),
    );
  }

  @override
  Future<List<BillingAccountDto>> listAccounts() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/billing/accounts',
      parseData: (raw) => raw,
    );
    return _items(
      raw,
    ).map((e) => BillingAccountDto.fromJson(_map(e))).toList(growable: false);
  }

  @override
  Future<BillingAccountDto> createAccount({
    required String billingType,
    required String provider,
    required String label,
    required DateTime nextDueDate,
    double? expectedAmount,
    int billingCycleMonths = 1,
    String sourceType = 'manual',
  }) async {
    final body = <String, dynamic>{
      'billingType': billingType,
      'provider': provider,
      'label': label,
      'nextDueDate': nextDueDate.toUtc().toIso8601String(),
      'billingCycleMonths': billingCycleMonths,
      'sourceType': sourceType,
    };
    if (expectedAmount != null) body['expectedAmount'] = expectedAmount;
    final raw = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/billing/accounts',
      body: body,
      parseData: (raw) => _map(raw),
    );
    return BillingAccountDto.fromJson(raw);
  }

  @override
  Future<void> recordPayment(
    int accountId, {
    required double amount,
    DateTime? dueDate,
    DateTime? paidAt,
    DateTime? nextDueDate,
    String sourceType = 'manual',
  }) async {
    await _api.request<dynamic>(
      method: 'POST',
      path: '/homes/$_homeId/billing/accounts/$accountId/payments',
      body: {
        'amount': amount,
        if (dueDate != null) 'dueDate': dueDate.toUtc().toIso8601String(),
        if (paidAt != null) 'paidAt': paidAt.toUtc().toIso8601String(),
        if (nextDueDate != null)
          'nextDueDate': nextDueDate.toUtc().toIso8601String(),
        'sourceType': sourceType,
      },
      parseData: (_) => null,
    );
  }

  @override
  Future<List<BillingReminderDto>> listReminders({DateTime? asOf}) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/billing/reminders',
      query: {if (asOf != null) 'asOf': asOf.toUtc().toIso8601String()},
      parseData: (raw) => raw,
    );
    return _items(
      raw,
    ).map((e) => BillingReminderDto.fromJson(_map(e))).toList(growable: false);
  }

  @override
  Future<BillingAnnualTrendDto> annualTrend({int? year}) async {
    final raw = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/homes/$_homeId/billing/trend',
      query: {'year': ?year},
      parseData: (raw) => _map(raw),
    );
    return BillingAnnualTrendDto.fromJson(raw);
  }
}

int _number(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
