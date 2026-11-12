/// Who bears a share of an item: the app's user or somebody else.
sealed class Party {
  const Party();
}

/// The user of the app.
final class Me extends Party {
  const Me();

  @override
  bool operator ==(Object other) => other is Me;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'me';
}

/// Somebody the user pays for, or who pays the user back.
final class Person extends Party {
  const Person(this.name);

  final String name;

  @override
  bool operator ==(Object other) => other is Person && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
