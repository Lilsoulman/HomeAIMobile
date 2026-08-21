class FinanceTransactionDto {
  const FinanceTransactionDto({
    required this.id,
    required this.date,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.category,
    this.notes,
  });
  factory FinanceTransactionDto.fromJson(Map<String, dynamic> json) =>
      FinanceTransactionDto(
        id: _int(json['Id'] ?? json['id']),
        date: DateTime.parse(
          (json['TransactionDate'] ?? json['transactionDate']).toString(),
        ),
        merchant: (json['Merchant'] ?? json['merchant'] ?? '').toString(),
        amount: _decimal(json['Amount'] ?? json['amount']),
        currency: (json['Currency'] ?? json['currency'] ?? 'CNY').toString(),
        category: (json['Category'] ?? json['category'] ?? '其他').toString(),
        notes: (json['Notes'] ?? json['notes'])?.toString(),
      );
  final int id;
  final DateTime date;
  final String merchant;
  final double amount;
  final String currency;
  final String category;
  final String? notes;
}

class FinanceCategorySummaryDto {
  const FinanceCategorySummaryDto(this.category, this.amount, this.count);
  factory FinanceCategorySummaryDto.fromJson(Map<String, dynamic> json) =>
      FinanceCategorySummaryDto(
        (json['Category'] ?? json['category'] ?? '').toString(),
        _decimal(json['Amount'] ?? json['amount']),
        _int(json['Count'] ?? json['count']),
      );
  final String category;
  final double amount;
  final int count;
}

class FinanceSummaryDto {
  const FinanceSummaryDto({
    required this.from,
    required this.to,
    required this.totalAmount,
    required this.transactionCount,
    required this.categories,
    required this.suggestions,
    required this.confirmationIds,
  });
  factory FinanceSummaryDto.fromJson(Map<String, dynamic> json) =>
      FinanceSummaryDto(
        from: DateTime.parse((json['From'] ?? json['from']).toString()),
        to: DateTime.parse((json['To'] ?? json['to']).toString()),
        totalAmount: _decimal(json['TotalAmount'] ?? json['totalAmount']),
        transactionCount: _int(
          json['TransactionCount'] ?? json['transactionCount'],
        ),
        categories: _list(json['Categories'] ?? json['categories'])
            .map((e) => FinanceCategorySummaryDto.fromJson(e))
            .toList(growable: false),
        suggestions: _values(
          json['Suggestions'] ?? json['suggestions'],
        ).map((e) => e.toString()).toList(growable: false),
        confirmationIds: _values(
          json['ConfirmationIds'] ?? json['confirmationIds'],
        ).map(_int).toList(growable: false),
      );
  final DateTime from;
  final DateTime to;
  final double totalAmount;
  final int transactionCount;
  final List<FinanceCategorySummaryDto> categories;
  final List<String> suggestions;
  final List<int> confirmationIds;
}

class BillingAccountDto {
  const BillingAccountDto({
    required this.id,
    required this.type,
    required this.provider,
    required this.label,
    required this.nextDueDate,
    this.expectedAmount,
    required this.currency,
    required this.cycleMonths,
  });
  factory BillingAccountDto.fromJson(Map<String, dynamic> json) =>
      BillingAccountDto(
        id: _int(json['Id'] ?? json['id']),
        type: (json['BillingType'] ?? json['billingType'] ?? 'other')
            .toString(),
        provider: (json['Provider'] ?? json['provider'] ?? '').toString(),
        label: (json['Label'] ?? json['label'] ?? '').toString(),
        nextDueDate: DateTime.parse(
          (json['NextDueDate'] ?? json['nextDueDate']).toString(),
        ),
        expectedAmount:
            json['ExpectedAmount'] == null && json['expectedAmount'] == null
            ? null
            : _decimal(json['ExpectedAmount'] ?? json['expectedAmount']),
        currency: (json['Currency'] ?? json['currency'] ?? 'CNY').toString(),
        cycleMonths: _int(
          json['BillingCycleMonths'] ?? json['billingCycleMonths'],
          fallback: 1,
        ),
      );
  final int id;
  final String type;
  final String provider;
  final String label;
  final DateTime nextDueDate;
  final double? expectedAmount;
  final String currency;
  final int cycleMonths;
}

class BillingReminderDto {
  const BillingReminderDto({
    required this.accountId,
    required this.label,
    required this.dueDate,
    required this.daysUntilDue,
    this.confirmationId,
  });
  factory BillingReminderDto.fromJson(
    Map<String, dynamic> json,
  ) => BillingReminderDto(
    accountId: _int(json['BillingAccountId'] ?? json['billingAccountId']),
    label: (json['Label'] ?? json['label'] ?? '').toString(),
    dueDate: DateTime.parse((json['DueDate'] ?? json['dueDate']).toString()),
    daysUntilDue: _int(json['DaysUntilDue'] ?? json['daysUntilDue']),
    confirmationId: (json['ConfirmationId'] ?? json['confirmationId']) == null
        ? null
        : _int(json['ConfirmationId'] ?? json['confirmationId']),
  );
  final int accountId;
  final String label;
  final DateTime dueDate;
  final int daysUntilDue;
  final int? confirmationId;
}

class BillingMonthlyTrendDto {
  const BillingMonthlyTrendDto({
    required this.month,
    required this.amount,
    required this.paymentCount,
  });

  factory BillingMonthlyTrendDto.fromJson(Map<String, dynamic> json) =>
      BillingMonthlyTrendDto(
        month: _int(json['Month'] ?? json['month']),
        amount: _decimal(json['Amount'] ?? json['amount']),
        paymentCount: _int(json['PaymentCount'] ?? json['paymentCount']),
      );

  final int month;
  final double amount;
  final int paymentCount;
}

class BillingAnnualTrendDto {
  const BillingAnnualTrendDto({
    required this.year,
    required this.totalAmount,
    required this.months,
  });

  factory BillingAnnualTrendDto.fromJson(Map<String, dynamic> json) =>
      BillingAnnualTrendDto(
        year: _int(json['Year'] ?? json['year']),
        totalAmount: _decimal(json['TotalAmount'] ?? json['totalAmount']),
        months: _list(
          json['Months'] ?? json['months'],
        ).map(BillingMonthlyTrendDto.fromJson).toList(growable: false),
      );

  final int year;
  final double totalAmount;
  final List<BillingMonthlyTrendDto> months;
}

int _int(dynamic value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
double _decimal(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false)
    : const [];

List<dynamic> _values(dynamic value) => value is List ? value : const [];
