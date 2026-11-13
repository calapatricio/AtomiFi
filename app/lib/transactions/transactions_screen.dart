import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import '../widgets/appearance_avatar.dart';
import 'transactions_view_model.dart';

typedef OpenTransactionForm =
    Future<void> Function(BuildContext context, {Transaction? existing});

/// Lists everything that happened, day by day, latest first.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.viewModel,
    required this.openForm,
  });

  final TransactionsViewModel viewModel;

  /// Opens the form for a new transaction or for [existing], and completes
  /// when the user leaves it.
  final OpenTransactionForm openForm;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionsViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  Future<void> _openForm({Transaction? existing}) async {
    await widget.openForm(context, existing: existing);
    await _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(texts.transactionsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        tooltip: texts.addTransaction,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _viewModel.days.isEmpty
            ? Center(child: Text(texts.noTransactions))
            : ListView.builder(
                itemCount: _viewModel.days.length,
                itemBuilder: (context, index) => _Day(
                  day: _viewModel.days[index],
                  onEdit: (transaction) => _openForm(existing: transaction),
                ),
              ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.onEdit});

  final DayOfEntries day;
  final ValueChanged<Transaction> onEdit;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            DateFormat.yMMMMEEEEd(locale).format(day.date),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final entry in day.entries)
          switch (entry) {
            TransactionEntry() => _TransactionTile(
              entry,
              onTap: () => onEdit(entry.transaction),
            ),
            TransferEntry() => _TransferTile(entry),
            RevaluationEntry() => _RevaluationTile(entry),
          },
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(this.entry, {required this.onTap});

  final TransactionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    final total = entry.transaction.total;
    final category = entry.categories.firstOrNull;
    return ListTile(
      leading: category == null
          ? const CircleAvatar(child: Icon(Icons.receipt_long))
          : AppearanceAvatar(
              appearance: category.appearance,
              name: category.name,
            ),
      onTap: onTap,
      title: Text(entry.transaction.name),
      subtitle: Text(
        texts.transactionPlace(
          entry.account.name,
          entry.categories.map((category) => category.name).join(', '),
        ),
      ),
      trailing: Text(
        money.format(total),
        style: total.isPositive
            ? TextStyle(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile(this.entry);

  final TransferEntry entry;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.swap_horiz)),
      title: Text(texts.transferBetween(entry.from.name, entry.to.name)),
      subtitle: Text(texts.transfer),
      trailing: Text(money.format(entry.transfer.outgoing.amount)),
    );
  }
}

class _RevaluationTile extends StatelessWidget {
  const _RevaluationTile(this.entry);

  final RevaluationEntry entry;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.show_chart)),
      title: Text(entry.account.name),
      subtitle: Text(texts.revaluation),
      trailing: Text(money.format(entry.revaluation.value)),
    );
  }
}
