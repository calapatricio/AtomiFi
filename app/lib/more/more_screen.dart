import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'import_view_model.dart';

/// The things that are looked at or done once in a while, such as the
/// accounts, the goals or importing a backup.
class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.importViewModel,
    required this.openGoals,
    required this.openAccounts,
  });

  final ImportViewModel importViewModel;

  /// Opens the list of goals.
  final void Function(BuildContext context) openGoals;

  /// Opens the list of accounts.
  final void Function(BuildContext context) openAccounts;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(texts.moreTitle)),
      body: ListenableBuilder(
        listenable: importViewModel,
        builder: (context, _) {
          final status = importViewModel.status;
          final isBusy = status is ImportInProgress;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: Text(texts.accountsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openAccounts(context),
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(texts.goalsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openGoals(context),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(texts.importCashewBackup),
                subtitle: Text(_describe(status, texts)),
                trailing: isBusy ? const CircularProgressIndicator() : null,
                enabled: !isBusy,
                onTap: importViewModel.importBackup,
              ),
            ],
          );
        },
      ),
    );
  }

  static String _describe(ImportStatus status, AppLocalizations texts) =>
      switch (status) {
        ImportIdle() => texts.importCashewBackupHint,
        ImportInProgress() => texts.importInProgress,
        ImportFailed() => texts.importFailed,
        ImportDone(:final ledger) => texts.importDone(
          ledger.transactions.length,
          ledger.transfers.length,
          ledger.skippedRows,
        ),
      };
}
