import 'package:atomifi/stats/stats_screen.dart';
import 'package:atomifi/widgets/line_chart.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('StatsScreen', () {
    late InMemoryStore store;
    Transaction? opened;

    setUp(() async {
      store = await seededStore();
      await store.categories.save(beer);
      opened = null;
    });

    Future<void> record() async {
      for (final transaction in [
        spending('shop', centsByCategory: const {food: -1000}),
        spending(
          'bar',
          name: 'Bar',
          centsByCategory: const {alcohol: -1000, beer: -2000},
        ),
        spending(
          'old',
          name: 'Old shop',
          dateTime: DateTime(2026, 10, 20),
          centsByCategory: const {food: -900},
        ),
        income('payroll', bank, 200000),
      ]) {
        await store.transactions.save(transaction);
      }
    }

    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      StatsScreen(
        viewModel: statsViewModelOn(store),
        openTransaction: (context, transaction) async => opened = transaction,
      ),
    );

    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    /// Scrolls the screen down until [finder] finds something.
    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        150,
        scrollable: find.byType(Scrollable).first,
      );
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
      expect(find.text('€1,960.00'), findsWidgets);
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

    testWidgets('unfolds the subcategories of the category that is tapped', (
      tester,
    ) async {
      await record();
      await pump(tester);

      await tap(tester, find.text('Alcohol'));

      expect(find.text('Beer'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('€20.00'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);

      await tap(tester, find.text('Alcohol').first);

      expect(find.text('Beer'), findsNothing);
    });

    testWidgets('shows the income when it is chosen', (tester) async {
      await record();
      await pump(tester);

      await tap(tester, find.widgetWithText(ChoiceChip, 'Income'));

      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('tells the total of the day that is touched in the line', (
      tester,
    ) async {
      await record();
      await pump(tester);
      await scrollTo(tester, find.byType(LineChart));

      await tester.tapAt(
        tester.getTopLeft(find.byType(LineChart)) + const Offset(2, 20),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nov 1, 2026'), findsOneWidget);
      expect(find.text('€2,000.00'), findsWidgets);
    });

    testWidgets('lists the transactions of the period', (tester) async {
      await record();
      await pump(tester);
      await scrollTo(tester, find.text('Payroll'));

      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Old shop'), findsNothing);
    });

    testWidgets('lists only those of the category that is tapped', (
      tester,
    ) async {
      await record();
      await pump(tester);

      await tap(tester, find.text('Alcohol'));
      await scrollTo(tester, find.text('Bar'));

      expect(find.text('Bar'), findsOneWidget);
      expect(find.text('Supermarket'), findsNothing);
      expect(find.text('Payroll'), findsNothing);
    });

    testWidgets('opens the transaction that is tapped', (tester) async {
      await record();
      await pump(tester);
      await scrollTo(tester, find.text('Payroll'));

      await tap(tester, find.text('Payroll'));

      expect(opened?.id, const TransactionId('payroll'));
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
      expect(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
        findsNothing,
      );
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
