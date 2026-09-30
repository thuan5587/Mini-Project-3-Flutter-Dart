import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_category.dart';
import '../../theme/app_colors.dart';
import 'donut_chart_painter.dart';

class AnimatedDonutChart extends StatefulWidget {
  final Map<String, double> categoryBreakdown;
  final double totalAmount;
  final double size;

  const AnimatedDonutChart({
    super.key,
    required this.categoryBreakdown,
    required this.totalAmount,
    this.size = 230,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryBreakdown != widget.categoryBreakdown) {
      _controller.reset();
      _controller.forward();
      _selectedIndex = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    if (widget.totalAmount <= 0) return;

    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final baseRadius = widget.size / 2 - 18;
    final innerRadius = baseRadius * 0.62;

    // Check if tap falls within the donut ring
    if (distance < innerRadius || distance > baseRadius + 15) {
      setState(() => _selectedIndex = null);
      return;
    }

    // Calculate angle from center in [0, 2*pi], starting from 12 o'clock (-pi/2)
    var angle = math.atan2(dy, dx);
    angle += math.pi / 2; // Shift origin to top
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    double cumulativeAngle = 0;
    int index = 0;
    int? tappedIndex;

    for (final entry in widget.categoryBreakdown.entries) {
      final sweep = (entry.value / widget.totalAmount) * 2 * math.pi;
      if (angle >= cumulativeAngle && angle < cumulativeAngle + sweep) {
        tappedIndex = index;
        break;
      }
      cumulativeAngle += sweep;
      index++;
    }

    setState(() {
      if (_selectedIndex == tappedIndex) {
        _selectedIndex = null; // Toggle off
      } else {
        _selectedIndex = tappedIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    // Selected category info
    String centerTitle = 'Tổng chi tiêu';
    String centerValue = currencyFormatter.format(widget.totalAmount);
    Color centerAccent = isDark ? Colors.white : AppColors.lightTextPrimary;
    String centerSub = '${widget.categoryBreakdown.length} danh mục';

    if (_selectedIndex != null && _selectedIndex! < widget.categoryBreakdown.length) {
      final selectedEntry = widget.categoryBreakdown.entries.elementAt(_selectedIndex!);
      final category = ExpenseCategory.fromId(selectedEntry.key);
      final percent = widget.totalAmount > 0
          ? (selectedEntry.value / widget.totalAmount * 100).toStringAsFixed(1)
          : '0.0';

      centerTitle = category.nameVi;
      centerValue = currencyFormatter.format(selectedEntry.value);
      centerAccent = category.color;
      centerSub = '$percent% tổng chi';
    }

    return Column(
      children: [
        GestureDetector(
          onTapUp: (details) => _handleTap(details, BoxConstraints.tight(Size(widget.size, widget.size))),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: DonutChartPainter(
                      categoryBreakdown: widget.categoryBreakdown,
                      animationProgress: _animation.value,
                      selectedIndex: _selectedIndex,
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  );
                },
              ),
              // Center information badge
              Container(
                width: widget.size * 0.48,
                height: widget.size * 0.48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      centerTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: centerAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        centerValue,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      centerSub,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Interactive Category Legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.categoryBreakdown.entries.map((entry) {
            final category = ExpenseCategory.fromId(entry.key);
            final percent = widget.totalAmount > 0
                ? (entry.value / widget.totalAmount * 100).toStringAsFixed(0)
                : '0';
            final index = widget.categoryBreakdown.keys.toList().indexOf(entry.key);
            final isSelected = (_selectedIndex == index);

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = isSelected ? null : index;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withOpacity(0.2)
                      : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? category.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.nameVi,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
