import 'package:atomifi/widgets/line_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('LineChart', () {
    testWidgets('tells which point is nearest to where it is touched', (
      tester,
    ) async {
      final selected = <int>[];
      await pumpScreen(
        tester,
        Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: LineChart(
              points: const [LinePoint(0, 0), LinePoint(1, 5), LinePoint(2, 3)],
              color: Colors.blue,
              selected: null,
              onSelected: selected.add,
            ),
          ),
        ),
      );
      final topLeft = tester.getTopLeft(find.byType(LineChart));

      await tester.tapAt(topLeft + const Offset(190, 50));
      await tester.tapAt(topLeft + const Offset(95, 50));
      await tester.tapAt(topLeft + const Offset(5, 50));

      expect(selected, [2, 1, 0]);
    });
  });
}
