import 'cashew_row.dart';
import 'csv_reader.dart';

/// Reads the rows of a Cashew CSV export.
final class CashewExportParser {
  const CashewExportParser({CsvReader reader = const CsvReader()})
      : _reader = reader;

  static const _byteOrderMark = '\uFEFF';

  final CsvReader _reader;

  List<CashewRow> parse(String csv) {
    final text = csv.startsWith(_byteOrderMark) ? csv.substring(1) : csv;
    final records = _reader.read(text);
    if (records.isEmpty) {
      throw const FormatException('The export has no header.');
    }
    final columns = _Columns(records.first);
    return [
      for (final (index, record) in records.skip(1).indexed)
        columns.rowOf(record, number: index + 1),
    ];
  }
}

/// Finds each field of a record by the name of its column.
final class _Columns {
  _Columns(List<String> header)
      : _indexByName = {
          for (final (index, name) in header.indexed) name.trim(): index,
        } {
    for (final name in _needed) {
      if (!_indexByName.containsKey(name)) {
        throw FormatException('The export has no "$name" column.');
      }
    }
  }

  static const _account = 'account';
  static const _amount = 'amount';
  static const _currency = 'currency';
  static const _title = 'title';
  static const _note = 'note';
  static const _date = 'date';
  static const _category = 'category name';
  static const _subcategory = 'subcategory name';

  /// Cashew leaves the amount of a transaction empty until it is paid.
  static const _noAmount = 0.0;
  static const _needed = [
    _account,
    _amount,
    _currency,
    _title,
    _note,
    _date,
    _category,
    _subcategory,
  ];

  final Map<String, int> _indexByName;

  CashewRow rowOf(List<String> record, {required int number}) {
    try {
      final subcategory = _field(record, _subcategory);
      return CashewRow(
        account: _field(record, _account),
        amount: _amountOf(record),
        currencyCode: _field(record, _currency),
        title: _field(record, _title),
        note: _field(record, _note),
        date: _dateOf(record),
        category: _field(record, _category),
        subcategory: subcategory.isEmpty ? null : subcategory,
      );
    } on FormatException catch (error) {
      throw FormatException('Row $number: ${error.message}');
    }
  }

  double _amountOf(List<String> record) {
    final text = _field(record, _amount);
    if (text.isEmpty) return _noAmount;
    return double.tryParse(text) ??
        (throw FormatException('the amount "$text" is not a number'));
  }

  DateTime _dateOf(List<String> record) {
    final text = _field(record, _date);
    return DateTime.tryParse(text) ??
        (throw FormatException('the date "$text" cannot be read'));
  }

  String _field(List<String> record, String name) {
    final index = _indexByName[name]!;
    if (index >= record.length) {
      throw FormatException(
        'it has ${record.length} fields, so it has no "$name"',
      );
    }
    return record[index];
  }
}
