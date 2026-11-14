import 'package:atomifi/widgets/choice_carousel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('ChoiceCarousel', () {
    Future<void> pump(
      WidgetTester tester, {
      String? selected,
      ValueChanged<String>? onSelected,
      VoidCallback? onAdd,
    }) => pumpScreen(
      tester,
      Scaffold(
        body: ChoiceCarousel<String>(
          choices: const ['Bank', 'Savings', 'Cash'],
          selected: selected,
          labelOf: (choice) => choice,
          onSelected: onSelected ?? (_) {},
          addLabel: onAdd == null ? null : 'Add account',
          onAdd: onAdd,
        ),
      ),
    );

    bool isSelected(WidgetTester tester, String label) => tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
        .selected;

    testWidgets('shows every choice and marks the selected one', (
      tester,
    ) async {
      await pump(tester, selected: 'Savings');

      expect(isSelected(tester, 'Bank'), isFalse);
      expect(isSelected(tester, 'Savings'), isTrue);
      expect(isSelected(tester, 'Cash'), isFalse);
    });

    testWidgets('tells which choice was tapped', (tester) async {
      final tapped = <String>[];
      await pump(tester, onSelected: tapped.add);

      await tester.tap(find.text('Cash'));

      expect(tapped, ['Cash']);
    });

    testWidgets('ends with a way to add a choice when there is one', (
      tester,
    ) async {
      var added = 0;
      await pump(tester, onAdd: () => added++);

      await tester.tap(find.text('Add account'));

      expect(added, 1);
    });

    testWidgets('offers nothing to add otherwise', (tester) async {
      await pump(tester);

      expect(find.byType(ActionChip), findsNothing);
    });
  });
}
