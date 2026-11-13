import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// What the user typed to describe a new account.
typedef NewAccount = ({String name, String currencyCode});

/// Asks for the name and the currency of a new account.
///
/// Completes with nothing when the user cancels.
Future<NewAccount?> showAddAccountDialog(BuildContext context) =>
    showDialog<NewAccount>(
      context: context,
      builder: (context) => const _AddAccountDialog(),
    );

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  static final _currencyCode = RegExp(r'^[A-Za-z]{3}$');

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _currency = TextEditingController(text: 'EUR');

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context)
        .pop<NewAccount>((name: _name.text, currencyCode: _currency.text));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(texts.addAccount),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: texts.accountName),
              validator: (name) => name == null || name.trim().isEmpty
                  ? texts.accountNameRequired
                  : null,
            ),
            TextFormField(
              controller: _currency,
              decoration: InputDecoration(labelText: texts.accountCurrency),
              textCapitalization: TextCapitalization.characters,
              validator: (code) =>
                  code != null && _currencyCode.hasMatch(code.trim())
                  ? null
                  : texts.currencyCodeInvalid,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(texts.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(texts.save)),
      ],
    );
  }
}
