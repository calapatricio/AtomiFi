import 'package:atomifi/goals/goals_screen.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('GoalsScreen', () {
    late InMemoryStore store;
    var formsOpened = 0;

    setUp(() async {
      store = await seededStore();
      formsOpened = 0;
    });

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      GoalsScreen(
        viewModel: goalsViewModelOn(store),
        openForm: (context) async => formsOpened++,
      ),
    );

    testWidgets('says so when there is no goal yet', (tester) async {
      await pump(tester);

      expect(find.text('No goals yet. Add the first one.'), findsOneWidget);
    });

    testWidgets('shows how far a goal has come and what is left', (
      tester,
    ) async {
      await store.goals.save(
        pizzaGoal(
          deadline: DateTime(2026, 12, 31),
          itemIds: {const ItemId('payroll-item')},
        ),
      );
      await store.transactions.save(income('payroll', bank, 20000));

      await pump(tester);

      expect(find.text('Pizza oven'), findsOneWidget);
      expect(find.text('🍕'), findsOneWidget);
      expect(find.text('€200.00 of €500.00'), findsOneWidget);
      expect(find.text('€300.00 to go'), findsOneWidget);
      expect(find.text('By Dec 31, 2026'), findsOneWidget);
    });

    testWidgets('says so when a goal is reached', (tester) async {
      await store.goals.save(
        pizzaGoal(itemIds: {const ItemId('payroll-item')}),
      );
      await store.transactions.save(income('payroll', bank, 60000));

      await pump(tester);

      expect(find.text('Reached'), findsOneWidget);
    });

    testWidgets('opens the form to add a goal', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(formsOpened, 1);
    });

    testWidgets('deletes a goal once confirmed', (tester) async {
      await store.goals.save(pizzaGoal());
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Pizza oven?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await store.goals.all(), isEmpty);
      expect(find.text('Pizza oven'), findsNothing);
    });
  });
}
