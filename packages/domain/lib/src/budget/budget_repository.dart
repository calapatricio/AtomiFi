import '../ids.dart';
import 'budget.dart';

/// Where budgets are kept.
abstract interface class BudgetRepository {
  /// Stores [budget], replacing the one with the same id if there is one.
  Future<void> save(Budget budget);

  Future<void> remove(BudgetId id);

  /// Every stored budget, ordered by name.
  Future<List<Budget>> all();
}
