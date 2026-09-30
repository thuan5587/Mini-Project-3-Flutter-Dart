import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import 'weekly_bar_chart_painter.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<DailySpending> dailySpendings;
  final double height;

  const WeeklyBarChart({
    super.key,
    required this.dailySpendings,
    this.height = 190,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailySpendings != widget.dailySpendings) {
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
    if (widget.dailySpendings.isEmpty) return;

    final leftPadding = 45.0;
    final rightPadding = 12.0;
    final chartWidth = constraints.maxWidth - leftPadding - rightPadding;
    final barCount = widget.dailySpendings.length;
    final slotWidth = chartWidth / barCount;

    final touchX = details.localPosition.dx - leftPadding;
    if (touchX >= 0 && touchX <= chartWidth) {
      final index = (touchX / slotWidth).floor().clamp(0, barCount - 1);
      setState(() {
        if (_selectedIndex == index) {
          _selectedIndex = null;
        } else {
          _selectedIndex = index;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(constraints.maxWidth, widget.height),
                painter: WeeklyBarChartPainter(
                  dailySpendings: widget.dailySpendings,
                  animationProgress: _animation.value,
                  selectedIndex: _selectedIndex,
                  isDark: isDark,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
