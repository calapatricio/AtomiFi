import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'import_view_model.dart';

/// The things that are done once in a while, such as importing a backup.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.importViewModel});

  final ImportViewModel importViewModel;

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
