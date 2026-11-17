import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

const _food = Category(
  id: CategoryId('food'),
  name: 'Food',
  side: CategorySide.expense,
);
const _alcohol = Category(
  id: CategoryId('alcohol'),
  name: 'Alcohol',
  side: CategorySide.expense,
);
const _beer = Category(
  id: CategoryId('beer'),
  name: 'Beer',
  side: CategorySide.expense,
  parentId: CategoryId('alcohol'),
);
const _wine = Category(
  id: CategoryId('wine'),
  name: 'Wine',
  side: CategorySide.expense,
  parentId: CategoryId('alcohol'),
);
const _salary = Category(
  id: CategoryId('salary'),
  name: 'Salary',
  side: CategorySide.income,
);
const _categories = [_food, _alcohol, _beer, _wine, _salary];

List<CategoryAmount> _breakdown(
  Map<Category, int> centsByCategory, {
  CategorySide side = CategorySide.expense,
}) =>
    CategoryBreakdown(_categories).of(
      PeriodStats(
        currency: Currency.eur,
        netByCategory: {
          for (final MapEntry(key: category, value: cents)
              in centsByCategory.entries)
            category.id: eur(cents),
        },
        sideOfCategory: {
          for (final category in _categories) category.id: category.side,
        },
      ),
      side,
    );

void main() {
  group('The breakdown of the expenses by category', () {
    test('lists the main categories, the largest first', () {
      final amounts = _breakdown({_food: -2500, _alcohol: -7500});

      expect(amounts.map((amount) => amount.category), [_alcohol, _food]);
      expect(amounts.map((amount) => amount.amount), [eur(7500), eur(2500)]);
    });

    test('tells which part of the whole each one is', () {
      final amounts = _breakdown({_food: -2500, _alcohol: -7500});

      expect(amounts.map((amount) => amount.fraction), [0.75, 0.25]);
    });

    test('counts the subcategories within their category', () {
      final amounts = _breakdown({_alcohol: -1000, _beer: -3000, _wine: -500});

      expect(amounts.single.category, _alcohol);
      expect(amounts.single.amount, eur(4500));
    });

    test('splits a category into its subcategories and itself', () {
      final parts =
          _breakdown({_alcohol: -1000, _beer: -3000, _food: -100}).first.parts;

      expect(parts.map((part) => part.category), [_beer, _alcohol]);
      expect(parts.map((part) => part.amount), [eur(3000), eur(1000)]);
      expect(parts.map((part) => part.fraction), [0.75, 0.25]);
    });

    test('does not split a category whose subcategories have nothing', () {
      expect(_breakdown({_alcohol: -1000}).single.parts, isEmpty);
    });

    test('leaves out the categories with nothing spent, or with more back',
        () {
      final amounts = _breakdown({_food: 300, _alcohol: -100, _salary: 900});

      expect(amounts.map((amount) => amount.category), [_alcohol]);
    });

    test('is empty when there is nothing', () {
      expect(_breakdown({}), isEmpty);
    });
  });

  group('The breakdown of the income by category', () {
    test('lists what came in, as positive amounts', () {
      final amounts = _breakdown(
        {_salary: 9000, _food: -100},
        side: CategorySide.income,
      );

      expect(amounts.single.category, _salary);
      expect(amounts.single.amount, eur(9000));
      expect(amounts.single.fraction, 1);
    });
  });
}
