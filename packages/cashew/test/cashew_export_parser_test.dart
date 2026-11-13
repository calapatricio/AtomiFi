import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:test/test.dart';

import 'support/sample.dart';

void main() {
  group('CashewExportParser', () {
    const parser = CashewExportParser();

    test('reads one row per record, even when a note spans lines', () {
      final rows = parser.parse(sampleExport);

      expect(rows, hasLength(4));
      expect(rows[1].note, 'Tacos - 14€\nCooltra - 4,5€');
    });

    test('reads the fields of a row', () {
      final row = parser.parse(sampleExport).first;

      expect(row.account, 'Imagin');
      expect(row.amount, -0.5);
      expect(row.currencyCode, 'EUR');
      expect(row.title, 'BiciMad');
      expect(row.note, isEmpty);
      expect(row.date, DateTime(2026, 11, 9, 4, 40, 33));
      expect(row.category, 'Transporte');
      expect(row.subcategory, isNull);
    });

    test('reads the subcategory when there is one', () {
      expect(parser.parse(sampleExport)[2].subcategory, 'Alcohol');
    });

    test('finds the columns by name, whatever their order', () {
      const reordered = 'title,date,amount,currency,account,note,'
          'subcategory name,category name\n'
          'Chino,2026-11-07 21:49:20.000,-4.1,EUR,Imagin,,,Comestibles\n';

      final row = parser.parse(reordered).single;

      expect(row.title, 'Chino');
      expect(row.amount, -4.1);
      expect(row.category, 'Comestibles');
    });

    test('ignores a byte order mark before the header', () {
      expect(parser.parse('\uFEFF$sampleExport'), hasLength(4));
    });

    test('reads no rows from an export with only a header', () {
      expect(parser.parse('$header\n'), isEmpty);
    });

    test('rejects an export without a column it needs', () {
      expect(
        () => parser.parse('account,amount\nImagin,-1\n'),
        throwsFormatException,
      );
    });

    test('rejects a row whose date cannot be read, saying which', () {
      const broken = '$header\n'
          'Imagin,-1,,EUR,BiciMad,,yesterday,false,default,Transporte,,,,,,,\n'
          'Imagin,-1,,EUR,BiciMad,,9 Nov,false,default,Transporte,,,,,,,\n';

      expect(
        () => parser.parse(broken),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Row 1: the date "yesterday" cannot be read',
          ),
        ),
      );
    });

    test('rejects a row whose amount is not a number', () {
      const broken = '$header\n'
          'Imagin,five,,EUR,BiciMad,,2026-11-09 04:40:33.000,false,default,'
          'Transporte,,,,,,,\n';

      expect(
        () => parser.parse(broken),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Row 1: the amount "five" is not a number',
          ),
        ),
      );
    });
  });
}
