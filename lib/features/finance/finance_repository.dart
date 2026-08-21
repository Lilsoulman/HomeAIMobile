import 'dto.dart';

abstract class FinanceRepository {
  Future<List<FinanceTransactionDto>> listTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
  });
  Future<FinanceSummaryDto> summary({DateTime? from, DateTime? to});
  Future<({int imported, int skipped})> importCsv(String csv);
  Future<List<BillingAccountDto>> listAccounts();
  Future<BillingAccountDto> createAccount({
    required String billingType,
    required String provider,
    required String label,
    required DateTime nextDueDate,
    double? expectedAmount,
    int billingCycleMonths = 1,
    String sourceType = 'manual',
  });
  Future<void> recordPayment(
    int accountId, {
    required double amount,
    DateTime? dueDate,
    DateTime? paidAt,
    DateTime? nextDueDate,
    String sourceType = 'manual',
  });
  Future<List<BillingReminderDto>> listReminders({DateTime? asOf});
  Future<BillingAnnualTrendDto> annualTrend({int? year});
}
