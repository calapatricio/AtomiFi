import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../money_formatter.dart';
import 'accounts_view_model.dart';

/// Says what deleting an account takes with it and asks whether to go on.
///
/// Completes with `true` only when the user confirms.
Future<bool> showRemoveAccountDialog(
  BuildContext context, {
  required AccountRemoval removal,
  required List<BalanceChange> balanceChanges,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _RemoveAccountDialog(removal, balanceChanges),
  );
  return confirmed ?? false;
}

class _RemoveAccountDialog extends StatelessWidget {
  const _RemoveAccountDialog(this.removal, this.balanceChanges);

  final AccountRemoval removal;
  final List<BalanceChange> balanceChanges;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final money = MoneyFormatter(Localizations.localeOf(context).toString());
    return AlertDialog(
      title: Text(texts.deleteAccountTitle(removal.account.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.deleteAccountRecords(removal.recordCount)),
          for (final (:account, :change) in balanceChanges)
            Text(
              texts.deleteAccountBalanceChange(
                account.name,
                money.format(change),
              ),
            ),
          const SizedBox(height: 16),
          Text(texts.cannotBeUndone),
        ],
      ),
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
    );
  }
}
