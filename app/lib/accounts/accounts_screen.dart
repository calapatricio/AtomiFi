import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import 'account_avatar.dart';
import 'accounts_view_model.dart';
import 'add_account_dialog.dart';
import 'remove_account_dialog.dart';

/// Lists the accounts with what each holds, and lets the user add, archive,
/// restore and delete them.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key, required this.viewModel});

  final AccountsViewModel viewModel;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  AccountsViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  Future<void> _add() async {
    final account = await showAddAccountDialog(context);
    if (account == null) return;
    await _viewModel.add(
      name: account.name,
      currencyCode: account.currencyCode,
    );
  }

  Future<void> _remove(Account account) async {
    final removal = _viewModel.removalOf(account);
    final confirmed = await showRemoveAccountDialog(
      context,
      removal: removal,
      balanceChanges: _viewModel.balanceChangesOf(removal),
    );
    if (confirmed) await _viewModel.remove(account);
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(texts.accountsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: texts.addAccount,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) =>
            _viewModel.active.isEmpty && _viewModel.archived.isEmpty
            ? Center(child: Text(texts.noAccounts))
            : _accountList(texts),
      ),
    );
  }

  Widget _accountList(AppLocalizations texts) => ListView(
    children: [
      for (final summary in _viewModel.active)
        _AccountTile(
          summary: summary,
          actions: [
            (texts.archive, () => _viewModel.archive(summary.account)),
            (texts.delete, () => _remove(summary.account)),
          ],
        ),
      if (_viewModel.archived.isNotEmpty)
        ExpansionTile(
          title: Text(texts.archivedAccounts(_viewModel.archived.length)),
          children: [
            for (final summary in _viewModel.archived)
              _AccountTile(
                summary: summary,
                actions: [
                  (texts.restore, () => _viewModel.restore(summary.account)),
                  (texts.delete, () => _remove(summary.account)),
                ],
              ),
          ],
        ),
    ],
  );
}

/// Something the user can do with an account: its label and what it does.
typedef _AccountAction = (String label, VoidCallback run);

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.summary, required this.actions});

  final AccountSummary summary;
  final List<_AccountAction> actions;

  @override
  Widget build(BuildContext context) {
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return ListTile(
      leading: AccountAvatar(account: summary.account),
      title: Text(summary.account.name),
      subtitle: Text(money.format(summary.balance)),
      trailing: PopupMenuButton<VoidCallback>(
        onSelected: (run) => run(),
        itemBuilder: (context) => [
          for (final (label, run) in actions)
            PopupMenuItem(value: run, child: Text(label)),
        ],
      ),
    );
  }
}
