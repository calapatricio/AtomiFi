import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

/// The round badge of an account: its emoji, or else its initial, on its
/// color.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final color = account.appearance.color;
    return CircleAvatar(
      backgroundColor: color == null ? null : Color(color),
      child: Text(account.appearance.emoji ?? _initialOf(account.name)),
    );
  }

  static String _initialOf(String name) =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();
}
