import 'package:atomifi_domain/atomifi_domain.dart';

import 'database.dart';

extension AccountRowCurrency on AccountRow {
  Currency get currency => Currency(currencyCode, decimals: currencyDecimals);
}

/// The currency of every stored account, by account id.
///
/// Amounts are stored as bare minor units; their currency is always the one
/// of the account they belong to.
Future<Map<String, Currency>> currencyByAccountId(
  AtomiFiDatabase database,
) async {
  final rows = await database.select(database.accounts).get();
  return {for (final row in rows) row.id: row.currency};
}
