import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  late AtomiFiDatabase database;
  late CategoryRepository categories;

  setUp(() {
    database = openDatabase();
    categories = DriftCategoryRepository(database);
  });

  tearDown(() => database.close());

  group('DriftCategoryRepository', () {
    test('starts without categories', () async {
      expect(await categories.all(), isEmpty);
    });

    test('returns the categories it saved, ordered by name', () async {
      await categories.save(salary);
      await categories.save(food);

      final saved = await categories.all();

      expect(saved.map((category) => category.id), [food.id, salary.id]);
      expect(saved.map((category) => category.name), ['Food', 'Salary']);
      expect(
        saved.map((category) => category.side),
        [CategorySide.expense, CategorySide.income],
      );
    });

    test('remembers which category a subcategory belongs to', () async {
      await categories.save(leisure);
      await categories.save(alcohol);

      final saved = await categories.all();

      expect(saved.map((category) => category.parentId), [leisure.id, null]);
    });

    test('restores how a category looks', () async {
      const looks =
          Appearance(color: 0xFFFFEB3B, iconName: 'tram', emoji: '🚋');
      await categories.save(
        const Category(
          id: CategoryId('transport'),
          name: 'Transport',
          side: CategorySide.expense,
          appearance: looks,
        ),
      );

      expect((await categories.all()).single.appearance, looks);
    });

    test('restores a category that looks like nothing in particular', () async {
      await categories.save(food);

      expect((await categories.all()).single.appearance, Appearance.none);
    });

    test('saving a category again replaces it', () async {
      await categories.save(food);
      await categories.save(
        const Category(
          id: CategoryId('food'),
          name: 'Eating out',
          side: CategorySide.expense,
        ),
      );

      expect((await categories.all()).single.name, 'Eating out');
    });
  });
}
