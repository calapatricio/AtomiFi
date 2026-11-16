import 'dart:math' as math;

import 'package:atomifi_domain/atomifi_domain.dart';

/// Reads the amounts that Cashew keeps for a wallet, such as the limit of a
/// budget or the target of a goal, in the currency of that wallet.
final class WalletAmounts {
  WalletAmounts({
    required List<Account> accounts,
    required Currency defaultCurrency,
  })  : _currencyByAccountId = {
          for (final account in accounts) account.id.value: account.currency,
        },
        _defaultCurrency = defaultCurrency;

  final Map<String, Currency> _currencyByAccountId;
  final Currency _defaultCurrency;

  /// [amount] without its sign, in the currency of the wallet with
  /// [walletId], or in the default one when that wallet is not known.
  Money of(String walletId, double amount) {
    final currency = _currencyByAccountId[walletId] ?? _defaultCurrency;
    final scale = math.pow(10, currency.decimals);
    return Money((amount.abs() * scale).round(), currency);
  }
}
