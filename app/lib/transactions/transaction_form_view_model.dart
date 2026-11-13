import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Whether the money of a transaction leaves the account or comes in.
enum Direction { expense, income }

/// What keeps an item from being saved.
enum ItemProblem {
  invalidAmount,
  missingCategory,
  incompleteShare,
  repeatedPerson,
  sharesExceedAmount,
}

/// A category to choose from, named with the category it belongs to.
typedef CategoryOption = ({CategoryId id, String label});

/// The part of an item that somebody else bears, as it is being typed.
final class ShareDraft {
  ShareDraft._(this._changed, {String person = '', String amount = ''})
    : _person = person,
      _amount = amount;

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
    String name = '',
    String price = '',
    CategoryId? categoryId,
    List<ShareDraft>? others,
  }) : _name = name,
       _price = price,
       _categoryId = categoryId,
       _others = others ?? [];

  final void Function() _changed;

  /// The id of the item being edited, or nothing for a new one.
  final ItemId? id;

  /// What the item being edited offsets, which the form leaves as it is.
  final ItemId? offsets;

  String _name;
  String _price;
  CategoryId? _categoryId;
  List<ShareDraft> _others;

  String get name => _name;

  set name(String name) {
    _name = name;
    _changed();
  }

  /// The amount as typed, always without a sign.
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

  /// The parts borne by other people. What is left of the price is mine.
  List<ShareDraft> get others => List.unmodifiable(_others);
}

/// The state and the actions of the form that adds or edits a transaction.
final class TransactionFormViewModel extends ChangeNotifier {
  TransactionFormViewModel({
    required this._transactions,
    required this._accounts,
    required this._categories,
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
  final String Function() _newId;
  final Transaction? _existing;

  String _name;
  String _note;
  DateTime _dateTime;
  Direction _direction;
  Account? _account;
  late List<ItemDraft> _items;
  List<Account> _accountsInUse = const [];
  List<CategoryOption> _categoryOptions = const [];

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

  /// The categories to choose from, ordered by label.
  List<CategoryOption> get categoryOptions => _categoryOptions;

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
    _categoryOptions = _optionsOf(await _categories.all());
    notifyListeners();
  }

  void addItem() => _change(() => _items.add(ItemDraft._(notifyListeners)));

  void removeItem(ItemDraft item) => _change(() => _items.remove(item));

  void addPerson(ItemDraft item) =>
      _change(() => item._others.add(ShareDraft._(notifyListeners)));

  void removePerson(ItemDraft item, ShareDraft share) =>
      _change(() => item._others.remove(share));

  /// Divides the price of [item] evenly between me and the others named in
  /// it. The cents that cannot be divided fall on me.
  void splitEvenly(ItemDraft item) {
    final price = _priceOf(item);
    if (price == null || item._others.isEmpty) return;
    final parts = price.allocate(List.filled(item._others.length + 1, 1));
    _change(() {
      item._others = [
        for (final (index, share) in item._others.indexed)
          ShareDraft._(
            notifyListeners,
            person: share.person,
            amount: parts[index + 1].toDecimalString(),
          ),
      ];
    });
  }

  /// The part of [item] that is mine, when its amounts can be read.
  Money? ownPartOf(ItemDraft item) {
    final price = _priceOf(item);
    final others = [for (final share in item._others) _amountOf(share)];
    if (price == null || others.contains(null)) return null;
    final own = others.nonNulls.fold(price, (left, part) => left - part);
    return own.isNegative ? null : own;
  }

  ItemProblem? problemOf(ItemDraft item) {
    final price = _priceOf(item);
    if (price == null || price.isZero) return ItemProblem.invalidAmount;
    if (item.categoryId == null) return ItemProblem.missingCategory;
    if (item._others.any(_isIncomplete)) return ItemProblem.incompleteShare;
    final people = {for (final share in item._others) _keyOf(share.person)};
    if (people.length != item._others.length) return ItemProblem.repeatedPerson;
    if (ownPartOf(item) == null) return ItemProblem.sharesExceedAmount;
    return null;
  }

  /// What leaves or enters the account, when every amount can be read.
  Money? get total {
    final currency = _account?.currency;
    final prices = [for (final item in _items) _priceOf(item)];
    if (currency == null || prices.contains(null)) return null;
    return prices.nonNulls.fold<Money>(
      Money.zero(currency),
      (sum, price) => sum + _signed(price),
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
    await _transactions.save(
      Transaction(
        id: _existing?.id ?? TransactionId(_newId()),
        name: _name.trim(),
        note: _note.trim(),
        dateTime: _dateTime,
        accountId: _account!.id,
        items: [for (final item in _items) _itemOf(item)],
      ),
    );
  }

  /// Deletes the transaction being edited.
  Future<void> delete() async {
    final existing = _existing;
    if (existing != null) await _transactions.remove(existing.id);
  }

  Item _itemOf(ItemDraft draft) {
    final own = ownPartOf(draft)!;
    final name = draft.name.trim();
    return Item(
      id: draft.id ?? ItemId(_newId()),
      name: name.isEmpty ? _name.trim() : name,
      categoryId: draft.categoryId!,
      shares: [
        if (!own.isZero) Share(const Me(), _signed(own)),
        for (final share in draft._others)
          Share(Person(share.person.trim()), _signed(_amountOf(share)!)),
      ],
      offsets: draft.offsets,
    );
  }

  ItemDraft _draftOf(Item item) => ItemDraft._(
    notifyListeners,
    id: item.id,
    offsets: item.offsets,
    name: item.name,
    price: item.price.abs().toDecimalString(),
    categoryId: item.categoryId,
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

  Money? _priceOf(ItemDraft item) => _read(item.price);

  Money? _amountOf(ShareDraft share) => _read(share.amount);

  Money? _read(String typed) {
    final currency = _account?.currency;
    return currency == null ? null : Money.tryParse(typed, currency);
  }

  Money _signed(Money amount) =>
      _direction == Direction.expense ? -amount : amount;

  bool _isIncomplete(ShareDraft share) {
    final amount = _amountOf(share);
    return share.person.trim().isEmpty || amount == null || amount.isZero;
  }

  void _change(void Function() change) {
    change();
    notifyListeners();
  }

  static String _keyOf(String person) => person.trim().toLowerCase();

  static List<CategoryOption> _optionsOf(List<Category> categories) {
    final nameById = {
      for (final category in categories) category.id: category.name,
    };
    String labelOf(Category category) {
      final parent = nameById[category.parentId];
      return parent == null ? category.name : '$parent › ${category.name}';
    }

    return [
      for (final category in categories)
        (id: category.id, label: labelOf(category)),
    ]..sort((a, b) => a.label.compareTo(b.label));
  }
}
