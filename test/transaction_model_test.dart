import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense_category.dart';
import 'package:ocr_expense_tracker/models/expense_transaction.dart';

void main() {
  group('ExpenseTransaction Model Tests', () {
    test('Should serialize to map and deserialize from map correctly', () {
      final tx = ExpenseTransaction(
        id: 1,
        merchant: 'WinMart Cộng Hòa',
        amount: 99360.0,
        date: DateTime(2026, 9, 29, 17, 15),
        categoryId: 'food',
        notes: 'Sữa tươi và mì gói',
        rawOcrText: 'WINMART CONG HOA\nTONG CONG: 99.360 VND',
        imagePath: '/data/receipt_1.jpg',
        thumbnailPath: '/data/thumb_1.jpg',
      );

      final map = tx.toMap();
      expect(map['id'], equals(1));
      expect(map['merchant'], equals('WinMart Cộng Hòa'));
      expect(map['amount'], equals(99360.0));
      expect(map['category_id'], equals('food'));
      expect(map['notes'], equals('Sữa tươi và mì gói'));

      final restored = ExpenseTransaction.fromMap(map);
      expect(restored.id, equals(tx.id));
      expect(restored.merchant, equals(tx.merchant));
      expect(restored.amount, equals(tx.amount));
      expect(restored.date, equals(tx.date));
      expect(restored.category.type, equals(ExpenseCategoryType.food));
    });

    test('Should format currency with Vietnamese Dong symbol ₫', () {
      final tx = ExpenseTransaction(
        merchant: 'Highlands Coffee',
        amount: 113000.0,
        date: DateTime.now(),
        categoryId: 'food',
      );

      expect(tx.formattedAmount, contains('113.000'));
      expect(tx.formattedAmount, contains('₫'));
    });
  });
}
