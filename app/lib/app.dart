import 'package:material_ui/material_ui.dart';

import 'accounts/accounts_screen.dart';
import 'accounts/accounts_view_model.dart';
import 'dependencies.dart';
import 'l10n/app_localizations.dart';

/// The AtomiFi app.
class AtomiFiApp extends StatefulWidget {
  const AtomiFiApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  State<AtomiFiApp> createState() => _AtomiFiAppState();
}

class _AtomiFiAppState extends State<AtomiFiApp> {
  late final _accounts = AccountsViewModel(
    accounts: widget.dependencies.accounts,
    ledger: widget.dependencies.ledger,
    newId: widget.dependencies.newId,
  );

  @override
  void dispose() {
    _accounts.dispose();
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
    home: AccountsScreen(viewModel: _accounts),
  );
}
