import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('Account', () {
    test('is not archived unless told otherwise', () {
      expect(bank.isArchived, isFalse);
    });

    test('can be archived and restored, keeping everything else', () {
      final archived = bank.archived();
      final restored = archived.restored();

      expect(archived.isArchived, isTrue);
      expect(archived.id, bank.id);
      expect(archived.name, bank.name);
      expect(archived.currency, bank.currency);
      expect(archived.appearance, bank.appearance);
      expect(restored.isArchived, isFalse);
    });
  });
}
