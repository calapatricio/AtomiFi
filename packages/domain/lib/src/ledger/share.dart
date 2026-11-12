import '../money/money.dart';
import 'party.dart';

/// The part of an item's price borne by one [party].
final class Share {
  const Share(this.party, this.amount);

  final Party party;
  final Money amount;

  @override
  bool operator ==(Object other) =>
      other is Share && other.party == party && other.amount == amount;

  @override
  int get hashCode => Object.hash(party, amount);

  @override
  String toString() => '$party: $amount';
}
