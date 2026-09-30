import 'package:flutter/material.dart';

enum ExpenseCategoryType {
  food,
  study,
  travel,
  gear,
  entertainment,
  other,
}

class ExpenseCategory {
  final ExpenseCategoryType type;
  final String id;
  final String nameVi;
  final String nameEn;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const ExpenseCategory({
    required this.type,
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.keywords,
  });

  static const List<ExpenseCategory> allCategories = [
    ExpenseCategory(
      type: ExpenseCategoryType.food,
      id: 'food',
      nameVi: 'Ăn uống',
      nameEn: 'Food & Drinks',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFEF4444), // Coral Red
      keywords: [
        'food', 'restaurant', 'coffee', 'cafe', 'highlands', 'phuc long',
        'starbucks', 'kfc', 'lotteria', 'mcdonald', 'pizza', 'tra sua',
        'com', 'pho', 'bun', 'lau', 'an uong', 'winmart', 'co.opmart',
        'coopmart', 'bach hoa xanh', 'circle k', '7-eleven', 'ministop',
        'gs25', 'market', 'sieu thi', 'banh mi', 'thuc pham', 'shopeefood',
        'baemin', 'grabfood'
      ],
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.study,
      id: 'study',
      nameVi: 'Học tập',
      nameEn: 'Study & Education',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF3B82F6), // Ocean Blue
      keywords: [
        'study', 'book', 'sach', 'nha sach', 'fahasa', 'phuong nam',
        'tien phong', 'van phong pham', 'but', 'vo', 'tap', 'giao trinh',
        'in an', 'photocopy', 'hoc phi', 'course', 'khoa hoc', 'udemy',
        'coursera', 'ielts', 'toiec', 'library'
      ],
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.travel,
      id: 'travel',
      nameVi: 'Di chuyển',
      nameEn: 'Travel & Transport',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF10B981), // Emerald Green
      keywords: [
        'travel', 'grab', 'be', 'gojek', 'xanh sm', 'taxi', 'mai linh',
        'vinasun', 'xang', 'petrolimex', 'gui xe', 've xe', 'xe bus',
        'tau hoa', 'may bay', 'vietjet', 'vietnam airlines', 've cau duong',
        'phi duong bo', 'parking', 'fuel'
      ],
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.gear,
      id: 'gear',
      nameVi: 'Thiết bị',
      nameEn: 'Tech & Gear',
      icon: Icons.devices_rounded,
      color: Color(0xFF8B5CF6), // Royal Purple
      keywords: [
        'gear', 'tech', 'the gioi di dong', 'fpt shop', 'cellphones',
        'hoang ha', 'phong vu', 'laptop', 'chuot', 'ban phim', 'tai nghe',
        'sac', 'cap', 'usb', 'may tinh', 'dien thoai', 'phu kien',
        'hardware', 'apple', 'samsung', 'xiaomi', 'asus'
      ],
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.entertainment,
      id: 'entertainment',
      nameVi: 'Giải trí',
      nameEn: 'Entertainment',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFF59E0B), // Amber Orange
      keywords: [
        'entertainment', 'cgv', 'lotte cinema', 'bhd', 'galaxy cinema',
        'rap chieu phim', 'karaoke', 'billiards', 'bida', 'bowling',
        'game', 'gaming', 'net', 'cyber', 'netflix', 'spotify', 'youtube',
        've xem phim', 'boardgame', 'khu vui choi'
      ],
    ),
    ExpenseCategory(
      type: ExpenseCategoryType.other,
      id: 'other',
      nameVi: 'Khác',
      nameEn: 'Other Expense',
      icon: Icons.category_rounded,
      color: Color(0xFF6B7280), // Slate Grey
      keywords: [],
    ),
  ];

  static ExpenseCategory fromId(String id) {
    return allCategories.firstWhere(
      (c) => c.id.toLowerCase() == id.toLowerCase(),
      orElse: () => allCategories.last,
    );
  }

  static ExpenseCategory matchFromText(String text) {
    final lower = text.toLowerCase();
    for (final cat in allCategories) {
      if (cat.type == ExpenseCategoryType.other) continue;
      for (final kw in cat.keywords) {
        if (lower.contains(kw)) {
          return cat;
        }
      }
    }
    return allCategories.firstWhere((c) => c.type == ExpenseCategoryType.food);
  }
}
