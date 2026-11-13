import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

/// The round badge of an account or a category: its emoji, or else the
/// initial of its name, on its color.
class AppearanceAvatar extends StatelessWidget {
  const AppearanceAvatar({
    super.key,
    required this.appearance,
    required this.name,
  });

  final Appearance appearance;
  final String name;

  @override
  Widget build(BuildContext context) {
    final color = appearance.color;
    return CircleAvatar(
      backgroundColor: color == null ? null : Color(color),
      child: Text(appearance.emoji ?? _initialOf(name)),
    );
  }

  static String _initialOf(String name) =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();
}
