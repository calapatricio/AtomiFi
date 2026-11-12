import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

Revaluation _worth(String id, DateTime dateTime, Money value) => Revaluation(
      id: RevaluationId(id),
      accountId: broker.id,
      dateTime: dateTime,
      value: value,
    );

void main() {
  late AtomiFiDatabase database;
  late RevaluationRepository revaluations;

  setUp(() async {
    database = await openSeededDatabase();
    revaluations = DriftRevaluationRepository(database);
  });

  tearDown(() => database.close());

  group('DriftRevaluationRepository', () {
    test('starts without revaluations', () async {
      expect(await revaluations.all(), isEmpty);
    });

    test('restores a revaluation in the currency of its account', () async {
      await revaluations.save(
        _worth('october', DateTime(2026, 10, 20, 18), usd(215000)),
      );

      final restored = (await revaluations.all()).single;

      expect(restored.id, const RevaluationId('october'));
      expect(restored.accountId, broker.id);
      expect(restored.dateTime, DateTime(2026, 10, 20, 18));
      expect(restored.value, usd(215000));
    });

    test('returns the revaluations oldest first', () async {
      await revaluations.save(
        _worth('november', DateTime(2026, 11, 20), usd(230000)),
      );
      await revaluations.save(
        _worth('october', DateTime(2026, 10, 20), usd(215000)),
      );

      final restored = await revaluations.all();

      expect(restored.map((revaluation) => revaluation.id), const [
        RevaluationId('october'),
        RevaluationId('november'),
      ]);
    });

    test('removes a revaluation', () async {
      await revaluations.save(
        _worth('october', DateTime(2026, 10, 20), usd(215000)),
      );

      await revaluations.remove(const RevaluationId('october'));

      expect(await revaluations.all(), isEmpty);
    });
  });
}
