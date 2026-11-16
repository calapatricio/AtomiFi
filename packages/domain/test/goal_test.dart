import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

Goal _goal({
  String id = 'pizza',
  GoalKind kind = GoalKind.saving,
  int targetCents = 50000,
  Set<ItemId> itemIds = const {},
}) =>
    Goal(
      id: GoalId(id),
      name: id,
      target: eur(targetCents),
      kind: kind,
      itemIds: itemIds,
    );

GoalProgress _progress(
  Goal goal,
  List<Transaction> ledger, {
  CurrencyConverter? converter,
}) =>
    GoalProgressCalculator(converter: converter).progressOf(goal, ledger);

void main() {
  group('Goal', () {
    test('rejects a target that is not positive', () {
      expect(() => _goal(targetCents: 0), throwsArgumentError);
    });

    test('can hold other items, keeping everything else', () {
      final goal = _goal(itemIds: {const ItemId('first')})
          .withItems({const ItemId('second')});

      expect(goal.itemIds, {const ItemId('second')});
      expect(goal.id, const GoalId('pizza'));
      expect(goal.kind, GoalKind.saving);
    });
  });

  group('A goal to save', () {
    final goal = _goal(itemIds: {const ItemId('bonus'), const ItemId('fee')});

    test('grows with the money put in it and shrinks with what is taken', () {
      final progress = _progress(goal, [
        on(DateTime(2026, 11, 1), [mine(20000, id: 'bonus')]),
        on(DateTime(2026, 11, 5), [mine(-1500, id: 'fee')]),
        on(DateTime(2026, 11, 6), [mine(99900, id: 'other')]),
      ]);

      expect(progress.reached, eur(18500));
      expect(progress.remaining, eur(31500));
      expect(progress.isReached, isFalse);
    });

    test('counts only my share of an item', () {
      final progress = _progress(goal, [
        on(DateTime(2026, 11, 1), [
          shared({me: 12000, moy: 8000}, id: 'bonus'),
        ]),
      ]);

      expect(progress.reached, eur(12000));
    });

    test('is reached once its target is covered', () {
      final progress = _progress(goal, [
        on(DateTime(2026, 11, 1), [mine(50000, id: 'bonus')]),
      ]);

      expect(progress.remaining, eur(0));
      expect(progress.isReached, isTrue);
    });

    test('counts items in other currencies in its own', () {
      final dollars = Item.mine(
        id: const ItemId('bonus'),
        name: 'Bonus',
        categoryId: const CategoryId('salary'),
        price: usd(10800),
      );

      final progress = _progress(
        goal,
        [
          on(DateTime(2026, 11, 2), [dollars], account: broker),
        ],
        converter: RateTable(
          base: Currency.eur,
          unitsPerBase: {Currency.usd: 1.08},
        ),
      );

      expect(progress.reached, eur(10000));
    });
  });

  group('A goal to spend', () {
    test('grows with what is spent towards it', () {
      final goal = _goal(
        kind: GoalKind.spending,
        itemIds: {const ItemId('deposit'), const ItemId('refund')},
      );

      final progress = _progress(goal, [
        on(DateTime(2026, 11, 1), [mine(-30000, id: 'deposit')]),
        on(DateTime(2026, 11, 9), [mine(5000, id: 'refund')]),
      ]);

      expect(progress.reached, eur(25000));
    });
  });

  group('GoalAssignments', () {
    late InMemoryStore store;
    late GoalAssignments assignments;

    setUp(() async {
      store = InMemoryStore();
      assignments = GoalAssignments(store.goals);
      await store.goals.save(_goal(itemIds: {const ItemId('bonus')}));
      await store.goals.save(_goal(id: 'car'));
    });

    Future<Set<ItemId>> itemsOf(String id) async =>
        (await store.goals.all()).firstWhere((goal) => goal.id == GoalId(id))
            .itemIds;

    test('offers every goal', () async {
      final goals = await assignments.goals();

      expect(goals.map((goal) => goal.id), const [GoalId('car'), GoalId('pizza')]);
    });

    test('tells which goal each item counts towards', () async {
      expect(
        await assignments.goalOfEach(const [ItemId('bonus'), ItemId('fee')]),
        {const ItemId('bonus'): const GoalId('pizza')},
      );
    });

    test('moves an item to the goal chosen for it', () async {
      await assignments.assign({const ItemId('bonus'): const GoalId('car')});

      expect(await itemsOf('pizza'), isEmpty);
      expect(await itemsOf('car'), {const ItemId('bonus')});
    });

    test('takes an item out when no goal is chosen for it', () async {
      await assignments.assign({const ItemId('bonus'): null});

      expect(await itemsOf('pizza'), isEmpty);
    });
  });
}
