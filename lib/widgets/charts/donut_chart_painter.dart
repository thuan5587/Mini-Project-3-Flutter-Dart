import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/expense_category.dart';

class DonutChartSegment {
  final ExpenseCategory category;
  final double amount;
  final double percentage;
  final double startAngle;
  final double sweepAngle;

  DonutChartSegment({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.startAngle,
    required this.sweepAngle,
  });
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryBreakdown;
  final double animationProgress; // 0.0 -> 1.0
  final int? selectedIndex;
  final Color backgroundColor;

  DonutChartPainter({
    required this.categoryBreakdown,
    required this.animationProgress,
    this.selectedIndex,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 18;
    final innerRadius = baseRadius * 0.62;

    final total = categoryBreakdown.values.fold(0.0, (sum, val) => sum + val);

    // Empty state ring
    if (total == 0) {
      final emptyPaint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseRadius - innerRadius;
      canvas.drawCircle(center, (baseRadius + innerRadius) / 2, emptyPaint);
      return;
    }

    double currentAngle = -math.pi / 2; // Start from top 12 o'clock
    int index = 0;

    for (final entry in categoryBreakdown.entries) {
      final category = ExpenseCategory.fromId(entry.key);
      final amount = entry.value;
      final sweepAngle = (amount / total) * 2 * math.pi * animationProgress;

      if (sweepAngle <= 0.001) {
        index++;
        continue;
      }

      final isSelected = (index == selectedIndex);
      final currentOuterRadius = isSelected ? baseRadius + 8 : baseRadius;
      final currentInnerRadius = isSelected ? innerRadius - 2 : innerRadius;

      // Draw segment path
      final path = Path();
      // Outer arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: currentOuterRadius),
        currentAngle,
        sweepAngle,
        false,
      );
      // Line to inner arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: currentInnerRadius),
        currentAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();

      // Shadow / Glow for selected slice
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = category.color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawPath(path, shadowPaint);
      }

      // Fill segment
      final fillPaint = Paint()
        ..color = category.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawPath(path, fillPaint);

      // White / Background border between segments for crisp look
      final borderPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true;

      canvas.drawPath(path, borderPaint);

      currentAngle += sweepAngle;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.categoryBreakdown != categoryBreakdown ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
