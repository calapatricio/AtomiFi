import 'package:atomifi_data/atomifi_data.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

/// Follows an item from the form to the figure a budget shows, through the
/// real database: the transaction is stored, its item is put in a budget
/// for chosen items, and the budget is read back and worked out.
void main() {
  late AtomiFiDatabase database;
  late BudgetRepository budgets;
  late TransactionRepository transactions;

  final hotel = Transaction(
    id: const TransactionId('booking'),
    name: 'Booking',
    dateTime: DateTime(2026, 11, 10, 12),
    accountId: bank.id,
    items: [
      Item.mine(
        id: const ItemId('hotel'),
        name: 'Hotel',
        categoryId: food.id,
        price: eur(-20000),
      ),
    ],
  );

  Future<BudgetProgress> progressAt(DateTime moment) async {
    final calculator = BudgetProgressCalculator(
      categories: await DriftCategoryRepository(database).all(),
    );
    return calculator.progressOf(
      (await budgets.all()).single,
      await transactions.all(),
      at: moment,
    );
  }

  setUp(() async {
    database = await openSeededDatabase();
    budgets = DriftBudgetRepository(database);
    transactions = DriftTransactionRepository(database);
    await budgets.save(
      Budget(
        id: const BudgetId('trip'),
        name: 'Trip',
        limit: eur(50000),
        period: RecurringPeriod(Recurrence.calendarMonths),
        scope: const ChosenItems({}),
      ),
    );
    await transactions.save(hotel);
  });

  tearDown(() => database.close());

  test('an item put in a budget is taken off what is left of it', () async {
    await BudgetAssignments(budgets).assign({
      const ItemId('hotel'): const BudgetId('trip'),
    });

    final progress = await progressAt(DateTime(2026, 11, 16));

    expect(progress.spent, eur(20000));
    expect(progress.remaining, eur(30000));
  });

  test('it still counts after its transaction is saved again', () async {
    await BudgetAssignments(budgets).assign({
      const ItemId('hotel'): const BudgetId('trip'),
    });
    await transactions.save(hotel);

    expect((await progressAt(DateTime(2026, 11, 16))).spent, eur(20000));
  });

  test('it does not count in a period it does not fall in', () async {
    await BudgetAssignments(budgets).assign({
      const ItemId('hotel'): const BudgetId('trip'),
    });

    expect((await progressAt(DateTime(2026, 12, 2))).spent, eur(0));
  });
}
