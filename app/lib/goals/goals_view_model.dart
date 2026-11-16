import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// The state and the actions of the list of goals.
final class GoalsViewModel extends ChangeNotifier {
  GoalsViewModel({required this._goals, required this._ledger});

  final GoalRepository _goals;
  final Ledger _ledger;

  List<GoalProgress> _progress = const [];

  /// How far each goal has come, ordered by name.
  List<GoalProgress> get progress => _progress;

  Future<void> load() async {
    final goals = await _goals.all();
    final transactions = (await _ledger.snapshot()).transactions;
    final calculator = GoalProgressCalculator();
    _progress = [
      for (final goal in goals) calculator.progressOf(goal, transactions),
    ];
    notifyListeners();
  }

  Future<void> remove(Goal goal) async {
    await _goals.remove(goal.id);
    await load();
  }
}
