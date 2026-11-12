/// One transaction as Cashew exports it.
final class CashewRow {
  const CashewRow({
    required this.account,
    required this.amount,
    required this.currencyCode,
    required this.title,
    required this.note,
    required this.date,
    required this.category,
    this.subcategory,
  });

  final String account;

  /// Negative for money spent. Cashew stores it as a fraction, so it can
  /// carry noise such as `21.200000000000003`.
  final double amount;
  final String currencyCode;
  final String title;
  final String note;
  final DateTime date;
  final String category;
  final String? subcategory;
}
