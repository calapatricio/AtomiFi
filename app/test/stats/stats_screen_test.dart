import 'package:atomifi/stats/stats_screen.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('StatsScreen', () {
    late InMemoryStore store;

    setUp(() async {
      store = await seededStore();
      await store.categories.save(beer);
    });

    Future<void> record() async {
      for (final transaction in [
        spending('shop', centsByCategory: const {food: -1000}),
        spending('bar', centsByCategory: const {alcohol: -1000, beer: -2000}),
        spending(
          'old',
          dateTime: DateTime(2026, 10, 20),
          centsByCategory: const {food: -900},
        ),
        income('payroll', bank, 200000),
      ]) {
        await store.transactions.save(transaction);
      }
    }

    Future<void> pump(WidgetTester tester) =>
        pumpScreen(tester, StatsScreen(viewModel: statsViewModelOn(store)));

    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('says so when the period has nothing', (tester) async {
      await pump(tester);

      expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
      expect(find.text('Nothing in this period'), findsOneWidget);
    });

    testWidgets('sums up the month', (tester) async {
      await record();
      await pump(tester);

      expect(find.text('€2,000.00'), findsOneWidget);
      expect(find.text('€40.00'), findsWidgets);
      expect(find.text('€1,960.00'), findsOneWidget);
    });

    testWidgets('lists the categories with the part each one is', (
      tester,
    ) async {
      await record();
      await pump(tester);

      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('€30.00'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('looks into the category that is tapped, and back', (
      tester,
    ) async {
      await record();
      await pump(tester);

      await tap(tester, find.text('Alcohol'));

      expect(find.text('Beer'), findsOneWidget);
      expect(find.text('€20.00'), findsOneWidget);
      expect(find.text('Food'), findsNothing);

      await tap(tester, find.widgetWithIcon(IconButton, Icons.arrow_back));

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Beer'), findsNothing);
    });

    testWidgets('shows the income when it is chosen', (tester) async {
      await record();
      await pump(tester);

      await tap(tester, find.widgetWithText(ChoiceChip, 'Income'));

      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('goes to the period before', (tester) async {
      await record();
      await pump(tester);

      await tap(tester, find.widgetWithIcon(IconButton, Icons.chevron_left));

      expect(find.text('Oct 1, 2026 – Oct 31, 2026'), findsOneWidget);
      expect(find.text('€9.00'), findsWidgets);
    });

    testWidgets('lets another period be chosen', (tester) async {
      await record();
      await pump(tester);

      await tap(tester, find.text('Nov 1, 2026 – Nov 30, 2026'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Last days'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Days'), '7');
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(FilledButton, 'Apply'));

      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.chevron_left), findsNothing);
    });

    testWidgets('can show everything', (tester) async {
      await record();
      await pump(tester);

      await tap(tester, find.text('Nov 1, 2026 – Nov 30, 2026'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'All time'));
      await tap(tester, find.widgetWithText(FilledButton, 'Apply'));

      expect(find.text('All time'), findsOneWidget);
      expect(find.text('€49.00'), findsWidgets);
    });
  });
}
