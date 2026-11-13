/// How an account or a category is shown: a color, an icon, an emoji.
final class Appearance {
  const Appearance({this.color, this.iconName, this.emoji});

  static const none = Appearance();

  /// The color as 0xAARRGGBB.
  final int? color;
  final String? iconName;
  final String? emoji;

  @override
  bool operator ==(Object other) =>
      other is Appearance &&
      other.color == color &&
      other.iconName == iconName &&
      other.emoji == emoji;

  @override
  int get hashCode => Object.hash(color, iconName, emoji);

  @override
  String toString() => 'Appearance($color, $iconName, $emoji)';
}
