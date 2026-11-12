import 'package:atomifi_domain/atomifi_domain.dart' show CategorySide;
import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// The SQLite database that holds everything AtomiFi stores.
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Items,
    Shares,
    Transfers,
    Revaluations,
  ],
)
class AtomiFiDatabase extends _$AtomiFiDatabase {
  AtomiFiDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
      );
}
