import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../theme/app_colors.dart';

/// The login hero background (Figma `20:1184`): 24 rotated ellipses and 3
/// concentric circles, centered in the canvas.
class GuillochePainter extends CustomPainter {
  const GuillochePainter();

  static const int _ellipses = 24;
  static const double _stepDegrees = 7.5;
  static const double _ellipseRadiusX = 360;
  static const double _ellipseRadiusY = 125;
  static const List<double> _circleRadii = [59.5, 119.5, 179.5];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ellipsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.textInverse.withValues(alpha: 0.09);
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.textInverse.withValues(alpha: 0.07);

    final ellipse = Rect.fromCenter(
      center: Offset.zero,
      width: _ellipseRadiusX * 2,
      height: _ellipseRadiusY * 2,
    );
    for (var k = 0; k < _ellipses; k++) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(k * _stepDegrees * math.pi / 180)
        ..drawOval(ellipse, ellipsePaint)
        ..restore();
    }
    for (final radius in _circleRadii) {
      canvas.drawCircle(center, radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(GuillochePainter oldDelegate) => false;
}
