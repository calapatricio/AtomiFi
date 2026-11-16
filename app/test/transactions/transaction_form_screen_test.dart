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
      expect(find.text('-€15.00'), findsOneWidget);
      expect(find.text('Food'), findsWidgets);
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

    testWidgets('shows the currency of the account next to each amount', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('€'), findsOneWidget);
    });

    testWidgets('lets the account be chosen from those in use', (tester) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await pump(tester, existing: shopping);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Savings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect((await store.transactions.all()).single.accountId, savings.id);
    });

    testWidgets('makes it plain that I am one of those sharing an item', (
      tester,
    ) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await pump(tester, existing: shopping);

      await tester.ensureVisible(find.text('Add person'));
      await tester.tap(find.text('Add person'));
      await tester.pumpAndSettle();

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Include me'), findsOneWidget);
    });

    testWidgets('leaves me out of an item I take no part in', (tester) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await pump(tester, existing: shopping);
      await tester.ensureVisible(find.text('Add person'));
      await tester.tap(find.text('Add person'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Person'),
        'Moy',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '').last, '10');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Include me'));
      await tester.tap(find.text('Include me'));
      await tester.pumpAndSettle();

      expect(find.text('Me'), findsNothing);
      expect(
        find.text('The parts add up to €10.00, but the amount is €15.00'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the place of the button that removes an item', (
      tester,
    ) async {
      await pump(tester);

      IconButton removeButton() =>
          tester.widget(find.widgetWithIcon(IconButton, Icons.close).first);

      expect(removeButton().onPressed, isNull);

      await tester.ensureVisible(find.text('Add item'));
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Remove item'), findsNWidgets(2));
      expect(removeButton().onPressed, isNotNull);
    });

    testWidgets('shows the emoji of the category of each item', (tester) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);

      await pump(tester, existing: shopping);

      expect(find.text('🍔'), findsOneWidget);
      expect(find.text('Food'), findsWidgets);
    });

    testWidgets('invites to choose a category for an item without one', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Choose a category'), findsOneWidget);
    });

    testWidgets('offers no budget when none takes items one by one', (
      tester,
    ) async {
      await store.budgets.save(monthlyBudget());

      await pump(tester);

      expect(find.text('Budget'), findsNothing);
    });

    testWidgets('puts an item in the budget that is tapped', (tester) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await store.budgets.save(tripBudget());
      await pump(tester, existing: shopping);

      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Trip'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(await itemsInBudget(store, 'trip'), {
        const ItemId('shopping-food'),
      });
    });

    testWidgets('takes the item out when its budget is tapped again', (
      tester,
    ) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await store.budgets.save(
        tripBudget(itemIds: {const ItemId('shopping-food')}),
      );
      await pump(tester, existing: shopping);

      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Trip'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(await itemsInBudget(store, 'trip'), isEmpty);
    });

    testWidgets('lets the amount of an item be typed with a minus', (
      tester,
    ) async {
      await pump(tester);

      final amount = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Amount'),
      );

      expect(amount.keyboardType.signed, isTrue);
    });

    testWidgets('offers no goal when there is none', (tester) async {
      await pump(tester);

      expect(find.text('Goal'), findsNothing);
    });

    testWidgets('makes an item count towards the goal that is tapped', (
      tester,
    ) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await store.goals.save(pizzaGoal(kind: GoalKind.spending));
      await pump(tester, existing: shopping);

      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Pizza oven'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pizza oven'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(await itemsInGoal(store, 'pizza'), {
        const ItemId('shopping-food'),
      });
    });

    testWidgets('stops the item from counting when its goal is tapped again', (
      tester,
    ) async {
      final shopping = spending('shopping');
      await store.transactions.save(shopping);
      await store.goals.save(
        pizzaGoal(itemIds: {const ItemId('shopping-food')}),
      );
      await pump(tester, existing: shopping);

      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Pizza oven'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pizza oven'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(await itemsInGoal(store, 'pizza'), isEmpty);
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
