import '../ids.dart';
import '../money/currency.dart';

/// A place where money is held: a bank account, cash, a broker.
final class Account {
  const Account({required this.id, required this.name, required this.currency});

  final AccountId id;
  final String name;
  final Currency currency;
}
