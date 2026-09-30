import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/charts/animated_donut_chart.dart';
import '../widgets/charts/weekly_bar_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    // Find highest spending category
    ExpenseCategory? topCategory;
    double topCategoryAmount = 0.0;
    for (final entry in provider.categoryBreakdown.entries) {
      if (entry.value > topCategoryAmount) {
        topCategoryAmount = entry.value;
        topCategory = ExpenseCategory.fromId(entry.key);
      }
    }

    final topCategoryPercent = provider.totalSpending > 0
        ? (topCategoryAmount / provider.totalSpending * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích chi tiêu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Timeframe Filter Selector
            Row(
              children: [
                _buildTimeframePill(
                  context,
                  title: 'Toàn thời gian',
                  option: DateFilterOption.allTime,
                  isSelected: provider.selectedDateFilter == DateFilterOption.allTime,
                ),
                const SizedBox(width: 8),
                _buildTimeframePill(
                  context,
                  title: 'Tuần này',
                  option: DateFilterOption.thisWeek,
                  isSelected: provider.selectedDateFilter == DateFilterOption.thisWeek,
                ),
                const SizedBox(width: 8),
                _buildTimeframePill(
                  context,
                  title: 'Tháng này',
                  option: DateFilterOption.thisMonth,
                  isSelected: provider.selectedDateFilter == DateFilterOption.thisMonth,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Spending Insight Card
            if (topCategory != null && provider.totalSpending > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      topCategory.color.withOpacity(0.2),
                      topCategory.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: topCategory.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: topCategory.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(topCategory.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiêu cao nhất',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${topCategory.nameVi} (${currencyFormatter.format(topCategoryAmount)})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Chiếm $topCategoryPercent% trên tổng chi tiêu hiện tại',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 3. Category Donut Chart Section (CustomPainter)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biểu đồ phân bổ tỷ trọng (Donut Chart)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vẽ trực tiếp bằng CustomPainter (Không dùng thư viện bên thứ 3)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedDonutChart(
                    categoryBreakdown: provider.categoryBreakdown,
                    totalAmount: provider.totalSpending,
                    size: 240,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Weekly Spending Bar Chart Section (CustomPainter)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biểu đồ chi tiêu theo tuần (Bar Chart)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vẽ trực tiếp bằng CustomPainter (T2 - CN)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WeeklyBarChart(
                    dailySpendings: provider.weeklySpending,
                    height: 200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Category Details Breakdown List
            const Text(
              'Chi tiết từng nhóm danh mục',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...provider.categoryBreakdown.entries.map((entry) {
              final cat = ExpenseCategory.fromId(entry.key);
              final amount = entry.value;
              final percent = provider.totalSpending > 0
                  ? (amount / provider.totalSpending)
                  : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.nameVi,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              Text(
                                cat.nameEn,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${(percent * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cat.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframePill(
    BuildContext context, {
    required String title,
    required DateFilterOption option,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    return Expanded(
      child: InkWell(
        onTap: () => provider.setDateFilter(option),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkCard : AppColors.lightCardElevated),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
