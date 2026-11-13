import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Appearance', () {
    test('is the same as another with the same color, icon and emoji', () {
      expect(
        const Appearance(color: 0xFF607D8B, iconName: 'tram', emoji: '🚋'),
        const Appearance(color: 0xFF607D8B, iconName: 'tram', emoji: '🚋'),
      );
      expect(
        const Appearance(color: 0xFF607D8B),
        isNot(const Appearance(color: 0xFFFFEB3B)),
      );
    });

    test('accounts and categories have none unless they are given one', () {
      const account = Account(
        id: AccountId('bank'),
        name: 'Bank',
        currency: Currency.eur,
      );
      const category = Category(
        id: CategoryId('food'),
        name: 'Food',
        side: CategorySide.expense,
      );

      expect(account.appearance, Appearance.none);
      expect(category.appearance, Appearance.none);
    });
  });
}
