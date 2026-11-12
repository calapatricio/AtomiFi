import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('Item', () {
    test('has the sum of its shares as price', () {
      final tacos = shared({me: -1250, moy: -1400});

      expect(tacos.price, eur(-2650));
    });

    test('separates my part from the part borne by others', () {
      final tacos = shared({me: -1250, moy: -1400});

      expect(tacos.ownAmount, eur(-1250));
      expect(tacos.othersAmount, eur(-1400));
      expect(tacos.amountFor(moy), eur(-1400));
    });

    test('has no own amount when it is entirely for others', () {
      final watch = shared({moy: -6296});

      expect(watch.ownAmount, eur(0));
      expect(watch.othersAmount, eur(-6296));
    });

    test('rejects an item without shares', () {
      expect(() => shared({}), throwsArgumentError);
    });

    test('rejects a share of zero', () {
      expect(() => shared({me: -100, moy: 0}), throwsArgumentError);
    });

    test('rejects shares with different signs', () {
      expect(() => shared({me: -100, moy: 100}), throwsArgumentError);
    });

    test('rejects two shares for the same party', () {
      expect(
        () => Item(
          id: const ItemId('rum'),
          name: 'Rum',
          categoryId: const CategoryId('alcohol'),
          shares: [Share(moy, eur(-100)), Share(moy, eur(-200))],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Item.split', () {
    Item beers(List<Party> among) => Item.split(
          id: const ItemId('beers'),
          name: 'Beers',
          categoryId: const CategoryId('alcohol'),
          price: eur(-625),
          among: among,
        );

    test('divides the price evenly and keeps every cent', () {
      final item = beers(const [moy, Person('Mario'), Person('Pablo'), me]);

      expect(item.price, eur(-625));
      expect(item.amountFor(moy), eur(-156));
    });

    test('makes me bear the cents that cannot be divided', () {
      final item = beers(const [moy, Person('Mario'), Person('Pablo'), me]);

      expect(item.ownAmount, eur(-157));
    });
  });
}
