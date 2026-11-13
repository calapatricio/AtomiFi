import 'dart:io';

import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'backup_importer.dart';

/// Imports the Cashew backup file the user picks on the device.
final class CashewBackupFileImporter implements BackupImporter {
  const CashewBackupFileImporter({
    required this._writer,
    required this._converter,
    this._reader = const CashewBackupReader(),
  });

  final LedgerWriter _writer;
  final CashewBackupConverter _converter;
  final CashewBackupReader _reader;

  @override
  Future<ImportedLedger?> importPickedBackup() async {
    final picked = await openFile();
    if (picked == null) return null;
    final ledger = await _read(picked);
    await _writer.write(ledger);
    return ledger;
  }

  /// Reads the picked file from a copy of its own, because what the device
  /// hands over is not always a file that SQLite can open in place.
  Future<ImportedLedger> _read(XFile picked) async {
    final directory = await getTemporaryDirectory();
    final copy = File('${directory.path}/cashew-backup.sqlite');
    await copy.writeAsBytes(await picked.readAsBytes());
    final database = sqlite3.open(copy.path, mode: OpenMode.readOnly);
    try {
      return _converter.convert(_reader.read(database));
    } finally {
      database.close();
      await copy.delete();
    }
  }
}
