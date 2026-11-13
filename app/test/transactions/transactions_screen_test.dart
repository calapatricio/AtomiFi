import 'package:atomifi/transactions/transactions_screen.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('TransactionsScreen', () {
    late InMemoryStore store;

    setUp(() async => store = await seededStore());

    /// What the screen asked to open the form with: `null` for a new one.
    final opened = <Transaction?>[];

    setUp(opened.clear);

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      TransactionsScreen(
        viewModel: transactionsViewModelOn(store),
        openForm: (context, {existing}) async => opened.add(existing),
      ),
    );

    testWidgets('opens an empty form to add a transaction', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(opened, [null]);
    });

    testWidgets('opens the form with the transaction that is tapped', (
      tester,
    ) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await pump(tester);

      await tester.tap(find.text('Supermarket'));
      await tester.pumpAndSettle();

      expect(opened, [shopping]);
    });

    testWidgets('shows what was stored while the form was open', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        TransactionsScreen(
          viewModel: transactionsViewModelOn(store),
          openForm: (context, {existing}) =>
              store.transactions.save(spending('shopping')),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Supermarket'), findsOneWidget);
    });

    testWidgets('says so when there is nothing yet', (tester) async {
      await pump(tester);

      expect(find.text('No transactions yet.'), findsOneWidget);
    });

    testWidgets('shows a transaction under the day it happened', (
      tester,
    ) async {
      await store.transactions.save(spending('shopping'));

      await pump(tester);

      expect(find.text('Friday, November 6, 2026'), findsOneWidget);
      expect(find.text('Supermarket'), findsOneWidget);
      expect(find.text('Bank · Food'), findsOneWidget);
      expect(find.text('-€15.00'), findsOneWidget);
    });

    testWidgets('names every category of a transaction with several', (
      tester,
    ) async {
      await store.transactions.save(
        spending('party', centsByCategory: {alcohol: -1200, food: -180}),
      );

      await pump(tester);

      expect(find.text('Bank · Alcohol, Food'), findsOneWidget);
      expect(find.text('-€13.80'), findsOneWidget);
    });

    testWidgets('shows a transfer with both accounts', (tester) async {
      await store.transfers.save(transfer('deposit', bank, savings, 30000));

      await pump(tester);

      expect(find.text('Bank → Savings'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('€300.00'), findsOneWidget);
    });
  });
}
