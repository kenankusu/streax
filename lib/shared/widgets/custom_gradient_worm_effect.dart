import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Ein WormEffect mit Gradient für den aktiven Punkt
// Custom effect for SmoothPageIndicator with gradient active dot
class CustomGradientWormEffect extends IndicatorEffect {
  final Gradient activeDotGradient;
  final double dotWidth;
  final double dotHeight;
  final double spacing;
  final Color dotColor;
  final PaintingStyle paintStyle;
  final double radius;
  final double strokeWidth;

  const CustomGradientWormEffect({
    required this.activeDotGradient,
    this.dotWidth = 16.0,
    this.dotHeight = 16.0,
    this.spacing = 8.0,
    this.dotColor = Colors.white54,
    this.paintStyle = PaintingStyle.fill,
    this.radius = 16.0,
    this.strokeWidth = 1.0,
  });

  //
  @override
  Size calculateSize(int count) {
    return Size(
      (dotWidth + spacing) * count - spacing,
      dotHeight,
    );
  }


  @override
  int hitTestDots(double dx, int count, double offset) {
    // Returns the index of the dot at position dx, or -1 if none
    for (int i = 0; i < count; i++) {
      final dotStart = i * (dotWidth + spacing);
      final dotEnd = dotStart + dotWidth;
      if (dx >= dotStart && dx <= dotEnd) {
        return i;
      }
    }
    return -1;
  }


  @override
  IndicatorPainter buildPainter(int count, double offset) {
    return _GradientWormPainter(
      offset: offset,
      count: count,
      effect: this,
      activeDotGradient: activeDotGradient,
    );
  }

  // build() is not needed for custom IndicatorEffect
}

class _GradientWormPainter extends IndicatorPainter {
  @override
  final double offset;
  final int count;
  final CustomGradientWormEffect effect;
  final Gradient activeDotGradient;

  _GradientWormPainter({
    required this.offset,
    required this.count,
    required this.effect,
    required this.activeDotGradient,
  }) : super(offset);

  @override
  void paint(Canvas canvas, Size size) {
    // Standardpunkte malen
    for (int i = 0; i < count; i++) {
      if (i != offset.floor() && i != offset.ceil()) {
        final x = i * (effect.dotWidth + effect.spacing) + effect.dotWidth / 2;
        final y = size.height / 2;
        final paint = Paint()
          ..color = effect.dotColor
          ..style = effect.paintStyle;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y),
              width: effect.dotWidth,
              height: effect.dotHeight,
            ),
            Radius.circular(effect.radius),
          ),
          paint,
        );
      }
    }

    // Aktiver Punkt (Worm)
    final wormX = offset * (effect.dotWidth + effect.spacing) + effect.dotWidth / 2;
    final y = size.height / 2;
    final rect = Rect.fromCenter(
      center: Offset(wormX, y),
      width: effect.dotWidth,
      height: effect.dotHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(effect.radius));
    final paint = Paint()
      ..shader = activeDotGradient.createShader(rect)
      ..style = effect.paintStyle;
    canvas.drawRRect(rrect, paint);
  }
}
