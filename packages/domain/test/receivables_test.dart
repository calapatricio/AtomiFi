import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/builders.dart';

void main() {
  group('Receivables', () {
    final tacos = on(DateTime(2026, 11, 7), [
      shared({me: -1250, moy: -1400}, id: 'tacos'),
    ]);
    final watch = on(DateTime(2026, 11, 8), [
      shared({moy: -6296}, id: 'watch'),
    ]);

    test('a person owes their whole share until they pay', () {
      final receivables = Receivables([tacos]);

      expect(receivables.outstandingFor(const ItemId('tacos'), moy), eur(1400));
    });

    test('a repayment that offsets the item settles it', () {
      final bizum = on(DateTime(2026, 11, 8), [
        shared({moy: 1400}, offsets: 'tacos'),
      ]);

      final receivables = Receivables([tacos, bizum]);

      expect(receivables.outstandingFor(const ItemId('tacos'), moy), eur(0));
    });

    test('one payment can settle items of several transactions', () {
      final bizum = on(DateTime(2026, 11, 9), [
        shared({moy: 1400}, offsets: 'tacos'),
        shared({moy: 6296}, offsets: 'watch'),
      ]);

      final receivables = Receivables([tacos, watch, bizum]);

      expect(receivables.open, isEmpty);
    });

    test('lists what is still owed after a short payment', () {
      final bizum = on(DateTime(2026, 11, 8), [
        shared({moy: 6295}, offsets: 'watch'),
      ]);

      final receivables = Receivables([watch, bizum]);

      expect(
        receivables.open,
        [Receivable(const ItemId('watch'), moy, eur(1))],
      );
    });

    test('rejects an item that is not in the ledger', () {
      expect(
        () => Receivables([tacos]).outstandingFor(const ItemId('gone'), moy),
        throwsArgumentError,
      );
    });
  });

  group('Item.writeOff', () {
    test('moves what a person will not pay to my share', () {
      final watch = shared({moy: -6296}).writeOff(moy, eur(1));

      expect(watch.amountFor(moy), eur(-6295));
      expect(watch.ownAmount, eur(-1));
      expect(watch.price, eur(-6296));
    });

    test('removes a person whose whole share is written off', () {
      final beers = shared({me: -100, moy: -200}).writeOff(moy, eur(200));

      expect(beers.shares, [Share(me, eur(-300))]);
    });

    test('rejects an amount that is not positive or exceeds the share', () {
      final beers = shared({me: -100, moy: -200});

      expect(() => beers.writeOff(moy, eur(0)), throwsArgumentError);
      expect(() => beers.writeOff(moy, eur(201)), throwsArgumentError);
    });
  });
}
