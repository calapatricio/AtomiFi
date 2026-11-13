import 'package:atomifi/more/backup_importer.dart';
import 'package:atomifi/more/import_view_model.dart';
import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Importer implements BackupImporter {
  _Importer(this._run);

  final Future<ImportedLedger?> Function() _run;

  @override
  Future<ImportedLedger?> importPickedBackup() => _run();
}

ImportedLedger _ledger() => ImportedLedger(
  accounts: const [],
  categories: const [],
  transactions: const [],
  skippedRows: 9,
);

void main() {
  group('ImportViewModel', () {
    test('has done nothing at first', () {
      final viewModel = ImportViewModel(importer: _Importer(() async => null));

      expect(viewModel.status, isA<ImportIdle>());
    });

    test('tells what was imported', () async {
      final ledger = _ledger();
      final viewModel = ImportViewModel(
        importer: _Importer(() async => ledger),
      );

      await viewModel.importBackup();

      expect((viewModel.status as ImportDone).ledger, ledger);
    });

    test('is busy while the import runs', () async {
      late ImportViewModel viewModel;
      late ImportStatus statusDuringImport;
      viewModel = ImportViewModel(
        importer: _Importer(() async {
          statusDuringImport = viewModel.status;
          return _ledger();
        }),
      );

      await viewModel.importBackup();

      expect(statusDuringImport, isA<ImportInProgress>());
    });

    test('goes back to doing nothing when no file is chosen', () async {
      final viewModel = ImportViewModel(importer: _Importer(() async => null));

      await viewModel.importBackup();

      expect(viewModel.status, isA<ImportIdle>());
    });

    test('says the file could not be read when it is not a backup', () async {
      final viewModel = ImportViewModel(
        importer: _Importer(
          () async => throw const FormatException('not a backup'),
        ),
      );

      await viewModel.importBackup();

      expect(viewModel.status, isA<ImportFailed>());
    });

    test('tells its listeners about each change', () async {
      final viewModel = ImportViewModel(
        importer: _Importer(() async => _ledger()),
      );
      final statuses = <ImportStatus>[];
      viewModel.addListener(() => statuses.add(viewModel.status));

      await viewModel.importBackup();

      expect(statuses, [isA<ImportInProgress>(), isA<ImportDone>()]);
    });
  });
}
