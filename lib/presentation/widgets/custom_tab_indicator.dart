import 'package:flutter/material.dart';

class CustomTabIndicator extends Decoration {
  final double radius;
  final Gradient gradient;
  final double indicatorHeight;
  const CustomTabIndicator({
    this.radius = 16,
    this.indicatorHeight = 5,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  });
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomTabIndicatorPainter(this, onChanged);
  }
}

class _CustomTabIndicatorPainter extends BoxPainter {
  final CustomTabIndicator decoration;
  _CustomTabIndicatorPainter(this.decoration, VoidCallback? onChanged)
    : super(onChanged);
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    final Rect rect =
        Offset(offset.dx, config.size!.height - decoration.indicatorHeight) &
        Size(config.size!.width, decoration.indicatorHeight);
    final Paint paint =
        Paint()
          ..shader = decoration.gradient.createShader(rect)
          ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(decoration.radius),
    );
    canvas.drawRRect(rrect, paint);
  }
}
