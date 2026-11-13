import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'backup_importer.dart';

/// Where an import stands.
sealed class ImportStatus {
  const ImportStatus();
}

final class ImportIdle extends ImportStatus {
  const ImportIdle();
}

final class ImportInProgress extends ImportStatus {
  const ImportInProgress();
}

final class ImportDone extends ImportStatus {
  const ImportDone(this.ledger);

  /// What was imported.
  final ImportedLedger ledger;
}

final class ImportFailed extends ImportStatus {
  const ImportFailed();
}

/// The state and the action of importing a backup.
final class ImportViewModel extends ChangeNotifier {
  ImportViewModel({required this._importer});

  final BackupImporter _importer;

  ImportStatus _status = const ImportIdle();

  ImportStatus get status => _status;

  Future<void> importBackup() async {
    _become(const ImportInProgress());
    try {
      final ledger = await _importer.importPickedBackup();
      _become(ledger == null ? const ImportIdle() : ImportDone(ledger));
    } on FormatException {
      _become(const ImportFailed());
    }
  }

  void _become(ImportStatus status) {
    _status = status;
    notifyListeners();
  }
}
