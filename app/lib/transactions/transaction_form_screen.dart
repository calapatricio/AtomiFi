import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../accounts/add_account_dialog.dart';
import '../categories/category_picker.dart';
import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/appearance_avatar.dart';
import '../widgets/choice_carousel.dart';
import 'transaction_form_view_model.dart';

/// The form that adds a transaction or edits one: what it is, where and
/// when, and its items with who bears each.
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, required this.viewModel});

  final TransactionFormViewModel viewModel;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  TransactionFormViewModel get _form => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _form.load();
  }

  Future<void> _save() async {
    await _form.save();
    if (mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _delete() async {
    final texts = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(texts.deleteTransactionTitle),
        content: Text(texts.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(texts.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(texts.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _form.delete();
    if (mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _addAccount() async {
    final account = await showAddAccountDialog(context);
    if (account == null) return;
    await _form.addAccount(
      name: account.name,
      currencyCode: account.currencyCode,
    );
  }

  Future<void> _pickDate() async {
    final current = _form.dateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    _form.dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      current.hour,
      current.minute,
    );
  }

  Future<void> _pickTime() async {
    final current = _form.dateTime;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    _form.dateTime = DateTime(
      current.year,
      current.month,
      current.day,
      time.hour,
      time.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            _form.isEditing ? texts.editTransaction : texts.newTransaction,
          ),
          actions: [
            if (_form.isEditing)
              IconButton(
                onPressed: _delete,
                tooltip: texts.delete,
                icon: const Icon(Icons.delete_outline),
              ),
            TextButton(
              onPressed: _form.canSave ? _save : null,
              child: Text(texts.save),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                _directionPicker(texts),
                _total(context),
                TextFormField(
                  initialValue: _form.name,
                  decoration: InputDecoration(labelText: texts.transactionName),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (name) => _form.name = name,
                ),
                _accountPicker(texts),
                _momentPickers(context),
                TextFormField(
                  initialValue: _form.note,
                  decoration: InputDecoration(labelText: texts.note),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  onChanged: (note) => _form.note = note,
                ),
                Text(
                  texts.items,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final item in _form.items)
                  _ItemCard(key: ObjectKey(item), form: _form, item: item),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _form.addItem,
                    icon: const Icon(Icons.add),
                    label: Text(texts.addItem),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Chooses between money that leaves, in red, and money that comes in,
  /// in green. The choice shows in the color alone.
  Widget _directionPicker(AppLocalizations texts) {
    final isExpense = _form.direction == Direction.expense;
    return SegmentedButton<Direction>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: isExpense
            ? Colors.red.shade100
            : Colors.green.shade100,
        selectedForegroundColor: isExpense
            ? Colors.red.shade900
            : Colors.green.shade900,
      ),
      segments: [
        ButtonSegment(
          value: Direction.expense,
          icon: const Icon(Icons.arrow_downward),
          label: Text(texts.expense),
        ),
        ButtonSegment(
          value: Direction.income,
          icon: const Icon(Icons.arrow_upward),
          label: Text(texts.income),
        ),
      ],
      selected: {_form.direction},
      onSelectionChanged: (selected) => _form.direction = selected.single,
    );
  }

  /// The amount of the whole transaction, large, or a dash while one of
  /// its amounts cannot be read.
  Widget _total(BuildContext context) {
    final total = _form.total;
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return Text(
      total == null ? '—' : money.format(total),
      style: Theme.of(context).textTheme.displaySmall,
      textAlign: TextAlign.center,
    );
  }

  Widget _accountPicker(AppLocalizations texts) => ChoiceCarousel<Account>(
    choices: _form.accounts,
    selected: _form.accounts
        .where((account) => account.id == _form.account?.id)
        .firstOrNull,
    labelOf: (account) => account.name,
    colorOf: (account) {
      final color = account.appearance.color;
      return color == null ? null : Color(color);
    },
    onSelected: (account) => _form.account = account,
    addLabel: texts.addAccount,
    onAdd: _addAccount,
  );

  Widget _momentPickers(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat.yMMMd(locale).format(_form.dateTime)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pickTime,
          icon: const Icon(Icons.schedule),
          label: Text(DateFormat.Hm(locale).format(_form.dateTime)),
        ),
      ],
    );
  }
}

/// One item of the transaction: its category and amount, its name and the
/// people it is shared with.
class _ItemCard extends StatelessWidget {
  const _ItemCard({super.key, required this.form, required this.item});

  final TransactionFormViewModel form;
  final ItemDraft item;

  Future<void> _pickCategory(BuildContext context) async {
    final id = await pickCategory(context, form);
    if (id != null) item.categoryId = id;
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final problem = form.problemOf(item);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            _categoryAndAmount(context, texts),
            TextFormField(
              initialValue: item.name,
              decoration: InputDecoration(labelText: texts.itemName),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (name) => item.name = name,
            ),
            if (item.others.isNotEmpty && item.includesMe)
              _myPart(context, texts),
            for (final share in item.others)
              _ShareRow(
                key: ObjectKey(share),
                share: share,
                currencySymbol: _currencySymbol(context),
                onRemove: () => form.removePerson(item, share),
              ),
            _sharingActions(texts),
            if (problem != null)
              Text(
                _describe(context, problem, texts),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryAndAmount(BuildContext context, AppLocalizations texts) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Expanded(child: _categoryField(context, texts)),
          SizedBox(
            width: 120,
            child: _AmountField(
              initialValue: item.price,
              label: texts.amount,
              currencySymbol: _currencySymbol(context),
              onChanged: (price) => item.price = price,
            ),
          ),
          IconButton(
            onPressed: form.items.length > 1
                ? () => form.removeItem(item)
                : null,
            tooltip: texts.removeItem,
            icon: const Icon(Icons.close),
          ),
        ],
      );

  /// Shows the emoji and the name of the chosen category, and opens the
  /// picker when it is tapped.
  Widget _categoryField(BuildContext context, AppLocalizations texts) {
    final id = item.categoryId;
    final category = id == null ? null : form.categoryOf(id);
    return InkWell(
      onTap: () => _pickCategory(context),
      borderRadius: BorderRadius.circular(28),
      child: Row(
        spacing: 12,
        children: [
          if (category == null)
            const CircleAvatar(child: Icon(Icons.category_outlined))
          else
            AppearanceAvatar(
              appearance: category.appearance,
              name: category.name,
            ),
          Expanded(
            child: Text(
              category == null
                  ? texts.chooseCategory
                  : form.labelOf(category.id),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// The row that shows I am one of those the item is shared among, with
  /// the part that is left for me.
  Widget _myPart(BuildContext context, AppLocalizations texts) {
    final own = form.ownPartOf(item);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return Row(
      spacing: 8,
      children: [
        const Icon(Icons.person),
        Expanded(child: Text(texts.me)),
        Text(own == null ? '—' : money.format(own)),
      ],
    );
  }

  Widget _sharingActions(AppLocalizations texts) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      TextButton.icon(
        onPressed: () => form.addPerson(item),
        icon: const Icon(Icons.person_add_alt),
        label: Text(texts.addPerson),
      ),
      if (item.others.isNotEmpty) ...[
        TextButton(
          onPressed: () => form.splitEvenly(item),
          child: Text(texts.splitEvenly),
        ),
        FilterChip(
          label: Text(texts.includeMe),
          selected: item.includesMe,
          onSelected: (includesMe) => item.includesMe = includesMe,
        ),
      ],
    ],
  );

  String? _currencySymbol(BuildContext context) {
    final currency = form.currency;
    if (currency == null) return null;
    return MoneyFormatter(Localizations.localeOf(context).toString())
        .symbolOf(currency);
  }

  String _describe(
    BuildContext context,
    ItemProblem problem,
    AppLocalizations texts,
  ) => switch (problem) {
    ItemProblem.invalidAmount => texts.itemNeedsAmount,
    ItemProblem.missingCategory => texts.itemNeedsCategory,
    ItemProblem.incompleteShare => texts.shareIncomplete,
    ItemProblem.repeatedPerson => texts.personRepeated,
    ItemProblem.sharesExceedAmount => texts.sharesExceedAmount,
    ItemProblem.sharesDoNotAddUp => _partsDoNotAddUp(context, texts),
  };

  String _partsDoNotAddUp(BuildContext context, AppLocalizations texts) {
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    final sum = form.othersTotalOf(item);
    final own = form.ownPartOf(item);
    if (sum == null || own == null) return texts.shareIncomplete;
    return texts.sharesDoNotAddUp(money.format(sum), money.format(sum + own));
  }
}

/// One person an item is shared with, and the part that person bears.
class _ShareRow extends StatelessWidget {
  const _ShareRow({
    super.key,
    required this.share,
    required this.currencySymbol,
    required this.onRemove,
  });

  final ShareDraft share;
  final String? currencySymbol;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: TextFormField(
            initialValue: share.person,
            decoration: InputDecoration(labelText: texts.person),
            textCapitalization: TextCapitalization.words,
            onChanged: (person) => share.person = person,
          ),
        ),
        SizedBox(
          width: 120,
          child: _AmountField(
            initialValue: share.amount,
            label: texts.amount,
            currencySymbol: currencySymbol,
            onChanged: (amount) => share.amount = amount,
          ),
        ),
        IconButton(
          onPressed: onRemove,
          tooltip: texts.removePerson,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

/// A field to type an amount of money in, followed by its currency.
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.initialValue,
    required this.label,
    required this.currencySymbol,
    required this.onChanged,
  });

  final String initialValue;
  final String label;
  final String? currencySymbol;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initialValue,
    decoration: InputDecoration(labelText: label, suffixText: currencySymbol),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.end,
    onChanged: onChanged,
  );
}
