import '../ids.dart';
import 'revaluation.dart';

/// Where revaluations are kept.
abstract interface class RevaluationRepository {
  /// Stores [revaluation], replacing the one with the same id if there is one.
  Future<void> save(Revaluation revaluation);

  Future<void> remove(RevaluationId id);

  /// Every stored revaluation, oldest first.
  Future<List<Revaluation>> all();
}
