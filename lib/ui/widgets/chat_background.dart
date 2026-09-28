import 'package:flutter/material.dart';

class ChatBackground extends StatelessWidget {
  final Widget child;

  const ChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B141A), // Modern WhatsApp Dark Background
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF0E1C26), // Subtle center glow
            Color(0xFF0B141A), // Deep wallpaper base
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
    // Clear visible opacity (~15% - 18%) for distinct, beautiful wallpaper pattern
    final paint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const double stepX = 76.0;
    const double stepY = 76.0;

    final int cols = (size.width / stepX).ceil() + 1;
    final int rows = (size.height / stepY).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = c * stepX + (r % 2 == 1 ? stepX / 2 : 0);
        final double y = r * stepY;

        final int iconType = (r * 5 + c * 11) % 10;

        canvas.save();
        canvas.translate(x, y);

        switch (iconType) {
          case 0:
            // Chat bubble
            final path = Path()
              ..moveTo(-9, -7)
              ..lineTo(9, -7)
              ..quadraticBezierTo(13, -7, 13, -3)
              ..lineTo(13, 4)
              ..quadraticBezierTo(13, 8, 9, 8)
              ..lineTo(-1, 8)
              ..lineTo(-5, 12)
              ..lineTo(-4, 8)
              ..lineTo(-9, 8)
              ..quadraticBezierTo(-13, 8, -13, 4)
              ..lineTo(-13, -3)
              ..quadraticBezierTo(-13, -7, -9, -7);
            canvas.drawPath(path, paint);
            break;

          case 1:
            // Sparkle / Four-point Star
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
            canvas.drawPath(starPath, paint);
            break;

          case 2:
            // Heart outline
            final heartPath = Path()
              ..moveTo(0, 5)
              ..cubicTo(-6, -1, -11, -7, -5, -9)
              ..cubicTo(-1, -10, 0, -5, 0, -5)
              ..cubicTo(0, -5, 1, -10, 5, -9)
              ..cubicTo(11, -7, 6, -1, 0, 5);
            canvas.drawPath(heartPath, paint);
            break;

          case 3:
            // Paper plane
            final planePath = Path()
              ..moveTo(-10, 8)
              ..lineTo(10, -8)
              ..lineTo(-1, 10)
              ..lineTo(-3, 3)
              ..lineTo(5, -3)
              ..lineTo(-7, 2)
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
            // Smiley Emoji
            canvas.drawCircle(Offset.zero, 8, paint);
            canvas.drawCircle(const Offset(-3, -2), 1, fillPaint);
            canvas.drawCircle(const Offset(3, -2), 1, fillPaint);
            final smilePath = Path()
              ..moveTo(-4, 2)
              ..quadraticBezierTo(0, 5.5, 4, 2);
            canvas.drawPath(smilePath, paint);
            break;

          case 6:
            // Camera
            final camBody = RRect.fromRectAndRadius(
              Rect.fromCenter(center: const Offset(0, 1), width: 18, height: 13),
              const Radius.circular(3),
            );
            canvas.drawRRect(camBody, paint);
            canvas.drawCircle(const Offset(0, 1), 3.5, paint);
            final camTop = Path()
              ..moveTo(-4, -5.5)
              ..lineTo(-2, -8.5)
              ..lineTo(2, -8.5)
              ..lineTo(4, -5.5);
            canvas.drawPath(camTop, paint);
            break;

          case 7:
            // Lock / Security
            final body = RRect.fromRectAndRadius(
              Rect.fromCenter(center: const Offset(0, 3), width: 14, height: 10),
              const Radius.circular(2),
            );
            canvas.drawRRect(body, paint);
            final shackle = Path()
              ..moveTo(-4, -2)
              ..lineTo(-4, -5)
              ..quadraticBezierTo(-4, -9, 0, -9)
              ..quadraticBezierTo(4, -9, 4, -5)
              ..lineTo(4, -2);
            canvas.drawPath(shackle, paint);
            break;

          case 8:
            // Microphone
            final micBody = RRect.fromRectAndRadius(
              Rect.fromCenter(center: const Offset(0, -3), width: 7, height: 11),
              const Radius.circular(3.5),
            );
            canvas.drawRRect(micBody, paint);
            final micStand = Path()
              ..moveTo(-6, -2)
              ..quadraticBezierTo(-6, 5, 0, 5)
              ..quadraticBezierTo(6, 5, 6, -2)
              ..moveTo(0, 5)
              ..lineTo(0, 9)
              ..moveTo(-4, 9)
              ..lineTo(4, 9);
            canvas.drawPath(micStand, paint);
            break;

          case 9:
            // Image / Gallery picture icon
            final imgFrame = RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 16, height: 14),
              const Radius.circular(2),
            );
            canvas.drawRRect(imgFrame, paint);
            canvas.drawCircle(const Offset(-3.5, -2.5), 1.5, fillPaint);
            final mountain = Path()
              ..moveTo(-7, 5)
              ..lineTo(-2, 0)
              ..lineTo(2, 4)
              ..lineTo(4, 2)
              ..lineTo(7, 5);
            canvas.drawPath(mountain, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

