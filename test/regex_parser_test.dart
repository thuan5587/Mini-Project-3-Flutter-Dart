import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense_category.dart';
import 'package:ocr_expense_tracker/services/regex_parser_service.dart';

void main() {
  group('RegexParserService Currency Extraction Tests', () {
    test('Should parse Vietnamese dot thousands separator "113.000 đ"', () {
      const receipt = '''
HIGHLANDS COFFEE
Ngay: 28/09/2026 08:45
1. Phin sua da 39.000
2. Freeze tra xanh 55.000
TONG CONG: 113.000 đ
TIEN MAT: 120.000
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.amount, equals(113000.0));
      expect(parsed.merchant, equals('Highlands Coffee'));
      expect(parsed.suggestedCategory.type, equals(ExpenseCategoryType.food));
    });

    test('Should parse comma thousands separator "99,360 VND"', () {
      const receipt = '''
WINMART CONG HOA
Hoa don ban le
Date: 29/09/2026
TỔNG THANH TOÁN: 99,360 VND
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.amount, equals(99360.0));
      expect(parsed.merchant, equals('WinMart'));
    });

    test('Should parse "k" notation "150k"', () {
      const receipt = '''
QUAN AN GIA DINH
Ngay 25/09/2026
Tong cong: 150k
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.amount, equals(150000.0));
    });

    test('Should ignore phone numbers and tax codes when extracting total', () {
      const receipt = '''
CUA HANG TIEN LOI
MST: 0312345678
Hotline: 0909123456
Ngay: 20/09/2026
TONG TIEN: 45.000 VND
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.amount, equals(45000.0));
      expect(parsed.amount, isNot(equals(312345678.0)));
      expect(parsed.amount, isNot(equals(909123456.0)));
    });
  });

  group('RegexParserService Date Extraction Tests', () {
    test('Should parse DD/MM/YYYY with HH:mm time', () {
      const receipt = '''
FAHASA BOOKSTORE
Ngay: 27/09/2026 15:20
TONG TIEN: 217.000 VND
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.date.year, equals(2026));
      expect(parsed.date.month, equals(9));
      expect(parsed.date.day, equals(27));
      expect(parsed.date.hour, equals(15));
      expect(parsed.date.minute, equals(20));
      expect(parsed.suggestedCategory.type, equals(ExpenseCategoryType.study));
    });

    test('Should parse YYYY-MM-DD format', () {
      const receipt = '''
GRAB VIETNAM
Date: 2026-09-26 07:30
TONG CONG: 63.000 đ
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.date.year, equals(2026));
      expect(parsed.date.month, equals(9));
      expect(parsed.date.day, equals(26));
      expect(parsed.suggestedCategory.type, equals(ExpenseCategoryType.travel));
    });
  });

  group('RegexParserService Merchant & Category Matching Tests', () {
    test('Should correctly identify Thế Giới Di Động and Gear category', () {
      const receipt = '''
THE GIOI DI DONG
Hoa don ban le
PHAI TRA: 350.000 đ
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.merchant, equals('Thế Giới Di Động'));
      expect(parsed.suggestedCategory.type, equals(ExpenseCategoryType.gear));
    });

    test('Should filter noise headers like "HÓA ĐƠN BÁN HÀNG" and pick real store name', () {
      const receipt = '''
HOA DON BAN HANG
PHIẾU THANH TOÁN
PHUC LONG COFFEE & TEA
TONG TIEN: 75.000 đ
''';
      final parsed = RegexParserService.parse(receipt);
      expect(parsed.merchant, equals('Phúc Long Coffee & Tea'));
      expect(parsed.amount, equals(75000.0));
      expect(parsed.suggestedCategory.type, equals(ExpenseCategoryType.food));
    });
  });
}
