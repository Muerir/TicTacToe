// lib/widgets/animated_x.dart
import 'package:flutter/material.dart';

class AnimatedX extends StatelessWidget {
  const AnimatedX({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(painter: _XPainter(value)),
        );
      },
    );
  }
}

class _XPainter extends CustomPainter {
  final double progress;
  _XPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4;
    if (progress < 0.5) {
      canvas.drawLine(
        Offset(0, 0),
        Offset(size.width * progress * 2, size.height * progress * 2),
        paint,
      );
    } else {
      canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(
          size.width - (size.width * (progress - 0.5) * 2),
          size.height * (progress - 0.5) * 2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _XPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
