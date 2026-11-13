import 'package:atomifi/accounts/accounts_screen.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('AccountsScreen', () {
    late InMemoryStore store;

    setUp(() => store = InMemoryStore());

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      AccountsScreen(viewModel: accountsViewModelOn(store)),
    );

    testWidgets('invites to add an account when there is none', (tester) async {
      await pump(tester);

      expect(find.text('No accounts yet. Add the first one.'), findsOneWidget);
    });

    testWidgets('shows each account with its balance', (tester) async {
      await store.accounts.save(bank);
      await store.accounts.save(savings);
      await store.transactions.save(income('payroll', bank, 150000));

      await pump(tester);

      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('€1,500.00'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('€0.00'), findsOneWidget);
    });

    testWidgets('adds the account typed into the form', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Broker');
      await tester.enterText(find.byType(TextFormField).last, 'usd');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Broker'), findsOneWidget);
      expect(find.text(r'$0.00'), findsOneWidget);
    });

    testWidgets('does not add an account without a name', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name'), findsOneWidget);
      expect(await store.accounts.all(), isEmpty);
    });

    testWidgets('moves an archived account out of the list', (tester) async {
      await store.accounts.save(bank);
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Bank'), findsNothing);
      expect(find.text('Archived (1)'), findsOneWidget);
    });

    testWidgets('asks before deleting and says what will go', (tester) async {
      await store.accounts.save(bank);
      await store.accounts.save(savings);
      await store.transfers.save(transfer('deposit', bank, savings, 30000));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Savings?'), findsOneWidget);
      expect(find.text('Its only record will be deleted too.'), findsOneWidget);
      expect(
        find.text('The balance of Bank will change by €300.00.'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the account when the deletion is cancelled', (
      tester,
    ) async {
      await store.accounts.save(bank);
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Bank'), findsOneWidget);
    });

    testWidgets('deletes the account once confirmed', (tester) async {
      await store.accounts.save(bank);
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Bank'), findsNothing);
      expect(await store.accounts.all(), isEmpty);
    });
  });
}
