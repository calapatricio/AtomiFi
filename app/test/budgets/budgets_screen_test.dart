import 'package:atomifi/budgets/budgets_screen.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('BudgetsScreen', () {
    late InMemoryStore store;
    var formsOpened = 0;
    Budget? edited;

    setUp(() async {
      store = await seededStore();
      formsOpened = 0;
      edited = null;
    });

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      BudgetsScreen(
        viewModel: budgetsViewModelOn(store),
        openForm: (context, {existing}) async {
          formsOpened++;
          edited = existing;
        },
      ),
    );

    testWidgets('says so when there is no budget yet', (tester) async {
      await pump(tester);

      expect(find.text('No budgets yet. Add the first one.'), findsOneWidget);
    });

    testWidgets('shows how much of a budget is spent and how much is left', (
      tester,
    ) async {
      await store.budgets.save(monthlyBudget());
      await store.transactions.save(
        spending('shopping', dateTime: DateTime(2026, 11, 6)),
      );

      await pump(tester);

      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('€15.00 of €1,000.00'), findsOneWidget);
      expect(find.text('€985.00 left'), findsOneWidget);
      expect(find.text('Nov 1 – Nov 30'), findsOneWidget);
    });

    testWidgets('says by how much a budget is overspent', (tester) async {
      await store.budgets.save(monthlyBudget(limitCents: 1000));
      await store.transactions.save(
        spending('shopping', dateTime: DateTime(2026, 11, 6)),
      );

      await pump(tester);

      expect(find.text('€5.00 over'), findsOneWidget);
    });

    testWidgets('opens the form to add a budget', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(formsOpened, 1);
    });

    testWidgets('opens the form to edit the budget that is tapped', (
      tester,
    ) async {
      await store.budgets.save(monthlyBudget());
      await pump(tester);

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      expect(formsOpened, 1);
      expect(edited?.name, 'Monthly');
    });

    testWidgets('deletes a budget once confirmed', (tester) async {
      await store.budgets.save(monthlyBudget());
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Monthly?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await store.budgets.all(), isEmpty);
      expect(find.text('Monthly'), findsNothing);
    });
  });
}
