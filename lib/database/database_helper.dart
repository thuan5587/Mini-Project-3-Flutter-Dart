import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/expense_transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ocr_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // If running on desktop platforms (Windows, Linux, macOS), initialize FFI
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationDocumentsDirectory();
      dbPath = join(docDir.path, 'ocr_expense_tracker', filePath);
      final dir = Directory(dirname(dbPath));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = join(databasesPath, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id TEXT NOT NULL,
        notes TEXT,
        raw_ocr_text TEXT,
        image_path TEXT,
        thumbnail_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category_id)',
    );
  }

  // Insert
  Future<int> insertTransaction(ExpenseTransaction transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get single transaction
  Future<ExpenseTransaction?> getTransactionById(int id) async {
    final db = await database;
    final results = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return ExpenseTransaction.fromMap(results.first);
    }
    return null;
  }

  // Get transactions with flexible filtering
  Future<List<ExpenseTransaction>> getTransactions({
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(merchant LIKE ? OR notes LIKE ?)');
      final queryParam = '%${searchQuery.trim()}%';
      whereArgs.add(queryParam);
      whereArgs.add(queryParam);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      'transactions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );

    return result.map((map) => ExpenseTransaction.fromMap(map)).toList();
  }

  // Update
  Future<int> updateTransaction(ExpenseTransaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Total spending in date range
  Future<double> getTotalSpending({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String sql = 'SELECT SUM(amount) as total FROM transactions';
    List<dynamic> args = [];
    List<String> conditions = [];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ' + conditions.join(' AND ');
    }

    final result = await db.rawQuery(sql, args);
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Category breakdown for Donut Chart
  Future<Map<String, double>> getCategoryBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String sql = '''
      SELECT category_id, SUM(amount) as total 
      FROM transactions
    ''';
    List<dynamic> args = [];
    List<String> conditions = [];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ' + conditions.join(' AND ');
    }

    sql += ' GROUP BY category_id ORDER BY total DESC';

    final result = await db.rawQuery(sql, args);
    final map = <String, double>{};
    for (final row in result) {
      final catId = row['category_id'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      map[catId] = total;
    }
    return map;
  }

  // Weekly spending breakdown for Bar Chart (last 7 days from today)
  Future<List<DailySpending>> getWeeklySpending() async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DailySpending>[];

    // Compute last 7 days starting from 6 days ago up to today
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final result = await db.rawQuery(
        '''
        SELECT SUM(amount) as total, COUNT(id) as count
        FROM transactions
        WHERE date >= ? AND date < ?
        ''',
        [date.toIso8601String(), nextDate.toIso8601String()],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      final count = (result.first['count'] as int?) ?? 0;

      days.add(DailySpending(
        date: date,
        amount: total,
        transactionCount: count,
      ));
    }

    return days;
  }

  // Clear all for demo reset
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

class DailySpending {
  final DateTime date;
  final double amount;
  final int transactionCount;

  DailySpending({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}
