import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class RideGoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const RideGoLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _RideGoLogoPainter()),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: size * 0.26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: textColor ?? AppColors.headerNavy,
              ),
              children: const [
                TextSpan(text: 'Ride'),
                TextSpan(
                  text: 'Go',
                  style: TextStyle(color: AppColors.buttonTeal),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RideGoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bubbles / water spray dots (light cyan)
    final bubblePaint = Paint()
      ..color = const Color(0xFF48CAE4).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final bubblePositions = [
      Offset(w * 0.18, h * 0.28),
      Offset(w * 0.24, h * 0.18),
      Offset(w * 0.78, h * 0.22),
      Offset(w * 0.84, h * 0.35),
      Offset(w * 0.14, h * 0.52),
      Offset(w * 0.88, h * 0.55),
      Offset(w * 0.22, h * 0.72),
      Offset(w * 0.80, h * 0.70),
    ];

    final bubbleRadii = [
      w * 0.05,
      w * 0.035,
      w * 0.045,
      w * 0.03,
      w * 0.04,
      w * 0.05,
      w * 0.035,
      w * 0.04,
    ];

    for (int i = 0; i < bubblePositions.length; i++) {
      canvas.drawCircle(bubblePositions[i], bubbleRadii[i], bubblePaint);
    }

    // Shield/Badge outline
    final shieldPaint = Paint()
      ..color = AppColors.headerNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;

    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, h * 0.12);
    shieldPath.lineTo(w * 0.82, h * 0.30);
    shieldPath.lineTo(w * 0.82, h * 0.65);
    shieldPath.quadraticBezierTo(w * 0.82, h * 0.86, w * 0.5, h * 0.94);
    shieldPath.quadraticBezierTo(w * 0.18, h * 0.86, w * 0.18, h * 0.65);
    shieldPath.lineTo(w * 0.18, h * 0.30);
    shieldPath.close();

    // Subtle shield fill
    final shieldFill = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldFill);
    canvas.drawPath(shieldPath, shieldPaint);

    // Car silhouette in center of shield
    final carPaint = Paint()
      ..color = AppColors.buttonTeal
      ..style = PaintingStyle.fill;

    final carPath = Path();
    // Car roof and windshield
    carPath.moveTo(w * 0.36, h * 0.44);
    carPath.quadraticBezierTo(w * 0.40, h * 0.35, w * 0.50, h * 0.35);
    carPath.quadraticBezierTo(w * 0.60, h * 0.35, w * 0.64, h * 0.44);
    carPath.lineTo(w * 0.72, h * 0.48);
    // Front hood
    carPath.quadraticBezierTo(w * 0.75, h * 0.52, w * 0.74, h * 0.58);
    // Wheels and underside
    carPath.lineTo(w * 0.67, h * 0.58);
    // Front wheel cutout
    carPath.arcToPoint(
      Offset(w * 0.59, h * 0.58),
      radius: Radius.circular(w * 0.04),
      clockwise: false,
    );
    carPath.lineTo(w * 0.41, h * 0.58);
    // Rear wheel cutout
    carPath.arcToPoint(
      Offset(w * 0.33, h * 0.58),
      radius: Radius.circular(w * 0.04),
      clockwise: false,
    );
    carPath.lineTo(w * 0.26, h * 0.58);
    carPath.quadraticBezierTo(w * 0.25, h * 0.52, w * 0.28, h * 0.48);
    carPath.close();

    canvas.drawPath(carPath, carPaint);

    // Wheels
    final wheelPaint = Paint()
      ..color = AppColors.headerNavy
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.63, h * 0.58), w * 0.038, wheelPaint);
    canvas.drawCircle(Offset(w * 0.37, h * 0.58), w * 0.038, wheelPaint);

    // Speed lines under car
    final linePaint = Paint()
      ..color = AppColors.accentCyan
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.30, h * 0.68),
      Offset(w * 0.70, h * 0.68),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
