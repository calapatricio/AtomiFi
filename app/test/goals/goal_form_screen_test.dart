import 'package:atomifi/goals/goal_form_screen.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('GoalFormScreen', () {
    late InMemoryStore store;

    setUp(() async => store = await seededStore());

    Future<void> pump(WidgetTester tester, {Goal? existing}) => pumpScreen(
      tester,
      GoalFormScreen(viewModel: goalFormOn(store, existing: existing)),
    );

    bool canTapSave(WidgetTester tester) =>
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
            .onPressed !=
        null;

    Future<void> fillIn(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Pizza oven',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Target'),
        '500',
      );
      await tester.pumpAndSettle();
    }

    testWidgets('cannot save a goal that is not filled in', (tester) async {
      await pump(tester);

      expect(find.text('New goal'), findsOneWidget);
      expect(canTapSave(tester), isFalse);
    });

    testWidgets('shows the goal being edited', (tester) async {
      await pump(tester, existing: pizzaGoal(deadline: DateTime(2026, 12, 31)));

      expect(find.text('Edit goal'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Pizza oven'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '500.00'), findsOneWidget);
      expect(find.text('Dec 31, 2026'), findsOneWidget);
      expect(canTapSave(tester), isTrue);
    });

    testWidgets('saves the goal typed into it', (tester) async {
      await pump(tester);

      await fillIn(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final goal = (await store.goals.all()).single;
      expect(goal.name, 'Pizza oven');
      expect(goal.target, eur(50000));
      expect(goal.kind, GoalKind.saving);
    });

    testWidgets('saves a goal to spend once that is chosen', (tester) async {
      await pump(tester);

      await fillIn(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Spend'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect((await store.goals.all()).single.kind, GoalKind.spending);
    });

    testWidgets('sets a deadline that can be taken away again', (tester) async {
      await pump(tester);
      expect(find.text('No deadline'), findsOneWidget);

      await tester.tap(find.text('No deadline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('No deadline'), findsNothing);
      expect(find.text('Nov 13, 2027'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('No deadline'), findsOneWidget);
    });
  });
}
