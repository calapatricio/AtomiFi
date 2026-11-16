import '../ids.dart';
import 'goal.dart';

/// Where goals are kept.
abstract interface class GoalRepository {
  /// Stores [goal], replacing the one with the same id if there is one.
  Future<void> save(Goal goal);

  Future<void> remove(GoalId id);

  /// Every stored goal, ordered by name.
  Future<List<Goal>> all();
}
