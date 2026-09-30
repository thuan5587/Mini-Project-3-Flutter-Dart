import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/charts/animated_donut_chart.dart';
import '../widgets/charts/weekly_bar_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import 'camera_scanner_screen.dart';
import 'sample_receipts_screen.dart';
import 'transaction_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    if (expenseProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalSpentFormatted = currencyFormatter.format(expenseProvider.totalSpending);
    final transactionCount = expenseProvider.transactions.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sổ Chi Tiêu OCR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const Text(
              'On-Device AI Receipt Parser',
              style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.primary,
            ),
            tooltip: 'Chuyển chế độ sáng/tối',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'seed') {
                await expenseProvider.seedDemoData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã nạp lại dữ liệu mẫu thành công')),
                );
              } else if (value == 'clear') {
                await expenseProvider.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu')),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Nạp lại dữ liệu mẫu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Xóa sạch database'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => expenseProvider.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Overview Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'TỔNG CHI TIÊU',
                      value: totalSpentFormatted,
                      subtitle: '$transactionCount giao dịch',
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'QUÉT HÓA ĐƠN',
                      value: '$transactionCount',
                      subtitle: 'Offline ML Kit',
                      icon: Icons.document_scanner_rounded,
                      accentColor: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
                        );
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Quét Hóa Đơn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SampleReceiptsScreen()),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, color: AppColors.accent),
                      label: const Text('Hóa Đơn Mẫu', style: TextStyle(color: AppColors.accent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Animated Weekly Spending Bar Chart Card (CustomPainter)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chi tiêu 7 ngày gần nhất',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CustomPainter Bar Chart (No 3rd-party lib)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Tuần này',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    WeeklyBarChart(
                      dailySpendings: expenseProvider.weeklySpending,
                      height: 180,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Chạm vào từng cột để xem chi tiết số tiền của ngày',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Animated Category Donut Chart Card (CustomPainter)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phân bổ chi tiêu theo danh mục',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CustomPainter Donut Chart (No 3rd-party lib)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onPressed: () => onNavigateTab(2), // Go to Analytics
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedDonutChart(
                      categoryBreakdown: expenseProvider.categoryBreakdown,
                      totalAmount: expenseProvider.totalSpending,
                      size: 220,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Giao dịch gần đây',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab(1), // Go to History tab
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (expenseProvider.transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.darkTextMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có giao dịch nào.\nHãy quét hóa đơn đầu tiên của bạn!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.darkTextMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...expenseProvider.transactions.take(5).map((tx) {
                  return TransactionCard(
                    transaction: tx,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(transaction: tx),
                        ),
                      );
                    },
                  );
                }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
