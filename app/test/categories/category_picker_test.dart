import 'package:atomifi/categories/category_picker.dart';
import 'package:atomifi/transactions/transaction_form_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

const leisure = Category(
  id: CategoryId('leisure'),
  name: 'Leisure',
  side: CategorySide.expense,
);
const cinema = Category(
  id: CategoryId('cinema'),
  name: 'Cinema',
  side: CategorySide.expense,
  parentId: CategoryId('leisure'),
);

void main() {
  group('pickCategory', () {
    late InMemoryStore store;
    late TransactionFormViewModel choices;
    late List<CategoryId?> picked;

    setUp(() async {
      store = await seededStore();
      await store.categories.save(leisure);
      await store.categories.save(cinema);
      choices = transactionFormOn(store);
      await choices.load();
      picked = [];
    });

    /// Shows a button that opens the picker and records what it gives.
    Future<void> open(WidgetTester tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  picked.add(await pickCategory(context, choices)),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the categories and not the subcategories', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Leisure'), findsOneWidget);
      expect(find.text('Cinema'), findsNothing);
    });

    testWidgets('gives the category that is tapped', (tester) async {
      await open(tester);

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      expect(picked, [food.id]);
    });

    testWidgets('gives nothing when it is dismissed', (tester) async {
      await open(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(picked, [null]);
    });

    testWidgets('goes on to the subcategories of a category that has them', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Leisure'));
      await tester.pumpAndSettle();
      expect(find.text('None'), findsOneWidget);
      await tester.tap(find.text('Cinema'));
      await tester.pumpAndSettle();

      expect(picked, [cinema.id]);
    });

    testWidgets('gives the category itself when no subcategory is wanted', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Leisure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      expect(picked, [leisure.id]);
    });

    testWidgets('adds a category on the spot and gives it', (tester) async {
      await open(tester);

      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Sport');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sport = (await store.categories.all()).firstWhere(
        (category) => category.name == 'Sport',
      );
      expect(picked, [sport.id]);
    });

    testWidgets('adds a subcategory under the category that was tapped', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Leisure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Concerts');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final concerts = (await store.categories.all()).firstWhere(
        (category) => category.name == 'Concerts',
      );
      expect(concerts.parentId, leisure.id);
      expect(picked, [concerts.id]);
    });
  });
}
