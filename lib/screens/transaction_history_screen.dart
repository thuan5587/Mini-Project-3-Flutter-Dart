import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/transaction_card.dart';
import 'camera_scanner_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chi tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Quét hóa đơn mới',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => provider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên cửa hàng, ghi chú...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Date Filter Tabs (Toàn bộ, Tuần này, Tháng này)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildDateFilterChip(
                  context,
                  title: 'Toàn bộ',
                  option: DateFilterOption.allTime,
                  isSelected: provider.selectedDateFilter == DateFilterOption.allTime,
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  context,
                  title: 'Tuần này',
                  option: DateFilterOption.thisWeek,
                  isSelected: provider.selectedDateFilter == DateFilterOption.thisWeek,
                ),
                const SizedBox(width: 8),
                _buildDateFilterChip(
                  context,
                  title: 'Tháng này',
                  option: DateFilterOption.thisMonth,
                  isSelected: provider.selectedDateFilter == DateFilterOption.thisMonth,
                ),
              ],
            ),
          ),

          // 3. Category Horizontal Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // "All" filter chip
                InkWell(
                  onTap: () => provider.setCategoryFilter('all'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: provider.selectedCategory == 'all'
                          ? AppColors.primary
                          : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: provider.selectedCategory == 'all'
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.allCategories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      category: cat,
                      isSelected: provider.selectedCategory == cat.id,
                      onTap: () => provider.setCategoryFilter(cat.id),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 4. Subtotal banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.transactions.length} giao dịch tìm thấy',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                Text(
                  'Tổng: ${currencyFormatter.format(provider.totalSpending)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          // 5. Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: provider.transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 54, color: AppColors.darkTextMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'Không tìm thấy giao dịch nào',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thử đổi bộ lọc hoặc quét thêm hóa đơn mới',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = provider.transactions[index];
                        return Dismissible(
                          key: Key('tx_${tx.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            provider.deleteTransaction(tx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã xóa "${tx.merchant}"'),
                                action: SnackBarAction(
                                  label: 'HOÀN TÁC',
                                  onPressed: () => provider.addTransaction(tx),
                                ),
                              ),
                            );
                          },
                          child: TransactionCard(
                            transaction: tx,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailScreen(transaction: tx),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(
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
                ? AppColors.primaryLight.withOpacity(0.2)
                : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryLight
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
