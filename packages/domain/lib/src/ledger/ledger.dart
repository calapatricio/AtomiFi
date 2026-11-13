import 'ledger_record.dart';
import 'revaluation.dart';
import 'revaluation_repository.dart';
import 'transaction.dart';
import 'transaction_repository.dart';
import 'transfer.dart';
import 'transfer_repository.dart';

/// Everything recorded in the ledger at one moment.
final class LedgerSnapshot {
  const LedgerSnapshot({
    required this.transactions,
    required this.transfers,
    required this.revaluations,
  });

  static const empty = LedgerSnapshot(
    transactions: [],
    transfers: [],
    revaluations: [],
  );

  final List<Transaction> transactions;
  final List<Transfer> transfers;
  final List<Revaluation> revaluations;

  List<LedgerRecord> get records => [
        ...transactions,
        ...transfers,
        ...revaluations,
      ];
}

/// Reads the whole ledger from wherever its records are kept.
final class Ledger {
  Ledger({
    required TransactionRepository transactions,
    required TransferRepository transfers,
    required RevaluationRepository revaluations,
  })  : _transactions = transactions,
        _transfers = transfers,
        _revaluations = revaluations;

  final TransactionRepository _transactions;
  final TransferRepository _transfers;
  final RevaluationRepository _revaluations;

  Future<LedgerSnapshot> snapshot() async => LedgerSnapshot(
        transactions: await _transactions.all(),
        transfers: await _transfers.all(),
        revaluations: await _revaluations.all(),
      );
}
