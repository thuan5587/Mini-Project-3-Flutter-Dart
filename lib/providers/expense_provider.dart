import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense_transaction.dart';
import '../services/mock_data_service.dart';
import '../services/receipt_storage_service.dart';

enum DateFilterOption {
  allTime,
  thisWeek,
  thisMonth,
}

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<ExpenseTransaction> _transactions = [];
  Map<String, double> _categoryBreakdown = {};
  List<DailySpending> _weeklySpending = [];
  double _totalSpending = 0.0;

  bool _isLoading = true;
  String _selectedCategory = 'all';
  DateFilterOption _selectedDateFilter = DateFilterOption.allTime;
  String _searchQuery = '';

  // Getters
  List<ExpenseTransaction> get transactions => _transactions;
  Map<String, double> get categoryBreakdown => _categoryBreakdown;
  List<DailySpending> get weeklySpending => _weeklySpending;
  double get totalSpending => _totalSpending;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  DateFilterOption get selectedDateFilter => _selectedDateFilter;
  String get searchQuery => _searchQuery;

  ExpenseProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await MockDataService.seedInitialDataIfEmpty(_db);
      await refresh();
    } catch (e) {
      debugPrint('Error initializing expense provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    DateTime? startDate;
    final now = DateTime.now();

    if (_selectedDateFilter == DateFilterOption.thisWeek) {
      // Start of current week (Monday)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(monday.year, monday.month, monday.day);
    } else if (_selectedDateFilter == DateFilterOption.thisMonth) {
      startDate = DateTime(now.year, now.month, 1);
    }

    _transactions = await _db.getTransactions(
      categoryId: _selectedCategory,
      startDate: startDate,
      searchQuery: _searchQuery,
    );

    _totalSpending = await _db.getTotalSpending(startDate: startDate);
    _categoryBreakdown = await _db.getCategoryBreakdown(startDate: startDate);
    _weeklySpending = await _db.getWeeklySpending();

    notifyListeners();
  }

  Future<int> addTransaction(ExpenseTransaction transaction) async {
    final id = await _db.insertTransaction(transaction);
    await refresh();
    return id;
  }

  Future<void> updateTransaction(ExpenseTransaction transaction) async {
    await _db.updateTransaction(transaction);
    await refresh();
  }

  Future<void> deleteTransaction(ExpenseTransaction transaction) async {
    if (transaction.id != null) {
      await _db.deleteTransaction(transaction.id!);
      // Also cleanup local files
      await ReceiptStorageService.deleteReceiptFiles(
        fullPath: transaction.imagePath,
        thumbPath: transaction.thumbnailPath,
      );
      await refresh();
    }
  }

  void setCategoryFilter(String categoryId) {
    if (_selectedCategory == categoryId) return;
    _selectedCategory = categoryId;
    refresh();
  }

  void setDateFilter(DateFilterOption option) {
    if (_selectedDateFilter == option) return;
    _selectedDateFilter = option;
    refresh();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    refresh();
  }

  Future<void> seedDemoData() async {
    _isLoading = true;
    notifyListeners();

    await _db.clearAll();
    await MockDataService.seedInitialDataIfEmpty(_db);
    await refresh();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();

    await _db.clearAll();
    await refresh();

    _isLoading = false;
    notifyListeners();
  }
}
