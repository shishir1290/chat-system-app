import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatBackground extends StatelessWidget {
  final Widget child;

  const ChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF030A1C), // Deep subtle navy slate
            Color(0xFF020617), // Deep slate 950
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _DoodlePatternPainter(),
          ),
          child,
        ],
      ),
    );
  }
}

class _DoodlePatternPainter extends CustomPainter {
  const _DoodlePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8) // Ultra-subtle wallpaper doodle opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white.withAlpha(5)
      ..style = PaintingStyle.fill;

    const double stepX = 72.0;
    const double stepY = 72.0;

    int cols = (size.width / stepX).ceil() + 1;
    int rows = (size.height / stepY).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = c * stepX + (r % 2 == 1 ? stepX / 2 : 0);
        final double y = r * stepY;

        final int iconType = (r * 7 + c * 13) % 9;

        canvas.save();
        canvas.translate(x, y);

        switch (iconType) {
          case 0:
            // Chat bubble
            final path = Path()
              ..moveTo(-8, -6)
              ..lineTo(8, -6)
              ..quadraticBezierTo(12, -6, 12, -2)
              ..lineTo(12, 4)
              ..quadraticBezierTo(12, 8, 8, 8)
              ..lineTo(-2, 8)
              ..lineTo(-6, 12)
              ..lineTo(-5, 8)
              ..lineTo(-8, 8)
              ..quadraticBezierTo(-12, 8, -12, 4)
              ..lineTo(-12, -2)
              ..quadraticBezierTo(-12, -6, -8, -6);
            canvas.drawPath(path, paint);
            break;

          case 1:
            // Small Star / Sparkle
            final starPath = Path()
              ..moveTo(0, -9)
              ..lineTo(2.5, -2.5)
              ..lineTo(9, 0)
              ..lineTo(2.5, 2.5)
              ..lineTo(0, 9)
              ..lineTo(-2.5, 2.5)
              ..lineTo(-9, 0)
              ..lineTo(-2.5, -2.5)
              ..close();
            canvas.drawPath(starPath, fillPaint);
            break;

          case 2:
            // Heart outline
            final heartPath = Path()
              ..moveTo(0, 4)
              ..cubicTo(-6, -2, -10, -7, -4, -9)
              ..cubicTo(0, -9, 0, -4, 0, -4)
              ..cubicTo(0, -4, 0, -9, 4, -9)
              ..cubicTo(10, -7, 6, -2, 0, 4);
            canvas.drawPath(heartPath, paint);
            break;

          case 3:
            // Paper plane
            final planePath = Path()
              ..moveTo(-9, 7)
              ..lineTo(9, -7)
              ..lineTo(-1, 9)
              ..lineTo(-3, 3)
              ..lineTo(4, -3)
              ..lineTo(-6, 2)
              ..close();
            canvas.drawPath(planePath, paint);
            break;

          case 4:
            // Musical note
            final notePath = Path()
              ..addOval(Rect.fromCircle(center: const Offset(-4, 4), radius: 3))
              ..moveTo(-1, 4)
              ..lineTo(-1, -7)
              ..lineTo(6, -4)
              ..lineTo(6, 1)
              ..addOval(Rect.fromCircle(center: const Offset(3, 1), radius: 3));
            canvas.drawPath(notePath, paint);
            break;

          case 5:
            // Geometric Concentric Circles
            canvas.drawCircle(Offset.zero, 7, paint);
            canvas.drawCircle(Offset.zero, 2.5, fillPaint);
            break;

          case 6:
            // Lightning bolt
            final bolt = Path()
              ..moveTo(1, -9)
              ..lineTo(-5, 0)
              ..lineTo(-1, 0)
              ..lineTo(-3, 9)
              ..lineTo(5, -1)
              ..lineTo(1, -1)
              ..close();
            canvas.drawPath(bolt, paint);
            break;

          case 7:
            // Shield / Lock
            final shield = Path()
              ..moveTo(-6, -6)
              ..lineTo(6, -6)
              ..lineTo(6, 1)
              ..quadraticBezierTo(6, 7, 0, 9)
              ..quadraticBezierTo(-6, 7, -6, 1)
              ..close();
            canvas.drawPath(shield, paint);
            break;

          case 8:
            // Small Diamond grid
            final diamond = Path()
              ..moveTo(0, -6)
              ..lineTo(6, 0)
              ..lineTo(0, 6)
              ..lineTo(-6, 0)
              ..close();
            canvas.drawPath(diamond, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
