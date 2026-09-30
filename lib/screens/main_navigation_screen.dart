import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'analytics_screen.dart';
import 'camera_scanner_screen.dart';
import 'dashboard_screen.dart';
import 'sample_receipts_screen.dart';
import 'transaction_history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigateTab: _onTabTapped),
      const TransactionHistoryScreen(),
      const AnalyticsScreen(),
      const SampleReceiptsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
          );
        },
        backgroundColor: AppColors.accent,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 0: Dashboard
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Tổng quan',
                index: 0,
              ),
              // Tab 1: History
              _buildNavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Lịch sử',
                index: 1,
              ),

              const SizedBox(width: 48), // Spacer for notched FAB

              // Tab 2: Analytics
              _buildNavItem(
                icon: Icons.pie_chart_rounded,
                label: 'Phân tích',
                index: 2,
              ),
              // Tab 3: Sample Receipts
              _buildNavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Mẫu OCR',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
