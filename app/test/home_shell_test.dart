import 'package:atomifi/accounts/accounts_screen.dart';
import 'package:atomifi/home_shell.dart';
import 'package:atomifi/transactions/transactions_screen.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  group('HomeShell', () {
    late InMemoryStore store;

    setUp(() async => store = await seededStore());

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      HomeShell(
        transactions: (_) =>
            TransactionsScreen(viewModel: transactionsViewModelOn(store)),
        accounts: (_) => AccountsScreen(viewModel: accountsViewModelOn(store)),
        more: (_) => const Text('More screen'),
      ),
    );

    testWidgets('opens on the transactions', (tester) async {
      await pump(tester);

      expect(find.widgetWithText(AppBar, 'Transactions'), findsOneWidget);
    });

    testWidgets('goes to the accounts and to the rest', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('More screen'), findsOneWidget);
    });

    testWidgets('shows what changed while another screen was open', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      await store.transactions.save(spending('shopping'));
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      expect(find.text('Supermarket'), findsOneWidget);
    });
  });
}
