import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

Goal _goal({
  String id = 'pizza',
  String name = 'Pizza oven',
  Money? target,
  GoalKind kind = GoalKind.saving,
  DateTime? deadline,
  Appearance appearance = Appearance.none,
  Set<ItemId> itemIds = const {},
}) =>
    Goal(
      id: GoalId(id),
      name: name,
      target: target ?? eur(50000),
      kind: kind,
      deadline: deadline,
      appearance: appearance,
      itemIds: itemIds,
    );

void main() {
  late AtomiFiDatabase database;
  late GoalRepository goals;

  setUp(() {
    database = openDatabase();
    goals = DriftGoalRepository(database);
  });

  tearDown(() => database.close());

  group('DriftGoalRepository', () {
    test('starts without goals', () async {
      expect(await goals.all(), isEmpty);
    });

    test('restores a goal as it was saved', () async {
      const looks = Appearance(color: 0xFF4CAF50, emoji: '🍕');
      await goals.save(
        _goal(
          target: usd(99900),
          kind: GoalKind.spending,
          deadline: DateTime(2026, 12, 31),
          appearance: looks,
        ),
      );

      final restored = (await goals.all()).single;

      expect(restored.id, const GoalId('pizza'));
      expect(restored.name, 'Pizza oven');
      expect(restored.target, usd(99900));
      expect(restored.kind, GoalKind.spending);
      expect(restored.deadline, DateTime(2026, 12, 31));
      expect(restored.appearance, looks);
    });

    test('restores a goal without a deadline', () async {
      await goals.save(_goal());

      expect((await goals.all()).single.deadline, isNull);
    });

    test('restores the items that count towards a goal', () async {
      await goals.save(
        _goal(itemIds: const {ItemId('bonus'), ItemId('gift')}),
      );

      expect(
        (await goals.all()).single.itemIds,
        const {ItemId('bonus'), ItemId('gift')},
      );
    });

    test('saving a goal again replaces it and its items', () async {
      await goals.save(_goal(itemIds: const {ItemId('bonus'), ItemId('gift')}));
      await goals.save(_goal(name: 'Oven', itemIds: const {ItemId('gift')}));

      final restored = (await goals.all()).single;

      expect(restored.name, 'Oven');
      expect(restored.itemIds, const {ItemId('gift')});
    });

    test('returns the goals ordered by name', () async {
      await goals.save(_goal(id: 'pizza', name: 'Pizza oven'));
      await goals.save(_goal(id: 'car', name: 'Car'));

      final restored = await goals.all();

      expect(restored.map((goal) => goal.name), ['Car', 'Pizza oven']);
    });

    test('removes a goal with its items', () async {
      await goals.save(_goal(itemIds: const {ItemId('bonus')}));

      await goals.remove(const GoalId('pizza'));

      expect(await goals.all(), isEmpty);
      expect(await database.select(database.goalItems).get(), isEmpty);
    });
  });
}
