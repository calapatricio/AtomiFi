import 'package:atomifi/budgets/budget_form_screen.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('BudgetFormScreen', () {
    late InMemoryStore store;

    setUp(() async => store = await seededStore());

    Future<void> pump(WidgetTester tester, {Budget? existing}) => pumpScreen(
      tester,
      BudgetFormScreen(viewModel: budgetFormOn(store, existing: existing)),
    );

    bool canTapSave(WidgetTester tester) =>
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
            .onPressed !=
        null;

    testWidgets('cannot save a budget that is not filled in', (tester) async {
      await pump(tester);

      expect(find.text('New budget'), findsOneWidget);
      expect(canTapSave(tester), isFalse);
    });

    testWidgets('shows the budget being edited', (tester) async {
      await pump(tester, existing: monthlyBudget());

      expect(find.text('Edit budget'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Monthly'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '1000.00'), findsOneWidget);
      expect(canTapSave(tester), isTrue);
    });

    testWidgets('saves the budget typed into it', (tester) async {
      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Monthly',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Limit'),
        '1200',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final budget = (await store.budgets.all()).single;
      expect(budget.name, 'Monthly');
      expect(budget.limit, eur(120000));
    });

    testWidgets('offers the categories once the budget is for some of them', (
      tester,
    ) async {
      await pump(tester);
      expect(find.widgetWithText(FilterChip, 'Alcohol'), findsNothing);

      await tester.ensureVisible(find.text('Some categories'));
      await tester.tap(find.text('Some categories'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'Alcohol'), findsOneWidget);
    });

    testWidgets('asks for an end instead of a rhythm when it does not repeat', (
      tester,
    ) async {
      await pump(tester);
      expect(find.widgetWithText(TextFormField, 'Every'), findsOneWidget);

      await tester.ensureVisible(find.text('Repeats'));
      await tester.tap(find.text('Repeats'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Every'), findsNothing);
      expect(find.text('Until'), findsOneWidget);
    });
  });
}
