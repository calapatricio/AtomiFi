import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('PeriodStats', () {
    final stats = PeriodStats(
      currency: Currency.eur,
      netByCategory: {
        const CategoryId('food'): eur(-4000),
        const CategoryId('salary'): eur(10000),
        const CategoryId('correction'): eur(-250),
      },
      sideOfCategory: const {
        CategoryId('food'): CategorySide.expense,
        CategoryId('salary'): CategorySide.income,
        CategoryId('correction'): CategorySide.neutral,
      },
    );

    test('tells what is left of the income after the expenses', () {
      expect(stats.balance, eur(6000));
    });

    test('tells what balance corrections added or took, apart', () {
      expect(stats.corrections, eur(-250));
    });
  });
}
