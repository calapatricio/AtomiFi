import '../appearance.dart';
import '../ids.dart';
import '../money/currency.dart';

/// A place where money is held: a bank account, cash, a broker.
final class Account {
  const Account({
    required this.id,
    required this.name,
    required this.currency,
    this.appearance = Appearance.none,
    this.isArchived = false,
  });

  final AccountId id;
  final String name;
  final Currency currency;
  final Appearance appearance;

  /// Whether the account is retired: kept with all its records, but out of
  /// sight.
  final bool isArchived;

  Account archived() => _withArchived(true);

  Account restored() => _withArchived(false);

  Account _withArchived(bool isArchived) => Account(
        id: id,
        name: name,
        currency: currency,
        appearance: appearance,
        isArchived: isArchived,
      );
}
