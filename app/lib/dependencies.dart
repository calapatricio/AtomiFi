import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:uuid/uuid.dart';

import 'more/backup_importer.dart';
import 'more/cashew_backup_file_importer.dart';

/// Everything the screens need from outside: where things are kept, how
/// new ids are made and how a backup is brought in.
final class Dependencies {
  const Dependencies({
    required this.accounts,
    required this.categories,
    required this.ledger,
    required this.backupImporter,
    required this.newId,
  });

  /// The dependencies of the real app, kept in [database].
  factory Dependencies.onDatabase(AtomiFiDatabase database) {
    final accounts = DriftAccountRepository(database);
    final categories = DriftCategoryRepository(database);
    final transactions = DriftTransactionRepository(database);
    final transfers = DriftTransferRepository(database);
    return Dependencies(
      accounts: accounts,
      categories: categories,
      ledger: Ledger(
        transactions: transactions,
        transfers: transfers,
        revaluations: DriftRevaluationRepository(database),
      ),
      backupImporter: CashewBackupFileImporter(
        writer: LedgerWriter(
          accounts: accounts,
          categories: categories,
          transactions: transactions,
          transfers: transfers,
        ),
        converter: const CashewBackupConverter(
          defaultCurrencyCode: _defaultCurrencyCode,
        ),
      ),
      newId: const Uuid().v4,
    );
  }

  /// The currency of imported accounts that do not say which one they use.
  static const _defaultCurrencyCode = 'EUR';

  final AccountRepository accounts;
  final CategoryRepository categories;
  final Ledger ledger;
  final BackupImporter backupImporter;
  final String Function() newId;
}
