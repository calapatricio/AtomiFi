import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// The state and the actions of the list of budgets.
final class BudgetsViewModel extends ChangeNotifier {
  BudgetsViewModel({
    required this._budgets,
    required this._ledger,
    required this._categories,
    required this._now,
  });

  final BudgetRepository _budgets;
  final Ledger _ledger;
  final CategoryRepository _categories;
  final DateTime Function() _now;

  List<BudgetProgress> _progress = const [];

  /// How each budget stands in its current period, ordered by name.
  List<BudgetProgress> get progress => _progress;

  Future<void> load() async {
    final budgets = await _budgets.all();
    final transactions = (await _ledger.snapshot()).transactions;
    final calculator = BudgetProgressCalculator(
      categories: await _categories.all(),
    );
    final now = _now();
    _progress = [
      for (final budget in budgets)
        calculator.progressOf(budget, transactions, at: now),
    ];
    notifyListeners();
  }

  Future<void> remove(Budget budget) async {
    await _budgets.remove(budget.id);
    await load();
  }
}
