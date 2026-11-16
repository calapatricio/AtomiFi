import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// The state and the actions of the form that adds a goal.
final class GoalFormViewModel extends ChangeNotifier {
  GoalFormViewModel({
    required this._goals,
    required this.currency,
    required this._newId,
    required DateTime Function() now,
  }) : suggestedDeadline = _oneYearAfter(now());

  final GoalRepository _goals;
  final String Function() _newId;

  /// The currency the target is typed in.
  final Currency currency;

  /// The day to start from when a deadline is being chosen.
  final DateTime suggestedDeadline;

  String _name = '';
  String _target = '';
  GoalKind _kind = GoalKind.saving;
  DateTime? _deadline;

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
        id: GoalId(_newId()),
        name: _name.trim(),
        target: target,
        kind: _kind,
        deadline: _deadline,
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
