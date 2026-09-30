import 'package:intl/intl.dart';
import 'expense_category.dart';

class ExpenseTransaction {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String notes;
  final String? rawOcrText;
  final String? imagePath;
  final String? thumbnailPath;
  final DateTime createdAt;

  ExpenseTransaction({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.notes = '',
    this.rawOcrText,
    this.imagePath,
    this.thumbnailPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ExpenseCategory get category => ExpenseCategory.fromId(categoryId);

  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get formattedDateTime {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'notes': notes,
      'raw_ocr_text': rawOcrText,
      'image_path': imagePath,
      'thumbnail_path': thumbnailPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Chưa rõ',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      categoryId: map['category_id'] as String? ?? 'other',
      notes: map['notes'] as String? ?? '',
      rawOcrText: map['raw_ocr_text'] as String?,
      imagePath: map['image_path'] as String?,
      thumbnailPath: map['thumbnail_path'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  ExpenseTransaction copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? notes,
    String? rawOcrText,
    String? imagePath,
    String? thumbnailPath,
    DateTime? createdAt,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
