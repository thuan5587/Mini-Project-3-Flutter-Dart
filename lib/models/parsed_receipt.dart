import 'expense_category.dart';

class ReceiptLineItem {
  final String description;
  final double? quantity;
  final double? unitPrice;
  final double totalPrice;

  const ReceiptLineItem({
    required this.description,
    this.quantity,
    this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() => {
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
  };
}

class ParsedReceipt {
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory suggestedCategory;
  final List<ReceiptLineItem> lineItems;
  final String rawText;
  final double confidence; // 0.0 to 1.0
  final String? imagePath;

  const ParsedReceipt({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.suggestedCategory,
    this.lineItems = const [],
    required this.rawText,
    this.confidence = 0.85,
    this.imagePath,
  });

  ParsedReceipt copyWith({
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? suggestedCategory,
    List<ReceiptLineItem>? lineItems,
    String? rawText,
    double? confidence,
    String? imagePath,
  }) {
    return ParsedReceipt(
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      lineItems: lineItems ?? this.lineItems,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
