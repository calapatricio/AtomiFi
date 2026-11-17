import 'dart:async';

import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import 'accounts/accounts_screen.dart';
import 'accounts/accounts_view_model.dart';
import 'budgets/budget_form_screen.dart';
import 'budgets/budget_form_view_model.dart';
import 'budgets/budgets_screen.dart';
import 'budgets/budgets_view_model.dart';
import 'dependencies.dart';
import 'goals/goal_form_screen.dart';
import 'goals/goal_form_view_model.dart';
import 'goals/goals_screen.dart';
import 'goals/goals_view_model.dart';
import 'home_shell.dart';
import 'l10n/app_localizations.dart';
import 'more/import_view_model.dart';
import 'more/more_screen.dart';
import 'stats/stats_screen.dart';
import 'stats/stats_view_model.dart';
import 'transactions/transaction_form_screen.dart';
import 'transactions/transaction_form_view_model.dart';
import 'transactions/transactions_screen.dart';
import 'transactions/transactions_view_model.dart';

/// The AtomiFi app.
class AtomiFiApp extends StatefulWidget {
  const AtomiFiApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  State<AtomiFiApp> createState() => _AtomiFiAppState();
}

class _AtomiFiAppState extends State<AtomiFiApp> {
  Dependencies get _dependencies => widget.dependencies;

  late final _transactions = TransactionsViewModel(
    ledger: _dependencies.ledger,
    accounts: _dependencies.accounts,
    categories: _dependencies.categories,
  );
  late final _accounts = AccountsViewModel(
    accounts: _dependencies.accounts,
    ledger: _dependencies.ledger,
    newId: _dependencies.newId,
  );
  late final _budgets = BudgetsViewModel(
    budgets: _dependencies.budgets,
    ledger: _dependencies.ledger,
    categories: _dependencies.categories,
    now: DateTime.now,
  );
  late final _goals = GoalsViewModel(
    goals: _dependencies.goals,
    ledger: _dependencies.ledger,
  );
  late final _stats = StatsViewModel(
    ledger: _dependencies.ledger,
    categories: _dependencies.categories,
    currency: _dependencies.mainCurrency,
    now: DateTime.now,
  );
  late final _import = ImportViewModel(importer: _dependencies.backupImporter);

  Future<void> _openTransactionForm(
    BuildContext context, {
    Transaction? existing,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TransactionFormScreen(
        viewModel: TransactionFormViewModel(
          transactions: _dependencies.transactions,
          accounts: _dependencies.accounts,
          categories: _dependencies.categories,
          budgets: _dependencies.budgetAssignments,
          goals: _dependencies.goalAssignments,
          newId: _dependencies.newId,
          now: DateTime.now,
          existing: existing,
        ),
      ),
    ),
  );

  Future<void> _openBudgetForm(BuildContext context, {Budget? existing}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BudgetFormScreen(
            viewModel: BudgetFormViewModel(
              budgets: _dependencies.budgets,
              categories: _dependencies.categories,
              currency: _dependencies.mainCurrency,
              newId: _dependencies.newId,
              now: DateTime.now,
              existing: existing,
            ),
          ),
        ),
      );

  void _openAccounts(BuildContext context) => unawaited(
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AccountsScreen(viewModel: _accounts)),
    ),
  );

  void _openGoals(BuildContext context) => unawaited(
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GoalsScreen(viewModel: _goals, openForm: _openGoalForm),
      ),
    ),
  );

  Future<void> _openGoalForm(BuildContext context, {Goal? existing}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => GoalFormScreen(
            viewModel: GoalFormViewModel(
              goals: _dependencies.goals,
              currency: _dependencies.mainCurrency,
              newId: _dependencies.newId,
              now: DateTime.now,
              existing: existing,
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _transactions.dispose();
    _accounts.dispose();
    _budgets.dispose();
    _goals.dispose();
    _stats.dispose();
    _import.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomeShell(
      transactions: (_) => TransactionsScreen(
        viewModel: _transactions,
        openForm: _openTransactionForm,
      ),
      stats: (_) => StatsScreen(viewModel: _stats),
      budgets: (_) =>
          BudgetsScreen(viewModel: _budgets, openForm: _openBudgetForm),
      more: (_) => MoreScreen(
        importViewModel: _import,
        openGoals: _openGoals,
        openAccounts: _openAccounts,
      ),
    ),
  );
}
