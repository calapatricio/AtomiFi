import 'package:atomifi_cashew/atomifi_cashew.dart';
import 'package:test/test.dart';

void main() {
  group('CsvReader', () {
    const reader = CsvReader();

    test('splits the text into records and fields', () {
      expect(reader.read('a,b\n1,2'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('keeps empty fields', () {
      expect(reader.read('a,,c,'), [
        ['a', '', 'c', ''],
      ]);
    });

    test('keeps commas and line breaks inside quoted fields', () {
      expect(reader.read('a,"1,5\n2,5",c'), [
        ['a', '1,5\n2,5', 'c'],
      ]);
    });

    test('reads a doubled quote inside a quoted field as one quote', () {
      expect(reader.read('"say ""hi""",b'), [
        ['say "hi"', 'b'],
      ]);
    });

    test('accepts Windows line endings', () {
      expect(reader.read('a,b\r\n1,2\r\n'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('keeps a bare line break in a field when records end in CRLF', () {
      expect(reader.read('a,one\ntwo,c\r\n1,2,3\r\n'), [
        ['a', 'one\ntwo', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('does not add a record for the final line break', () {
      expect(reader.read('a,b\n'), [
        ['a', 'b'],
      ]);
    });

    test('reads nothing from an empty text', () {
      expect(reader.read(''), isEmpty);
    });

    test('rejects a quoted field that is never closed', () {
      expect(() => reader.read('a,"b'), throwsFormatException);
    });
  });
}
