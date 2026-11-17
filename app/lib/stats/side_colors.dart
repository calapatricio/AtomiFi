import 'package:atomifi_domain/atomifi_domain.dart';
import 'package:material_ui/material_ui.dart';

/// The color that stands for a side of the statistics: red for money
/// spent, green for money earned.
Color colorOfSide(CategorySide side) => switch (side) {
  CategorySide.expense => Colors.red,
  CategorySide.income => Colors.green,
  CategorySide.neutral => Colors.grey,
};
