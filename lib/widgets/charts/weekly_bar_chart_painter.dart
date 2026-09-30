import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';

class WeeklyBarChartPainter extends CustomPainter {
  final List<DailySpending> dailySpendings;
  final double animationProgress; // 0.0 -> 1.0
  final int? selectedIndex;
  final bool isDark;

  WeeklyBarChartPainter({
    required this.dailySpendings,
    required this.animationProgress,
    this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailySpendings.isEmpty) return;

    final bottomPadding = 30.0;
    final topPadding = 25.0;
    final leftPadding = 45.0;
    final rightPadding = 12.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - bottomPadding - topPadding;

    // Find max spending to normalize bar heights
    double maxAmount = 100000; // minimum baseline 100k
    for (final d in dailySpendings) {
      if (d.amount > maxAmount) {
        maxAmount = d.amount;
      }
    }

    // Round max amount up to a nice number
    maxAmount = maxAmount * 1.15;

    // 1. Draw horizontal grid lines & Y-axis labels
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    const steps = 3;

    for (int i = 0; i <= steps; i++) {
      final y = topPadding + chartHeight - (i / steps) * chartHeight;

      // Grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Y-axis label
      final val = maxAmount * (i / steps);

      String label;

      if (val >= 1000000) {
        label = '${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        label = '${(val / 1000).toStringAsFixed(0)}k';
      } else {
        label = '0';
      }

      final textSpan = TextSpan(
        text: label,
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          leftPadding - textPainter.width - 8,
          y - textPainter.height / 2,
        ),
      );
    }

    // 2. Draw bars
    final barCount = dailySpendings.length;
    final slotWidth = chartWidth / barCount;
    final barWidth = math.min(slotWidth * 0.48, 28.0);

    final now = DateTime.now();

    for (int i = 0; i < barCount; i++) {
      final day = dailySpendings[i];

      final isCurrentDay =
          day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day;

      final isSelected = i == selectedIndex;

      final normalizedHeight =
          (day.amount / maxAmount).clamp(0.0, 1.0);

      final barHeight =
          normalizedHeight * chartHeight * animationProgress;

      final xCenter =
          leftPadding + i * slotWidth + slotWidth / 2;

      final xLeft = xCenter - barWidth / 2;

      final yTop =
          topPadding + chartHeight - barHeight;

      // Subtle background track for the bar
      final trackPaint = Paint()
        ..color =
            (isDark ? Colors.white : Colors.black).withOpacity(0.03)
        ..style = PaintingStyle.fill;

      final trackRRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          xLeft,
          topPadding,
          barWidth,
          chartHeight,
        ),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      canvas.drawRRect(trackRRect, trackPaint);

      // Bar fill with gradient
      if (barHeight > 2) {
        final barRect = Rect.fromLTWH(
          xLeft,
          yTop,
          barWidth,
          barHeight,
        );

        final barRRect = RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );

        final gradientColors = isSelected
            ? [
                AppColors.accent,
                AppColors.primary,
              ]
            : (isCurrentDay
                ? [
                    AppColors.primaryLight,
                    AppColors.primary,
                  ]
                : [
                    AppColors.primary.withOpacity(0.7),
                    AppColors.primaryDark.withOpacity(0.9),
                  ]);

        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ).createShader(barRect)
          ..style = PaintingStyle.fill;

        // Draw shadow for selected or active bar
        if (isSelected || isCurrentDay) {
          final glowPaint = Paint()
            ..color =
                (isSelected
                        ? AppColors.accent
                        : AppColors.primary)
                    .withOpacity(0.35)
            ..maskFilter =
                const MaskFilter.blur(
              BlurStyle.normal,
              6,
            );

          canvas.drawRRect(
            barRRect,
            glowPaint,
          );
        }

        canvas.drawRRect(
          barRRect,
          barPaint,
        );
      }

      // X-axis day label (T2, T3, ... CN)
      final weekday = day.date.weekday;

      final dayNamesVi = [
        'T2',
        'T3',
        'T4',
        'T5',
        'T6',
        'T7',
        'CN',
      ];

      final dayLabel = dayNamesVi[weekday - 1];

      final labelColor = isCurrentDay
          ? AppColors.primaryLight
          : (isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary);

      final labelSpan = TextSpan(
        text: dayLabel,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight:
              isCurrentDay || isSelected
                  ? FontWeight.bold
                  : FontWeight.w500,
        ),
      );

      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          xCenter - labelPainter.width / 2,
          size.height - bottomPadding + 8,
        ),
      );

      // Tooltip above selected bar
      if (isSelected && day.amount > 0) {
        final formatter = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
          decimalDigits: 0,
        );

        final tipText = formatter.format(day.amount);

        final tipSpan = TextSpan(
          text: tipText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );

        final tipPainter = TextPainter(
          text: tipSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        final tipWidth = tipPainter.width + 12;
        final tipHeight = tipPainter.height + 6;

        final tipX = (xCenter - tipWidth / 2).clamp(
          leftPadding,
          size.width - rightPadding - tipWidth,
        );

        final tipY = math.max(
          0.0,
          yTop - tipHeight - 4,
        );

        final tipRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            tipX,
            tipY,
            tipWidth,
            tipHeight,
          ),
          const Radius.circular(4),
        );

        final tipBgPaint = Paint()
          ..color = AppColors.primaryDark;

        canvas.drawRRect(
          tipRect,
          tipBgPaint,
        );

        tipPainter.paint(
          canvas,
          Offset(
            tipX + 6,
            tipY + 3,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant WeeklyBarChartPainter oldDelegate,
  ) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.dailySpendings != dailySpendings ||
        oldDelegate.isDark != isDark;
  }
}