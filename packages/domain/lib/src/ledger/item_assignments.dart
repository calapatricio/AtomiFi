import '../ids.dart';

/// The things that hold items put in them one by one, such as budgets for
/// chosen items or goals, and how to read and change what each holds.
abstract interface class ItemHolders<Holder, HolderId> {
  /// The holders that take items, ordered by name.
  Future<List<Holder>> all();

  HolderId idOf(Holder holder);

  Set<ItemId> itemsOf(Holder holder);

  /// Stores [holder] holding [itemIds] and no other items.
  Future<void> saveWithItems(Holder holder, Set<ItemId> itemIds);
}

/// Puts items in holders and takes them out, keeping each item in one
/// holder at most.
final class ItemAssignments<Holder, HolderId> {
  ItemAssignments(this._holders);

  final ItemHolders<Holder, HolderId> _holders;

  Future<List<Holder>> holders() => _holders.all();

  /// The holder that each of [itemIds] is in. Items in none are left out.
  Future<Map<ItemId, HolderId>> holderOfEach(Iterable<ItemId> itemIds) async {
    final holders = await _holders.all();
    return {
      for (final holder in holders)
        for (final itemId in itemIds)
          if (_holders.itemsOf(holder).contains(itemId))
            itemId: _holders.idOf(holder),
    };
  }

  /// Leaves each item in the holder given for it and in no other. An item
  /// given no holder is taken out of the one it was in.
  Future<void> assign(Map<ItemId, HolderId?> holderByItem) async {
    for (final holder in await _holders.all()) {
      final before = _holders.itemsOf(holder);
      final after = {
        for (final itemId in before)
          if (!holderByItem.containsKey(itemId)) itemId,
        for (final MapEntry(key: itemId, value: holderId)
            in holderByItem.entries)
          if (holderId == _holders.idOf(holder)) itemId,
      };
      if (!_areSame(before, after)) {
        await _holders.saveWithItems(holder, after);
      }
    }
  }

  static bool _areSame(Set<ItemId> one, Set<ItemId> other) =>
      one.length == other.length && one.containsAll(other);
}
