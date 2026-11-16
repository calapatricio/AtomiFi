import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../categories/category_choices.dart';

/// Whether the money of a transaction leaves the account or comes in.
enum Direction { expense, income }

/// What keeps an item from being saved.
enum ItemProblem {
  invalidAmount,
  missingCategory,
  incompleteShare,
  repeatedPerson,
  sharesExceedAmount,
  sharesDoNotAddUp,
}

/// The part of an item that somebody else bears, as it is being typed.
final class ShareDraft {
  ShareDraft._(this._changed, {this._person = '', this._amount = ''});

  final void Function() _changed;
  String _person;
  String _amount;

  String get person => _person;

  set person(String person) {
    _person = person;
    _changed();
  }

  /// The amount as typed, always without a sign.
  String get amount => _amount;

  set amount(String amount) {
    _amount = amount;
    _changed();
  }
}

/// An item of the transaction, as it is being typed.
final class ItemDraft {
  ItemDraft._(
    this._changed, {
    this.id,
    this.offsets,
    this._name = '',
    this._price = '',
    this._categoryId,
    this._includesMe = true,
    List<ShareDraft>? others,
  }) : _others = others ?? [];

  final void Function() _changed;

  /// The id of the item being edited, or nothing for a new one.
  final ItemId? id;

  /// What the item being edited offsets, which the form leaves as it is.
  final ItemId? offsets;

  String _name;
  String _price;
  CategoryId? _categoryId;
  bool _includesMe;
  BudgetId? _budgetId;
  GoalId? _goalId;
  List<ShareDraft> _others;

  String get name => _name;

  set name(String name) {
    _name = name;
    _changed();
  }

  /// The amount as typed. It has no sign unless the item goes against the
  /// rest of the transaction, such as a deposit returned in a purchase:
  /// then it starts with a minus.
  String get price => _price;

  set price(String price) {
    _price = price;
    _changed();
  }

  CategoryId? get categoryId => _categoryId;

  set categoryId(CategoryId? categoryId) {
    _categoryId = categoryId;
    _changed();
  }

  /// The budget for chosen items this item is put in, if any.
  BudgetId? get budgetId => _budgetId;

  set budgetId(BudgetId? budgetId) {
    _budgetId = budgetId;
    _changed();
  }

  /// The goal this item counts towards, if any.
  GoalId? get goalId => _goalId;

  set goalId(GoalId? goalId) {
    _goalId = goalId;
    _changed();
  }

  /// Whether I bear a part of an item that is shared. When I do not, the
  /// parts of the others must add up to the whole price.
  bool get includesMe => _includesMe;

  set includesMe(bool includesMe) {
    _includesMe = includesMe;
    _changed();
  }

  /// The parts borne by other people. What is left of the price is mine.
  List<ShareDraft> get others => List.unmodifiable(_others);
}

