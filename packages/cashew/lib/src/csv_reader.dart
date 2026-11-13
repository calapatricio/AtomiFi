/// Reads comma-separated text into records of fields.
///
/// Fields may be wrapped in double quotes to hold commas, line breaks and,
/// written twice, double quotes. When the records of a text end in CRLF, a
/// line feed on its own is part of a field, quoted or not.
final class CsvReader {
  const CsvReader();

  List<List<String>> read(String text) {
    final parser = _CsvParser(recordsEndInCrLf: text.contains('\r\n'));
    text.split('').forEach(parser.accept);
    return parser.finish();
  }
}

enum _Position {
  outsideQuotes,
  afterCarriageReturn,
  insideQuotes,
  afterQuoteInsideQuotes,
}

final class _CsvParser {
  _CsvParser({required bool recordsEndInCrLf})
      : _recordsEndInCrLf = recordsEndInCrLf;

  final bool _recordsEndInCrLf;
  final _records = <List<String>>[];
  final _field = StringBuffer();
  var _record = <String>[];
  var _position = _Position.outsideQuotes;

  void accept(String character) {
    switch (_position) {
      case _Position.outsideQuotes:
        _acceptOutsideQuotes(character);
      case _Position.afterCarriageReturn:
        _acceptAfterCarriageReturn(character);
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
        _acceptLineFeed();
      case '\r':
        _position = _Position.afterCarriageReturn;
      default:
        _field.write(character);
    }
  }

  void _acceptLineFeed() {
    if (_recordsEndInCrLf) {
      _field.write('\n');
    } else {
      _endRecord();
    }
  }

  void _acceptAfterCarriageReturn(String character) {
    _position = _Position.outsideQuotes;
    if (character == '\n') {
      _endRecord();
    } else {
      _acceptOutsideQuotes(character);
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
