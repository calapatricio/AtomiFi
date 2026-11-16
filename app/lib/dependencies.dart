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
    required this.budgets,
    required this.budgetAssignments,
    required this.categories,
    required this.goals,
    required this.goalAssignments,
    required this.transactions,
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
    final budgets = DriftBudgetRepository(database);
    final goals = DriftGoalRepository(database);
    return Dependencies(
      accounts: accounts,
      budgets: budgets,
      budgetAssignments: BudgetAssignments(budgets),
      categories: categories,
      goals: goals,
      goalAssignments: GoalAssignments(goals),
      transactions: transactions,
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
          budgets: budgets,
          goals: goals,
        ),
        converter: const CashewBackupConverter(
          defaultCurrencyCode: _defaultCurrencyCode,
        ),
      ),
      newId: const Uuid().v4,
    );
  }

  /// The currency of imported accounts that do not say which one they use,
  /// and of the limits of budgets and the targets of goals.
  static const _defaultCurrencyCode = 'EUR';

  /// The currency amounts that belong to no account are counted in.
  Currency get mainCurrency => Currency.iso(_defaultCurrencyCode);

  final AccountRepository accounts;
  final BudgetRepository budgets;
  final BudgetAssignments budgetAssignments;
  final CategoryRepository categories;
  final GoalRepository goals;
  final GoalAssignments goalAssignments;
  final TransactionRepository transactions;
  final Ledger ledger;
  final BackupImporter backupImporter;
  final String Function() newId;
}
