import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// The SQLite database that holds everything AtomiFi stores.
@DriftDatabase(tables: [Accounts])
class AtomiFiDatabase extends _$AtomiFiDatabase {
  AtomiFiDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