/// The state and the actions of the form that adds or edits a transaction.
final class TransactionFormViewModel extends ChangeNotifier
    implements CategoryChoices {
  TransactionFormViewModel({
    required this._transactions,
    required this._accounts,
    required this._categories,
    required this._budgets,
    required this._goals,
    required this._newId,
    required DateTime Function() now,
    Transaction? existing,
  }) : _existing = existing,
       _dateTime = existing?.dateTime ?? now(),
       _name = existing?.name ?? '',
       _note = existing?.note ?? '',
       _direction = existing != null && existing.total.isPositive
           ? Direction.income
           : Direction.expense {
    _items = existing == null
        ? [ItemDraft._(notifyListeners)]
        : [for (final item in existing.items) _draftOf(item)];
  }

  final TransactionRepository _transactions;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final BudgetAssignments _budgets;
  final GoalAssignments _goals;
  final String Function() _newId;
  final Transaction? _existing;

  String _name;
  String _note;
  DateTime _dateTime;
  Direction _direction;
  Account? _account;
  late List<ItemDraft> _items;
  List<Account> _accountsInUse = const [];
  List<Category> _allCategories = const [];
  List<Budget> _itemBudgets = const [];
  List<Goal> _itemGoals = const [];
  bool _knowsWhereItemsAre = false;

  bool get isEditing => _existing != null;

  String get name => _name;

  set name(String name) => _change(() => _name = name);

  String get note => _note;

  set note(String note) => _change(() => _note = note);

  DateTime get dateTime => _dateTime;

  set dateTime(DateTime dateTime) => _change(() => _dateTime = dateTime);

  Direction get direction => _direction;

  set direction(Direction direction) => _change(() => _direction = direction);

  Account? get account => _account;

  set account(Account? account) => _change(() => _account = account);

  /// The accounts to choose from: the ones in use, and the account of the
  /// transaction being edited even when it is archived.
  List<Account> get accounts => _accountsInUse;

  /// The currency the amounts are typed in: that of the chosen account.
  Currency? get currency => _account?.currency;

  @override
  List<Category> get mainCategories => [
    for (final category in _allCategories)
      if (category.parentId == null) category,
  ];

  @override
  List<Category> subcategoriesOf(CategoryId id) => [
    for (final category in _allCategories)
      if (category.parentId == id) category,
  ];

  /// The name of a category, after that of the category it belongs to.
  String labelOf(CategoryId id) {
    final category = _categoryById(id);
    final parentId = category?.parentId;
    final parent = parentId == null ? null : _categoryById(parentId);
    if (category == null) return '';
    return parent == null ? category.name : '${parent.name} › ${category.name}';
  }

  /// The category with this id, to show how it looks.
  Category? categoryOf(CategoryId id) => _categoryById(id);

  /// The budgets an item can be put in: those that take items one by one.
  List<Budget> get itemBudgets => _itemBudgets;

  /// The goals an item can count towards.
  List<Goal> get itemGoals => _itemGoals;

  List<ItemDraft> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final accounts = await _accounts.all();
    final accountId = _existing?.accountId;
    _accountsInUse = [
      for (final account in accounts)
        if (!account.isArchived || account.id == accountId) account,
    ];
    _account ??= accountId == null
        ? _accountsInUse.firstOrNull
        : _accountsInUse.where((account) => account.id == accountId).first;
    _allCategories = await _categories.all();
    _itemBudgets = await _budgets.budgetsForChosenItems();
    _itemGoals = await _goals.goals();
    await _findWhereItemsAre();
    notifyListeners();
  }

  /// Finds, the first time, the budget each item being edited is in and
  /// the goal it counts towards.
  Future<void> _findWhereItemsAre() async {
    if (_knowsWhereItemsAre) return;
    _knowsWhereItemsAre = true;
    final budgetByItem = await _budgets.budgetOfEach(_existingItemIds);
    final goalByItem = await _goals.goalOfEach(_existingItemIds);
    for (final item in _items) {
      item
        .._budgetId = budgetByItem[item.id]
        .._goalId = goalByItem[item.id];
    }
  }

  /// Adds an account and chooses it for this transaction.
  Future<void> addAccount({
    required String name,
    required String currencyCode,
  }) async {
    final account = Account(
      id: AccountId(_newId()),
      name: name.trim(),
      currency: Currency.iso(currencyCode.trim().toUpperCase()),
    );
    await _accounts.save(account);
    _account = account;
    await load();
  }

  @override
  Future<Category> addCategory({
    required String name,
    required CategorySide side,
    String? emoji,
    CategoryId? parentId,
  }) async {
    final parent = parentId == null ? null : _categoryById(parentId);
    final category = Category(
      id: CategoryId(_newId()),
      name: name.trim(),
      side: parent?.side ?? side,
      parentId: parentId,
      appearance: Appearance(emoji: emoji),
    );
    await _categories.save(category);
    await load();
    return category;
  }

  void addItem() => _change(() => _items.add(ItemDraft._(notifyListeners)));

  void removeItem(ItemDraft item) => _change(() => _items.remove(item));

  void addPerson(ItemDraft item) =>
      _change(() => item._others.add(ShareDraft._(notifyListeners)));

  void removePerson(ItemDraft item, ShareDraft share) =>
      _change(() => item._others.remove(share));

  /// Divides the price of [item] evenly among the others named in it, and
  /// me when it [ItemDraft.includesMe]. The cents that cannot be divided
  /// fall on me, or on the first person when I take no part.
  void splitEvenly(ItemDraft item) {
    final price = _priceOf(item);
    if (price == null || item._others.isEmpty) return;
    final mine = item.includesMe ? 1 : 0;
    final parts = price.allocate(List.filled(item._others.length + mine, 1));
    _change(() {
      item._others = [
        for (final (index, share) in item._others.indexed)
          ShareDraft._(
            notifyListeners,
            person: share.person,
            amount: parts[index + mine].toDecimalString(),
          ),
      ];
    });
  }

  /// What the others bear of [item] in all, when their amounts can be read.
  Money? othersTotalOf(ItemDraft item) {
    final currency = this.currency;
    final parts = [for (final share in item._others) _amountOf(share)];
    if (currency == null || parts.contains(null)) return null;
    return parts.nonNulls.fold<Money>(
      Money.zero(currency),
      (sum, part) => sum + part,
    );
  }

  /// What is left of the price of [item] once the others have borne their
  /// parts, when its amounts can be read and they do not exceed the price.
  Money? ownPartOf(ItemDraft item) {
    final price = _priceOf(item);
    final others = othersTotalOf(item);
    if (price == null || others == null) return null;
    final own = price - others;
    return own.isNegative ? null : own;
  }

  ItemProblem? problemOf(ItemDraft item) {
    final price = _priceOf(item);
    if (price == null || price.isZero) return ItemProblem.invalidAmount;
    if (item.categoryId == null) return ItemProblem.missingCategory;
    if (item._others.any(_isIncomplete)) return ItemProblem.incompleteShare;
    final people = {for (final share in item._others) _keyOf(share.person)};
    if (people.length != item._others.length) return ItemProblem.repeatedPerson;
    final own = ownPartOf(item);
    if (own == null) return ItemProblem.sharesExceedAmount;
    if (_isSharedWithoutMe(item) && !own.isZero) {
      return ItemProblem.sharesDoNotAddUp;
    }
    return null;
  }

  /// What leaves or enters the account, when every amount can be read.
  Money? get total {
    final currency = this.currency;
    final prices = [
      for (final item in _items)
        switch (_priceOf(item)) {
          final price? => _signed(price, item),
          null => null,
        },
    ];
    if (currency == null || prices.contains(null)) return null;
    return prices.nonNulls.fold<Money>(
      Money.zero(currency),
      (sum, price) => sum + price,
    );
  }

  bool get canSave =>
      _name.trim().isNotEmpty &&
      _account != null &&
      _items.isNotEmpty &&
      _items.every((item) => problemOf(item) == null);

  Future<void> save() async {
    if (!canSave) {
      throw StateError('The transaction is not complete yet.');
    }
    final id = _existing?.id ?? TransactionId(_newId());
    final items = [for (final draft in _items) _itemOf(draft)];
    await _transactions.save(
      Transaction(
        id: id,
        name: _name.trim(),
        note: _note.trim(),
        dateTime: _dateTime,
        accountId: _account!.id,
        items: items,
      ),
    );
    await _budgets.assign({
      for (final itemId in _existingItemIds) itemId: null,
      for (final (index, item) in items.indexed)
        item.id: _items[index].budgetId,
    });
    await _goals.assign({
      for (final itemId in _existingItemIds) itemId: null,
      for (final (index, item) in items.indexed) item.id: _items[index].goalId,
    });
  }

  /// Deletes the transaction being edited.
  Future<void> delete() async {
    final existing = _existing;
    if (existing == null) return;
    await _transactions.remove(existing.id);
    final inNothing = {for (final itemId in _existingItemIds) itemId: null};
    await _budgets.assign(inNothing);
    await _goals.assign(inNothing);
  }

  /// The ids of the items the transaction had before it was edited.
  List<ItemId> get _existingItemIds => [
    for (final item in _existing?.items ?? const <Item>[]) item.id,
  ];

  Item _itemOf(ItemDraft draft) {
    final own = ownPartOf(draft)!;
    final name = draft.name.trim();
    return Item(
      id: draft.id ?? ItemId(_newId()),
      name: name.isEmpty ? _name.trim() : name,
      categoryId: draft.categoryId!,
      shares: [
        if (!own.isZero) Share(const Me(), _signed(own, draft)),
        for (final share in draft._others)
          Share(Person(share.person.trim()), _signed(_amountOf(share)!, draft)),
      ],
      offsets: draft.offsets,
    );
  }

  ItemDraft _draftOf(Item item) => ItemDraft._(
    notifyListeners,
    id: item.id,
    offsets: item.offsets,
    name: item.name,
    price: _typedPriceOf(item),
    categoryId: item.categoryId,
    includesMe: !item.ownAmount.isZero,
    others: [
      for (final Share(:party, :amount) in item.shares)
        if (party is Person)
          ShareDraft._(
            notifyListeners,
            person: party.name,
            amount: amount.abs().toDecimalString(),
          ),
    ],
  );

  /// The price of [item] without its sign.
  Money? _priceOf(ItemDraft item) =>
      _read(_goesAgainst(item) ? item.price.trim().substring(1) : item.price);

  /// Whether [item] moves money the other way than the transaction does.
  static bool _goesAgainst(ItemDraft item) =>
      item.price.trim().startsWith(_minus);

  /// The price of [item] as it is typed: with a minus when it goes against
  /// the direction of the transaction.
  String _typedPriceOf(Item item) {
    final amount = item.price.abs().toDecimalString();
    final goesAgainst =
        !item.price.isZero &&
        item.price.isPositive != (_direction == Direction.income);
    return goesAgainst ? '$_minus$amount' : amount;
  }

  static const _minus = '-';

  Money? _amountOf(ShareDraft share) => _read(share.amount);

  Money? _read(String typed) {
    final currency = this.currency;
    return currency == null ? null : Money.tryParse(typed, currency);
  }

  /// [amount], which has no sign, as money that leaves or enters the
  /// account because of [item].
  Money _signed(Money amount, ItemDraft item) {
    final leaves = (_direction == Direction.expense) != _goesAgainst(item);
    return leaves ? -amount : amount;
  }

  bool _isIncomplete(ShareDraft share) {
    final amount = _amountOf(share);
    return share.person.trim().isEmpty || amount == null || amount.isZero;
  }

  void _change(void Function() change) {
    change();
    notifyListeners();
  }

  Category? _categoryById(CategoryId id) =>
      _allCategories.where((category) => category.id == id).firstOrNull;

  static bool _isSharedWithoutMe(ItemDraft item) =>
      !item.includesMe && item._others.isNotEmpty;

  static String _keyOf(String person) => person.trim().toLowerCase();
}
