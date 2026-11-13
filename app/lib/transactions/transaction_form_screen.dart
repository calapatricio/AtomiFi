import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              _directionPicker(texts),
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
              Text(texts.items, style: Theme.of(context).textTheme.titleMedium),
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
              _total(context, texts),
            ],
          ),
        ),
      ),
    );
  }

  Widget _directionPicker(AppLocalizations texts) =>
      SegmentedButton<Direction>(
        segments: [
          ButtonSegment(value: Direction.expense, label: Text(texts.expense)),
          ButtonSegment(value: Direction.income, label: Text(texts.income)),
        ],
        selected: {_form.direction},
        onSelectionChanged: (selected) => _form.direction = selected.single,
      );

  Widget _accountPicker(AppLocalizations texts) => DropdownMenu<AccountId>(
    key: ValueKey(_form.account?.id),
    label: Text(texts.account),
    expandedInsets: EdgeInsets.zero,
    initialSelection: _form.account?.id,
    dropdownMenuEntries: [
      for (final account in _form.accounts)
        DropdownMenuEntry(value: account.id, label: account.name),
    ],
    onSelected: (id) => _form.account = _form.accounts
        .where((account) => account.id == id)
        .firstOrNull,
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

  Widget _total(BuildContext context, AppLocalizations texts) {
    final total = _form.total;
    if (total == null) return const SizedBox.shrink();
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return Text(
      texts.total(money.format(total)),
      style: Theme.of(context).textTheme.titleMedium,
      textAlign: TextAlign.end,
    );
  }
}

/// One item of the transaction: its category and amount, its name and the
/// people it is shared with.
class _ItemCard extends StatelessWidget {
  const _ItemCard({super.key, required this.form, required this.item});

  final TransactionFormViewModel form;
  final ItemDraft item;

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
            _categoryAndAmount(texts),
            TextFormField(
              initialValue: item.name,
              decoration: InputDecoration(labelText: texts.itemName),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (name) => item.name = name,
            ),
            for (final share in item.others)
              _ShareRow(
                key: ObjectKey(share),
                share: share,
                onRemove: () => form.removePerson(item, share),
              ),
            _sharingActions(texts),
            if (item.others.isNotEmpty) _ownPart(context, texts),
            if (problem != null)
              Text(
                _describe(problem, texts),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryAndAmount(AppLocalizations texts) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Expanded(
        child: DropdownMenu<CategoryId>(
          label: Text(texts.category),
          expandedInsets: EdgeInsets.zero,
          initialSelection: item.categoryId,
          dropdownMenuEntries: [
            for (final option in form.categoryOptions)
              DropdownMenuEntry(value: option.id, label: option.label),
          ],
          onSelected: (id) => item.categoryId = id,
        ),
      ),
      SizedBox(
        width: 110,
        child: TextFormField(
          initialValue: item.price,
          decoration: InputDecoration(labelText: texts.amount),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.end,
          onChanged: (price) => item.price = price,
        ),
      ),
      if (form.items.length > 1)
        IconButton(
          onPressed: () => form.removeItem(item),
          tooltip: texts.removeItem,
          icon: const Icon(Icons.close),
        ),
    ],
  );

  Widget _sharingActions(AppLocalizations texts) => Wrap(
    spacing: 8,
    children: [
      TextButton.icon(
        onPressed: () => form.addPerson(item),
        icon: const Icon(Icons.person_add_alt),
        label: Text(texts.addPerson),
      ),
      if (item.others.isNotEmpty)
        TextButton(
          onPressed: () => form.splitEvenly(item),
          child: Text(texts.splitEvenly),
        ),
    ],
  );

  Widget _ownPart(BuildContext context, AppLocalizations texts) {
    final own = form.ownPartOf(item);
    if (own == null) return const SizedBox.shrink();
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return Text(texts.yourPart(money.format(own)));
  }

  static String _describe(ItemProblem problem, AppLocalizations texts) =>
      switch (problem) {
        ItemProblem.invalidAmount => texts.itemNeedsAmount,
        ItemProblem.missingCategory => texts.itemNeedsCategory,
        ItemProblem.incompleteShare => texts.shareIncomplete,
        ItemProblem.repeatedPerson => texts.personRepeated,
        ItemProblem.sharesExceedAmount => texts.sharesExceedAmount,
      };
}

/// One person an item is shared with, and the part that person bears.
class _ShareRow extends StatelessWidget {
  const _ShareRow({super.key, required this.share, required this.onRemove});

  final ShareDraft share;
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
          width: 110,
          child: TextFormField(
            initialValue: share.amount,
            decoration: InputDecoration(labelText: texts.amount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
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
