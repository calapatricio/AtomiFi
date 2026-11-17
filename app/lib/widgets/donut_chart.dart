import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// One part of a [DonutChart].
final class DonutSegment {
  const DonutSegment({required this.fraction, required this.color});

  /// The part of the whole ring it takes, from 0 to 1.
  final double fraction;
  final Color color;
}

/// A ring divided into coloured parts, which start at the top and go round
/// clockwise, with room in the middle for [child].
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.onSegmentTap,
    this.child,
  });

  final List<DonutSegment> segments;

  /// Called with the position in [segments] of the part that is tapped.
  final ValueChanged<int>? onSegmentTap;
  final Widget? child;

  static const _thickness = 28.0;
  static const _fullTurn = 2 * math.pi;
  static const _top = -math.pi / 2;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: (details) {
      final size = context.size;
      if (size == null) return;
      final tapped = _segmentAt(details.localPosition, size);
      if (tapped != null) onSegmentTap?.call(tapped);
    },
    child: CustomPaint(
      painter: _DonutPainter(segments),
      child: Center(child: child),
    ),
  );

  /// The position of the segment that [position] points at, if it is
  /// inside the circle.
  int? _segmentAt(Offset position, Size size) {
    final fromCenter = position - size.center(Offset.zero);
    if (segments.isEmpty || fromCenter.distance > size.shortestSide / 2) {
      return null;
    }
    final turn = ((fromCenter.direction - _top) / _fullTurn) % 1;
    var end = 0.0;
    for (final (index, segment) in segments.indexed) {
      end += segment.fraction;
      if (turn < end) return index;
    }
    return segments.length - 1;
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.segments);

  final List<DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - DonutChart._thickness) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = DonutChart._thickness;
    var start = DonutChart._top;
    for (final segment in segments) {
      final sweep = segment.fraction * DonutChart._fullTurn;
      canvas.drawArc(ring, start, sweep, false, paint..color = segment.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.segments != segments;
}
