import 'package:atomifi/transactions/transactions_screen.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('TransactionsScreen', () {
    late InMemoryStore store;

    setUp(() async => store = await seededStore());

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      TransactionsScreen(viewModel: transactionsViewModelOn(store)),
    );

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
