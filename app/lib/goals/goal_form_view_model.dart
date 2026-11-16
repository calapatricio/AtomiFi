import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// The state and the actions of the form that adds or edits a goal.
final class GoalFormViewModel extends ChangeNotifier {
  GoalFormViewModel({
    required this._goals,
    required Currency currency,
    required this._newId,
    required DateTime Function() now,
    Goal? existing,
  }) : _existing = existing,
       currency = existing?.target.currency ?? currency,
       suggestedDeadline = _oneYearAfter(now()),
       _name = existing?.name ?? '',
       _target = existing?.target.toDecimalString() ?? '',
       _kind = existing?.kind ?? GoalKind.saving,
       _deadline = existing?.deadline;

  final GoalRepository _goals;
  final String Function() _newId;
  final Goal? _existing;

  /// The currency the target is typed in.
  final Currency currency;

  /// The day to start from when a deadline is being chosen.
  final DateTime suggestedDeadline;

  String _name;
  String _target;
  GoalKind _kind;
  DateTime? _deadline;

  /// Whether the form changes a goal instead of adding one.
  bool get isEditing => _existing != null;

  String get name => _name;

  set name(String name) => _change(() => _name = name);

  /// The target as typed.
  String get target => _target;

  set target(String target) => _change(() => _target = target);

  GoalKind get kind => _kind;

  set kind(GoalKind kind) => _change(() => _kind = kind);

  /// The day the goal should be reached by, or nothing for no deadline.
  DateTime? get deadline => _deadline;

  set deadline(DateTime? deadline) => _change(() => _deadline = deadline);

  bool get canSave =>
      _name.trim().isNotEmpty && (_typedTarget?.isPositive ?? false);

  Future<void> save() async {
    final target = _typedTarget;
    if (!canSave || target == null) {
      throw StateError('The goal is not complete yet.');
    }
    await _goals.save(
      Goal(
        id: _existing?.id ?? GoalId(_newId()),
        name: _name.trim(),
        target: target,
        kind: _kind,
        deadline: _deadline,
        appearance: _existing?.appearance ?? Appearance.none,
        itemIds: _existing?.itemIds ?? const {},
      ),
    );
  }

  Money? get _typedTarget => Money.tryParse(_target, currency);

  void _change(void Function() change) {
    change();
    notifyListeners();
  }

  static DateTime _oneYearAfter(DateTime moment) =>
      DateTime(moment.year + 1, moment.month, moment.day);
}
