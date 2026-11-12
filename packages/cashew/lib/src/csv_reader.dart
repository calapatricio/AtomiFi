/// Reads comma-separated text into records of fields.
///
/// Fields may be wrapped in double quotes to hold commas, line breaks and,
/// written twice, double quotes.
final class CsvReader {
  const CsvReader();

  List<List<String>> read(String text) {
    final parser = _CsvParser();
    text.split('').forEach(parser.accept);
    return parser.finish();
  }
}

enum _Position { outsideQuotes, insideQuotes, afterQuoteInsideQuotes }

final class _CsvParser {
  final _records = <List<String>>[];
  final _field = StringBuffer();
  var _record = <String>[];
  var _position = _Position.outsideQuotes;

  void accept(String character) {
    switch (_position) {
      case _Position.outsideQuotes:
        _acceptOutsideQuotes(character);
      case _Position.insideQuotes:
        _acceptInsideQuotes(character);
      case _Position.afterQuoteInsideQuotes:
        _acceptAfterQuote(character);
    }
  }

  List<List<String>> finish() {
    if (_position == _Position.insideQuotes) {
      throw const FormatException('A quoted field is never closed.');
    }
    if (_field.isNotEmpty || _record.isNotEmpty) _endRecord();
    return _records;
  }

  void _acceptOutsideQuotes(String character) {
    switch (character) {
      case '"':
        _position = _Position.insideQuotes;
      case ',':
        _endField();
      case '\n':
        _endRecord();
      case '\r':
        return;
      default:
        _field.write(character);
    }
  }

  void _acceptInsideQuotes(String character) {
    if (character == '"') {
      _position = _Position.afterQuoteInsideQuotes;
    } else {
      _field.write(character);
    }
  }

  void _acceptAfterQuote(String character) {
    if (character == '"') {
      _field.write('"');
      _position = _Position.insideQuotes;
    } else {
      _position = _Position.outsideQuotes;
      _acceptOutsideQuotes(character);
    }
  }

  void _endField() {
    _record.add(_field.toString());
    _field.clear();
  }

  void _endRecord() {
    _endField();
    _records.add(_record);
    _record = <String>[];
  }
}
