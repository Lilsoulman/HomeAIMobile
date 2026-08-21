import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/finance/http_finance_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('maps finance and billing endpoints', () async {
    SharedPreferences.setMockInitialValues({});
    final paths = <String>[];
    final api = ApiClient(tokenStorage: _Tokens(), env: await EnvConfig.init());
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add(options.path);
          final data = switch (options.path) {
            '/homes/42/finance/summary' => _summary(),
            '/homes/42/finance/transactions' => [_transaction()],
            '/homes/42/finance/transactions/import' => {
              'imported': 2,
              'skipped': 1,
            },
            '/homes/42/billing/accounts' => [_account()],
            '/homes/42/billing/reminders' => [_reminder()],
            '/homes/42/billing/trend' => _trend(),
            _ => _account(),
          };
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'Code': 0, 'Msg': 'ok', 'Data': data},
            ),
          );
        },
      ),
    );
    final repo = HttpFinanceRepository(api, homeIdOf: () => 42);
    expect((await repo.summary()).totalAmount, 123.4);
    expect((await repo.listTransactions()).single.merchant, 'Market');
    expect(await repo.importCsv('csv'), (imported: 2, skipped: 1));
    expect((await repo.listAccounts()).single.label, 'Electricity');
    expect((await repo.listReminders()).single.daysUntilDue, 3);
    final trend = await repo.annualTrend(year: 2026);
    expect(trend.totalAmount, 88.5);
    expect(trend.months.single.paymentCount, 2);
    expect(paths, contains('/homes/42/finance/summary'));
    expect(paths, contains('/homes/42/billing/reminders'));
    expect(paths, contains('/homes/42/billing/trend'));
  });

  test('preserves annual trend API errors', () async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient(tokenStorage: _Tokens(), env: await EnvConfig.init());
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'Code': 422, 'Msg': 'invalid year', 'Data': null},
          ),
        ),
      ),
    );

    final repo = HttpFinanceRepository(api, homeIdOf: () => 42);
    expect(
      repo.annualTrend(year: 0),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 422)),
    );
  });
}

Map<String, dynamic> _summary() => {
  'From': '2026-08-01T00:00:00Z',
  'To': '2026-08-30T00:00:00Z',
  'TotalAmount': 123.4,
  'TransactionCount': 1,
  'Categories': [],
  'Suggestions': ['Review'],
  'ConfirmationIds': [9],
};
Map<String, dynamic> _transaction() => {
  'Id': 1,
  'TransactionDate': '2026-08-20T00:00:00Z',
  'Merchant': 'Market',
  'Amount': 12.3,
  'Currency': 'CNY',
  'Category': 'Food',
};
Map<String, dynamic> _account() => {
  'Id': 4,
  'BillingType': 'electricity',
  'Provider': 'Power',
  'Label': 'Electricity',
  'NextDueDate': '2026-09-01T00:00:00Z',
  'BillingCycleMonths': 1,
  'Currency': 'CNY',
};
Map<String, dynamic> _reminder() => {
  'BillingAccountId': 4,
  'Label': 'Electricity',
  'DueDate': '2026-09-01T00:00:00Z',
  'DaysUntilDue': 3,
  'ConfirmationId': 8,
};
Map<String, dynamic> _trend() => {
  'Year': 2026,
  'TotalAmount': 88.5,
  'Months': [
    {'Month': 8, 'Amount': 88.5, 'PaymentCount': 2},
  ],
};

class _Tokens implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {}
}
