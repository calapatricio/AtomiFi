import 'package:atomifi/widgets/donut_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness.dart';

void main() {
  group('DonutChart', () {
    late List<int> tapped;

    setUp(() => tapped = []);

    Future<Offset> pump(WidgetTester tester) async {
      await pumpScreen(
        tester,
        Center(
          child: SizedBox.square(
            dimension: 200,
            child: DonutChart(
              segments: const [
                DonutSegment(fraction: 0.5, color: Colors.red),
                DonutSegment(fraction: 0.25, color: Colors.green),
                DonutSegment(fraction: 0.25, color: Colors.blue),
              ],
              onSegmentTap: tapped.add,
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.byType(DonutChart));
    }

    testWidgets('starts at the top and goes round clockwise', (tester) async {
      final topLeft = await pump(tester);

      await tester.tapAt(topLeft + const Offset(190, 100));
      await tester.tapAt(topLeft + const Offset(40, 160));
      await tester.tapAt(topLeft + const Offset(40, 40));

      expect(tapped, [0, 1, 2]);
    });

    testWidgets('ignores a tap outside the circle', (tester) async {
      final topLeft = await pump(tester);

      await tester.tapAt(topLeft + const Offset(4, 4));

      expect(tapped, isEmpty);
    });
  });
}
