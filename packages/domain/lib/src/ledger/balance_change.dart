import '../ids.dart';
import '../money/money.dart';

/// Something that changes the balance of one account at one moment.
sealed class BalanceChange {
  const BalanceChange(this.accountId, this.dateTime);

  final AccountId accountId;
  final DateTime dateTime;

  /// The balance of the account once this change has happened.
  Money applyTo(Money balance);
}

/// Money entering (positive) or leaving (negative) an account.
final class Movement extends BalanceChange {
  const Movement(super.accountId, super.dateTime, this.amount);

  final Money amount;

  @override
  Money applyTo(Money balance) => balance + amount;
}

/// A statement of what an account is worth, whatever its balance was.
final class Valuation extends BalanceChange {
  const Valuation(super.accountId, super.dateTime, this.value);

  final Money value;

  @override
  Money applyTo(Money balance) {
    if (value.currency != balance.currency) {
      throw CurrencyMismatch(balance.currency, value.currency);
    }
    return value;
  }
}
