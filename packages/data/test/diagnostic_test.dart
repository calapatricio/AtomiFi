import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('diagnostic', () async {
    final database = await openSeededDatabase();
    final pragma = await database.customSelect('PRAGMA foreign_keys').get();
    print('PRAGMA: ${pragma.map((row) => row.data).toList()}');
    final schema = await database
        .customSelect("SELECT sql FROM sqlite_master WHERE type = 'table'")
        .get();
    for (final row in schema) {
      print('SQL: ${row.data}');
    }
    await database.close();
  });
}
