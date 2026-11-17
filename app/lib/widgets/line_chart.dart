import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A point of a [LineChart], in whatever units its values come in.
final class LinePoint {
  const LinePoint(this.x, this.y);

  final double x;
  final double y;
}

/// A line through [points] from left to right, over a tinted area down to
/// zero. It fills the space it is given and always shows where zero is.
///
/// Touching it, or sliding a finger along it, selects the nearest point,
/// which is then marked.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.points,
    required this.color,
    this.selected,
    this.onSelected,
  });

  /// The points to join, ordered by [LinePoint.x].
  final List<LinePoint> points;
  final Color color;

  /// The position in [points] of the one to mark, if any.
  final int? selected;

  /// Called with the position in [points] of the one nearest to a touch.
  final ValueChanged<int>? onSelected;

  void _selectNear(BuildContext context, Offset position) {
    final size = context.size;
    if (size == null || points.isEmpty) return;
    final scale = _Scale(points, size);
    double distanceTo(LinePoint point) =>
        (scale.acrossOf(point.x) - position.dx).abs();
    var nearest = 0;
    for (final (index, point) in points.indexed) {
      if (distanceTo(point) < distanceTo(points[nearest])) nearest = index;
    }
    onSelected?.call(nearest);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (details) => _selectNear(context, details.localPosition),
    onHorizontalDragUpdate: (details) =>
        _selectNear(context, details.localPosition),
    child: CustomPaint(
      painter: _LinePainter(
        points: points,
        color: color,
        baselineColor: Theme.of(context).colorScheme.outlineVariant,
        selected: selected,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.points,
    required this.color,
    required this.baselineColor,
    required this.selected,
  });

  final List<LinePoint> points;
  final Color color;
  final Color baselineColor;
  final int? selected;

  static const _lineWidth = 3.0;
  static const _dotRadius = 4.0;
  static const _areaOpacity = 0.15;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final scale = _Scale(points, size);
    final places = [for (final point in points) scale.placeOf(point)];
    final baseline = scale.heightOf(0);

    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()..color = baselineColor,
    );
    final line = Path()..moveTo(places.first.dx, places.first.dy);
    for (final place in places.skip(1)) {
      line.lineTo(place.dx, place.dy);
    }
    final area = Path.from(line)
      ..lineTo(places.last.dx, baseline)
      ..lineTo(places.first.dx, baseline)
      ..close();
    canvas
      ..drawPath(area, Paint()..color = color.withValues(alpha: _areaOpacity))
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _lineWidth
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(_markedOf(places), _dotRadius, Paint()..color = color);
    final selected = this.selected;
    if (selected != null && selected < places.length) {
      canvas.drawLine(
        Offset(places[selected].dx, 0),
        Offset(places[selected].dx, size.height),
        Paint()..color = baselineColor,
      );
    }
  }

  /// Where the dot goes: on the selected point, or on the last one.
  Offset _markedOf(List<Offset> places) {
    final selected = this.selected;
    return selected != null && selected < places.length
        ? places[selected]
        : places.last;
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.selected != selected ||
      oldDelegate.baselineColor != baselineColor;
}

/// Places the values of some points inside a space, leaving room for the
/// line at its edges. Zero is always inside.
final class _Scale {
  _Scale(List<LinePoint> points, this._size)
    : _minX = points.map((point) => point.x).reduce(math.min),
      _maxX = points.map((point) => point.x).reduce(math.max),
      _minY = math.min(0.0, points.map((point) => point.y).reduce(math.min)),
      _maxY = math.max(0.0, points.map((point) => point.y).reduce(math.max));

  static const _margin = 6.0;

  final Size _size;
  final double _minX;
  final double _maxX;
  final double _minY;
  final double _maxY;

  Offset placeOf(LinePoint point) =>
      Offset(acrossOf(point.x), heightOf(point.y));

  /// How far down the space the value [y] is drawn.
  double heightOf(double y) {
    final room = _size.height - 2 * _margin;
    final part = _maxY == _minY ? 0.0 : (y - _minY) / (_maxY - _minY);
    return _size.height - _margin - part * room;
  }

  /// How far across the space the value [x] is drawn.
  double acrossOf(double x) {
    final room = _size.width - 2 * _margin;
    final part = _maxX == _minX ? 0.5 : (x - _minX) / (_maxX - _minX);
    return _margin + part * room;
  }
}
