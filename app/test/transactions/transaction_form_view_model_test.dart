import 'package:atomifi/transactions/transaction_form_view_model.dart';
import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:atomifi_domain/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

const moy = Person('Moy');

void main() {
  late InMemoryStore store;
  late TransactionFormViewModel form;

  Future<Transaction> saved() async => (await store.transactions.all()).single;

  setUp(() async {
    store = await seededStore();
    form = transactionFormOn(store);
    await form.load();
  });

  group('A new transaction', () {
    test(
      'starts as an expense of now, in the first account, with one item',
      () {
        expect(form.isEditing, isFalse);
        expect(form.direction, Direction.expense);
        expect(form.dateTime, now);
        expect(form.account!.id, bank.id);
        expect(form.items, hasLength(1));
      },
    );

    test('cannot be saved until it is complete', () {
      expect(form.canSave, isFalse);

      form.name = 'Burger';
      expect(form.canSave, isFalse);

      form.items.single
        ..categoryId = food.id
        ..price = '5';
      expect(form.canSave, isTrue);
    });

    test('is saved as money that left, entirely mine', () async {
      form.name = ' Burger ';
      form.note = 'With fries';
      form.items.single
        ..categoryId = food.id
        ..price = '5';

      await form.save();
      final transaction = await saved();

      expect(transaction.id, const TransactionId('new-0'));
      expect(transaction.name, 'Burger');
      expect(transaction.note, 'With fries');
      expect(transaction.dateTime, now);
      expect(transaction.accountId, bank.id);
      expect(transaction.total, eur(-500));
      expect(transaction.items.single.name, 'Burger');
      expect(transaction.items.single.ownAmount, eur(-500));
    });

    test('is saved as money that came in when it is income', () async {
      form
        ..name = 'Payroll'
        ..direction = Direction.income;
      form.items.single
        ..categoryId = salary.id
        ..price = '1500,50';

      await form.save();

      expect((await saved()).total, eur(150050));
    });

    test('keeps the account and the moment that were chosen', () async {
      form
        ..name = 'Burger'
        ..account = savings
        ..dateTime = DateTime(2026, 11, 7, 22);
      form.items.single
        ..categoryId = food.id
        ..price = '5';

      await form.save();
      final transaction = await saved();

      expect(transaction.accountId, savings.id);
      expect(transaction.dateTime, DateTime(2026, 11, 7, 22));
    });

    test('offers the accounts in use and not the archived ones', () async {
      await store.accounts.save(savings.archived());
      await form.load();

      expect(form.accounts.map((account) => account.id), [bank.id]);
    });

    test('counts in the currency of its account', () {
      expect(form.currency, Currency.eur);
    });

    test('can add an account on the spot and takes it', () async {
      await form.addAccount(name: ' Broker ', currencyCode: 'usd');

      expect(form.account!.name, 'Broker');
      expect(form.currency, Currency.usd);
      expect(form.accounts.map((account) => account.name), [
        'Bank',
        'Broker',
        'Savings',
      ]);
    });

    test('can add a category on the spot', () async {
      final sport = await form.addCategory(
        name: ' Sport ',
        side: CategorySide.expense,
        emoji: '⚽',
      );

      expect(sport.name, 'Sport');
      expect(sport.appearance.emoji, '⚽');
      expect(
        form.mainCategories.map((category) => category.id),
        contains(sport.id),
      );
      expect(await store.categories.all(), hasLength(4));
    });

    test('gives a new subcategory the side of its category', () async {
      final bonus = await form.addCategory(
        name: 'Bonus',
        side: CategorySide.expense,
        parentId: salary.id,
      );

      expect(bonus.side, CategorySide.income);
      expect(form.subcategoriesOf(salary.id).single.id, bonus.id);
    });

    test('offers the categories, each with its subcategories', () async {
      await store.categories.save(
        const Category(
          id: CategoryId('leisure'),
          name: 'Leisure',
          side: CategorySide.expense,
        ),
      );
      await store.categories.save(
        const Category(
          id: CategoryId('cinema'),
          name: 'Cinema',
          side: CategorySide.expense,
          parentId: CategoryId('leisure'),
        ),
      );
      await form.load();

      expect(form.mainCategories.map((category) => category.name), [
        'Alcohol',
        'Food',
        'Leisure',
        'Salary',
      ]);
      expect(
        form
            .subcategoriesOf(const CategoryId('leisure'))
            .map((category) => category.name),
        ['Cinema'],
      );
      expect(form.subcategoriesOf(food.id), isEmpty);
      expect(form.labelOf(const CategoryId('cinema')), 'Leisure › Cinema');
      expect(form.labelOf(food.id), 'Food');
    });
  });

  group('The items of a transaction', () {
    setUp(() => form.name = 'Supermarket');

    test('each have their own category and amount', () async {
      form.items.single
        ..name = 'Rum'
        ..categoryId = alcohol.id
        ..price = '12';
      form.addItem();
      form.items.last
        ..name = 'Bananas'
        ..categoryId = food.id
        ..price = '1.80';

      expect(form.total, eur(-1380));
      await form.save();
      final transaction = await saved();

      expect(transaction.items.map((item) => item.name), ['Rum', 'Bananas']);
      expect(transaction.items.map((item) => item.categoryId), [
        alcohol.id,
        food.id,
      ]);
      expect(transaction.total, eur(-1380));
    });

    test('can be removed', () {
      form.addItem();

      form.removeItem(form.items.first);

      expect(form.items, hasLength(1));
    });

    test('have no total while an amount is missing', () {
      form.items.single.price = 'abc';

      expect(form.total, isNull);
    });

    test('say what is wrong with them', () {
      final item = form.items.single;
      expect(form.problemOf(item), ItemProblem.invalidAmount);

      item.price = '0';
      expect(form.problemOf(item), ItemProblem.invalidAmount);

      item.price = '5';
      expect(form.problemOf(item), ItemProblem.missingCategory);

      item.categoryId = food.id;
      expect(form.problemOf(item), isNull);
    });
  });

  group('Splitting an item with other people', () {
    late ItemDraft item;

    setUp(() {
      form.name = 'Tacos';
      item = form.items.single
        ..categoryId = food.id
        ..price = '26.50';
    });

    test('leaves me the part the others do not bear', () async {
      form.addPerson(item);
      item.others.single
        ..person = 'Moy'
        ..amount = '14';

      expect(form.ownPartOf(item), eur(1250));
      await form.save();
      final shares = (await saved()).items.single.shares;

      expect(shares, [Share(const Me(), eur(-1250)), Share(moy, eur(-1400))]);
    });

    test('leaves me out when the others bear it all', () async {
      form.addPerson(item);
      item.others.single
        ..person = 'Moy'
        ..amount = '26.50';

      await form.save();

      expect((await saved()).items.single.shares, [Share(moy, eur(-2650))]);
    });

    test('can divide the amount evenly, the odd cents falling on me', () {
      item.price = '6.25';
      for (final name in ['Moy', 'Mario', 'Pablo']) {
        form.addPerson(item);
        item.others.last.person = name;
      }

      form.splitEvenly(item);

      expect(item.others.map((share) => share.amount), [
        '1.56',
        '1.56',
        '1.56',
      ]);
      expect(form.ownPartOf(item), eur(157));
    });

    test('counts me in unless told otherwise', () {
      expect(item.includesMe, isTrue);
    });

    test('can divide the amount among the others only', () {
      for (final name in ['Moy', 'Mario']) {
        form.addPerson(item);
        item.others.last.person = name;
      }
      item
        ..price = '6.25'
        ..includesMe = false;

      form.splitEvenly(item);

      expect(item.others.map((share) => share.amount), ['3.13', '3.12']);
      expect(form.ownPartOf(item), eur(0));
    });

    test('needs the parts to add up when I take no part', () async {
      form.addPerson(item);
      item.others.single
        ..person = 'Moy'
        ..amount = '14';
      item.includesMe = false;

      expect(form.othersTotalOf(item), eur(1400));
      expect(form.problemOf(item), ItemProblem.sharesDoNotAddUp);
      expect(form.canSave, isFalse);

      item.others.single.amount = '26.50';
      expect(form.problemOf(item), isNull);
      await form.save();

      expect((await saved()).items.single.shares, [Share(moy, eur(-2650))]);
    });

    test('is all mine again once nobody else is left', () {
      form.addPerson(item);
      item.includesMe = false;

      form.removePerson(item, item.others.single);

      expect(form.problemOf(item), isNull);
      expect(form.ownPartOf(item), eur(2650));
    });

    test('lets a person be removed', () {
      form.addPerson(item);

      form.removePerson(item, item.others.single);

      expect(item.others, isEmpty);
    });

    test('says what is wrong with the parts', () {
      form.addPerson(item);
      final share = item.others.single;
      expect(form.problemOf(item), ItemProblem.incompleteShare);

      share
        ..person = 'Moy'
        ..amount = '30';
      expect(form.problemOf(item), ItemProblem.sharesExceedAmount);

      share.amount = '10';
      form.addPerson(item);
      item.others.last
        ..person = ' moy '
        ..amount = '5';
      expect(form.problemOf(item), ItemProblem.repeatedPerson);
      expect(form.canSave, isFalse);
    });
  });

  group('Editing a transaction', () {
    final tacos = Transaction(
      id: const TransactionId('tacos'),
      name: 'Tacos',
      note: 'Friday',
      dateTime: DateTime(2026, 11, 7, 22, 1),
      accountId: savings.id,
      items: [
        Item(
          id: const ItemId('tacos-food'),
          name: 'Dinner',
          categoryId: food.id,
          shares: [Share(const Me(), eur(-1250)), Share(moy, eur(-1400))],
          offsets: const ItemId('earlier'),
        ),
      ],
    );

    setUp(() async {
      await store.transactions.save(tacos);
      form = transactionFormOn(store, existing: tacos);
      await form.load();
    });

    test('starts from what it holds', () {
      final item = form.items.single;

      expect(form.isEditing, isTrue);
      expect(form.name, 'Tacos');
      expect(form.note, 'Friday');
      expect(form.direction, Direction.expense);
      expect(form.dateTime, DateTime(2026, 11, 7, 22, 1));
      expect(form.account!.id, savings.id);
      expect(item.name, 'Dinner');
      expect(item.categoryId, food.id);
      expect(item.price, '26.50');
      expect(item.others.single.person, 'Moy');
      expect(item.others.single.amount, '14.00');
      expect(form.canSave, isTrue);
    });

    test('knows whether I bear a part of each item', () async {
      final watch = Transaction(
        id: const TransactionId('watch'),
        name: 'Watch',
        dateTime: DateTime(2026, 11, 8),
        accountId: bank.id,
        items: [
          Item(
            id: const ItemId('watch-item'),
            name: 'Watch',
            categoryId: food.id,
            shares: [Share(moy, eur(-6296))],
          ),
        ],
      );
      final watchForm = transactionFormOn(store, existing: watch);
      await watchForm.load();

      expect(form.items.single.includesMe, isTrue);
      expect(watchForm.items.single.includesMe, isFalse);
    });

    test('replaces it, keeping its ids and what its items offset', () async {
      form.name = 'Tacos al pastor';

      await form.save();
      final transaction = await saved();

      expect(transaction.id, tacos.id);
      expect(transaction.name, 'Tacos al pastor');
      expect(transaction.items.single.id, const ItemId('tacos-food'));
      expect(transaction.items.single.offsets, const ItemId('earlier'));
      expect(transaction.items.single.shares, tacos.items.single.shares);
    });

    test('can delete it', () async {
      await form.delete();

      expect(await store.transactions.all(), isEmpty);
    });
  });

  group('Putting items in a budget', () {
    final shopping = spending('shopping');
    const shoppingItem = ItemId('shopping-food');

    setUp(() async {
      await store.budgets.save(tripBudget());
      await store.budgets.save(monthlyBudget());
      await form.load();
    });

    test('offers the budgets that take items one by one', () {
      expect(form.itemBudgets.map((budget) => budget.name), ['Trip']);
    });

    test('puts a new item in the budget chosen for it', () async {
      form.name = 'Hotel';
      form.items.single
        ..categoryId = food.id
        ..price = '200'
        ..budgetId = const BudgetId('trip');

      await form.save();
      final item = (await saved()).items.single;

      expect(await itemsInBudget(store, 'trip'), {item.id});
    });

    test('shows the budget an item is already in', () async {
      await store.transactions.save(shopping);
      await store.budgets.save(tripBudget(itemIds: {shoppingItem}));
      form = transactionFormOn(store, existing: shopping);

      await form.load();

      expect(form.items.single.budgetId, const BudgetId('trip'));
    });

    test('takes an item out of its budget when none is chosen', () async {
      await store.transactions.save(shopping);
      await store.budgets.save(tripBudget(itemIds: {shoppingItem}));
      form = transactionFormOn(store, existing: shopping);
      await form.load();

      form.items.single.budgetId = null;
      await form.save();

      expect(await itemsInBudget(store, 'trip'), isEmpty);
    });

    test('takes an item that is removed out of its budget', () async {
      await store.transactions.save(shopping);
      await store.budgets.save(tripBudget(itemIds: {shoppingItem}));
      form = transactionFormOn(store, existing: shopping);
      await form.load();

      form.addItem();
      form.items.last
        ..categoryId = alcohol.id
        ..price = '5';
      form.removeItem(form.items.first);
      await form.save();

      expect(await itemsInBudget(store, 'trip'), isEmpty);
    });

    test(
      'takes the items of a deleted transaction out of their budget',
      () async {
        await store.transactions.save(shopping);
        await store.budgets.save(tripBudget(itemIds: {shoppingItem}));
        form = transactionFormOn(store, existing: shopping);
        await form.load();

        await form.delete();

        expect(await itemsInBudget(store, 'trip'), isEmpty);
      },
    );
  });
}
