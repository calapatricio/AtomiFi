import 'package:atomifi/transactions/transaction_form_screen.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('TransactionFormScreen', () {
    late InMemoryStore store;

    setUp(() async => store = await seededStore());

    Future<void> pump(WidgetTester tester, {Transaction? existing}) =>
        pumpScreen(
          tester,
          TransactionFormScreen(
            viewModel: transactionFormOn(store, existing: existing),
          ),
        );

    bool canTapSave(WidgetTester tester) =>
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
            .onPressed !=
        null;

    testWidgets('starts a new transaction that cannot be saved yet', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('New transaction'), findsOneWidget);
      expect(canTapSave(tester), isFalse);
    });

    testWidgets('shows what the transaction being edited holds', (
      tester,
    ) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);

      await pump(tester, existing: shopping);

      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Supermarket'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '15.00'), findsOneWidget);
      expect(find.text('Total: -€15.00'), findsOneWidget);
      expect(canTapSave(tester), isTrue);
    });

    testWidgets('saves the changes typed into it', (tester) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await pump(tester, existing: shopping);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Supermarket'),
        'Market',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '15.00'), '20');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final saved = (await store.transactions.all()).single;
      expect(saved.name, 'Market');
      expect(saved.total, eur(-2000));
    });

    testWidgets('adds a person to share an item with', (tester) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await pump(tester, existing: shopping);

      await tester.ensureVisible(find.text('Add person'));
      await tester.tap(find.text('Add person'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Person'), findsOneWidget);
      expect(
        find.text('Give each person a name and an amount'),
        findsOneWidget,
      );
      expect(canTapSave(tester), isFalse);
    });

    testWidgets('deletes the transaction once confirmed', (tester) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await pump(tester, existing: shopping);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete this transaction?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await store.transactions.all(), isEmpty);
    });
  });
}
