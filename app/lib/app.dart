import 'package:material_ui/material_ui.dart';

import 'accounts/accounts_screen.dart';
import 'accounts/accounts_view_model.dart';
import 'dependencies.dart';
import 'home_shell.dart';
import 'l10n/app_localizations.dart';
import 'more/import_view_model.dart';
import 'more/more_screen.dart';
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
  late final _import = ImportViewModel(importer: _dependencies.backupImporter);

  @override
  void dispose() {
    _transactions.dispose();
    _accounts.dispose();
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
      transactions: (_) => TransactionsScreen(viewModel: _transactions),
      accounts: (_) => AccountsScreen(viewModel: _accounts),
      more: (_) => MoreScreen(importViewModel: _import),
    ),
  );
}
