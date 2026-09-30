import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CropFramingOverlay extends StatefulWidget {
  final Rect Function(Size) onGetFrameRect;

  const CropFramingOverlay({
    super.key,
    required this.onGetFrameRect,
  });

  @override
  State<CropFramingOverlay> createState() => _CropFramingOverlayState();
}

class _CropFramingOverlayState extends State<CropFramingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: CropFramingPainter(
            scanProgress: _scanController.value,
            getFrameRect: widget.onGetFrameRect,
          ),
        );
      },
    );
  }
}

class CropFramingPainter extends CustomPainter {
  final double scanProgress;
  final Rect Function(Size) getFrameRect;

  CropFramingPainter({
    required this.scanProgress,
    required this.getFrameRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frame = getFrameRect(size);

    // 1. Dark vignette mask outside the frame
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    canvas.drawPath(maskPath, maskPaint);

    // 2. Framing border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(16)),
      borderPaint,
    );

    // 3. Four high-contrast corner brackets
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;
    const radius = 16.0;

    // Top-Left
    final tlPath = Path()
      ..moveTo(frame.left, frame.top + cornerLength)
      ..lineTo(frame.left, frame.top + radius)
      ..arcToPoint(Offset(frame.left + radius, frame.top), radius: const Radius.circular(radius))
      ..lineTo(frame.left + cornerLength, frame.top);
    canvas.drawPath(tlPath, cornerPaint);

    // Top-Right
    final trPath = Path()
      ..moveTo(frame.right - cornerLength, frame.top)
      ..lineTo(frame.right - radius, frame.top)
      ..arcToPoint(Offset(frame.right, frame.top + radius), radius: const Radius.circular(radius))
      ..lineTo(frame.right, frame.top + cornerLength);
    canvas.drawPath(trPath, cornerPaint);

    // Bottom-Left
    final blPath = Path()
      ..moveTo(frame.left, frame.bottom - cornerLength)
      ..lineTo(frame.left, frame.bottom - radius)
      ..arcToPoint(Offset(frame.left + radius, frame.bottom), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(frame.left + cornerLength, frame.bottom);
    canvas.drawPath(blPath, cornerPaint);

    // Bottom-Right
    final brPath = Path()
      ..moveTo(frame.right - cornerLength, frame.bottom)
      ..lineTo(frame.right - radius, frame.bottom)
      ..arcToPoint(Offset(frame.right, frame.bottom - radius), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(frame.right, frame.bottom - cornerLength);
    canvas.drawPath(brPath, cornerPaint);

    // 4. Animated Laser Scanner line
    final scanY = frame.top + (frame.height * scanProgress);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accent.withOpacity(0.0),
          AppColors.accent,
          AppColors.primaryLight,
          AppColors.accent.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(frame.left, scanY - 2, frame.width, 4))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(frame.left + 8, scanY),
      Offset(frame.right - 8, scanY),
      laserPaint,
    );

    // Laser glow gradient underneath
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withOpacity(0.25),
          AppColors.accent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(frame.left, scanY - 30, frame.width, 30))
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(frame.left + 8, scanY - 30, frame.width - 16, 30),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CropFramingPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}
