// lib/widgets/animated_o.dart
import 'package:flutter/material.dart';

class AnimatedO extends StatelessWidget {
  const AnimatedO({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(painter: _CirclePainter(value)),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  _CirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -1.57,
      6.28 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
