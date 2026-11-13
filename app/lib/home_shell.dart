import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';

/// The frame of the app: one screen at a time, and the bar to move between
/// them.
///
/// A screen is built anew each time the user moves to it, so it always
/// shows what is stored at that moment.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.more,
  });

  final WidgetBuilder transactions;
  final WidgetBuilder accounts;
  final WidgetBuilder more;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final screens = [widget.transactions, widget.accounts, widget.more];
    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey(_selected),
        child: screens[_selected](context),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.receipt_long),
            label: texts.transactionsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet),
            label: texts.accountsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: texts.moreTitle,
          ),
        ],
      ),
    );
  }
}
