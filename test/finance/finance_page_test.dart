import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nexus_mind_mobile/features/finance/dto.dart';
import 'package:nexus_mind_mobile/features/finance/finance_repository.dart';
import 'package:nexus_mind_mobile/pages/finance_page.dart';

void main() {
  testWidgets('shows summary and empty account state', (tester) async {
    await tester.pumpWidget(
      Provider<FinanceRepository>.value(
        value: _Repo(),
        child: const MaterialApp(home: FinancePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Family finance'), findsOneWidget);
    expect(find.text('CNY 0.00'), findsNWidgets(2));
    expect(find.text('2026 billing total'), findsOneWidget);
    expect(find.text('No billing accounts'), findsOneWidget);
  });
}

class _Repo implements FinanceRepository {
  @override
  Future<({int imported, int skipped})> importCsv(String csv) async =>
      (imported: 0, skipped: 0);
  @override
  Future<List<FinanceTransactionDto>> listTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async => [];
  @override
  Future<FinanceSummaryDto> summary({DateTime? from, DateTime? to}) async =>
      FinanceSummaryDto(
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 30),
        totalAmount: 0,
        transactionCount: 0,
        categories: const [],
        suggestions: const [],
        confirmationIds: const [],
      );
  @override
  Future<List<BillingAccountDto>> listAccounts() async => [];
  @override
  Future<BillingAccountDto> createAccount({
    required String billingType,
    required String provider,
    required String label,
    required DateTime nextDueDate,
    double? expectedAmount,
    int billingCycleMonths = 1,
    String sourceType = 'manual',
  }) async => throw UnimplementedError();
  @override
  Future<void> recordPayment(
    int accountId, {
    required double amount,
    DateTime? dueDate,
    DateTime? paidAt,
    DateTime? nextDueDate,
    String sourceType = 'manual',
  }) async {}
  @override
  Future<List<BillingReminderDto>> listReminders({DateTime? asOf}) async => [];
  @override
  Future<BillingAnnualTrendDto> annualTrend({int? year}) async =>
      BillingAnnualTrendDto(year: 2026, totalAmount: 0, months: const []);
}
