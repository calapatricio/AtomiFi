import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:uuid/uuid.dart';

/// Everything the screens need from outside: where things are kept and how
/// new ids are made.
final class Dependencies {
  const Dependencies({
    required this.accounts,
    required this.ledger,
    required this.newId,
  });

  /// The dependencies of the real app, kept in [database].
  factory Dependencies.onDatabase(AtomiFiDatabase database) => Dependencies(
        accounts: DriftAccountRepository(database),
        ledger: Ledger(
          transactions: DriftTransactionRepository(database),
          transfers: DriftTransferRepository(database),
          revaluations: DriftRevaluationRepository(database),
        ),
        newId: const Uuid().v4,
      );

  final AccountRepository accounts;
  final Ledger ledger;
  final String Function() newId;
}
