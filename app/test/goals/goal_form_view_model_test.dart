import 'package:atomifi/goals/goal_form_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('GoalFormViewModel', () {
    late InMemoryStore store;
    late GoalFormViewModel form;

    Future<Goal> saved() async => (await store.goals.all()).single;

    setUp(() async {
      store = await seededStore();
      form = goalFormOn(store);
    });

    test('starts as a goal to save, without a deadline', () {
      expect(form.kind, GoalKind.saving);
      expect(form.deadline, isNull);
      expect(form.canSave, isFalse);
    });

    test('saves a goal with its name and target', () async {
      form
        ..name = ' Pizza oven '
        ..target = '500';

      await form.save();
      final goal = await saved();

      expect(goal.id, const GoalId('new-0'));
      expect(goal.name, 'Pizza oven');
      expect(goal.target, eur(50000));
      expect(goal.kind, GoalKind.saving);
      expect(goal.deadline, isNull);
      expect(goal.itemIds, isEmpty);
    });

    test('saves a goal to spend, with its deadline', () async {
      form
        ..name = 'Trip'
        ..target = '1200.50'
        ..kind = GoalKind.spending
        ..deadline = DateTime(2027, 6, 30);

      await form.save();
      final goal = await saved();

      expect(goal.target, eur(120050));
      expect(goal.kind, GoalKind.spending);
      expect(goal.deadline, DateTime(2027, 6, 30));
    });

    test('suggests a deadline one year from now', () {
      expect(form.suggestedDeadline, DateTime(2027, 11, 13));
    });

    test('cannot save without a name', () {
      form.target = '500';

      expect(form.canSave, isFalse);
    });

    test('cannot save without a target above zero', () {
      form.name = 'Pizza oven';

      for (final target in ['', 'abc', '0', '-5']) {
        form.target = target;
        expect(form.canSave, isFalse, reason: 'target "$target"');
      }
    });

    test('refuses to save while it is not complete', () {
      expect(form.save, throwsStateError);
    });

    test('tells its listeners about every change', () {
      var notifications = 0;
      form
        ..addListener(() => notifications++)
        ..name = 'Trip'
        ..target = '5'
        ..kind = GoalKind.spending
        ..deadline = DateTime(2027);

      expect(notifications, 4);
    });
  });

  group('Editing a goal', () {
    late InMemoryStore store;
    late GoalFormViewModel form;
    final goal = pizzaGoal(
      kind: GoalKind.spending,
      deadline: DateTime(2026, 12, 31),
      itemIds: {const ItemId('deposit')},
    );

    setUp(() async {
      store = await seededStore();
      await store.goals.save(goal);
      form = goalFormOn(store, existing: goal);
    });

    test('starts from what it holds', () {
      expect(form.isEditing, isTrue);
      expect(form.name, 'Pizza oven');
      expect(form.target, '500.00');
      expect(form.kind, GoalKind.spending);
      expect(form.deadline, DateTime(2026, 12, 31));
      expect(form.canSave, isTrue);
    });

    test('replaces it, keeping its id, its looks and its items', () async {
      form
        ..name = 'Big oven'
        ..target = '800'
        ..deadline = null;

      await form.save();
      final saved = (await store.goals.all()).single;

      expect(saved.id, const GoalId('pizza'));
      expect(saved.name, 'Big oven');
      expect(saved.target, eur(80000));
      expect(saved.deadline, isNull);
      expect(saved.appearance, const Appearance(emoji: '🍕'));
      expect(saved.itemIds, {const ItemId('deposit')});
    });
  });
}
