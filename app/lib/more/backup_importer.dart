import 'package:atomifi_cashew/atomifi_cashew.dart';

/// Lets the user choose a backup of another app and brings it in.
abstract interface class BackupImporter {
  /// Imports the backup the user picks and tells what it held.
  ///
  /// Completes with nothing when the user picks no file, and fails with a
  /// [FormatException] when the file is not a backup that can be read.
  Future<ImportedLedger?> importPickedBackup();
}
