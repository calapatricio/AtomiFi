import 'package:atomifi/more/backup_importer.dart';
import 'package:atomifi/more/import_view_model.dart';
import 'package:atomifi/more/more_screen.dart';
import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

final class _Importer implements BackupImporter {
  _Importer(this._run);

  final Future<ImportedLedger?> Function() _run;

  @override
  Future<ImportedLedger?> importPickedBackup() => _run();
}

void main() {
  group('MoreScreen', () {
    Future<void> pump(
      WidgetTester tester,
      Future<ImportedLedger?> Function() import,
    ) => pumpScreen(
      tester,
      MoreScreen(importViewModel: ImportViewModel(importer: _Importer(import))),
    );

    testWidgets('offers to import a Cashew backup', (tester) async {
      await pump(tester, () async => null);

      expect(find.text('Import a Cashew backup'), findsOneWidget);
    });

    testWidgets('says what was imported', (tester) async {
      await pump(
        tester,
        () async => ImportedLedger(
          accounts: const [],
          categories: const [],
          transactions: [spending('one'), spending('two')],
          transfers: [transfer('deposit', bank, savings, 30000)],
          skippedRows: 9,
        ),
      );

      await tester.tap(find.text('Import a Cashew backup'));
      await tester.pumpAndSettle();

      expect(
        find.text('Imported. Transactions: 2. Transfers: 1. Skipped: 9.'),
        findsOneWidget,
      );
    });

    testWidgets('says so when the file is not a backup', (tester) async {
      await pump(tester, () async => throw const FormatException('no'));

      await tester.tap(find.text('Import a Cashew backup'));
      await tester.pumpAndSettle();

      expect(
        find.text('This file is not a Cashew backup that can be read.'),
        findsOneWidget,
      );
    });
  });
}
