import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../models/expense_transaction.dart';
import '../models/parsed_receipt.dart';
import '../providers/expense_provider.dart';
import '../services/receipt_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';

class ReceiptReviewScreen extends StatefulWidget {
  final ParsedReceipt parsedReceipt;
  final String? capturedImagePath;

  const ReceiptReviewScreen({
    super.key,
    required this.parsedReceipt,
    this.capturedImagePath,
  });

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ExpenseCategory _selectedCategory;

  bool _isSaving = false;
  bool _showRawOcr = false;

  @override
  void initState() {
    super.initState();
    final p = widget.parsedReceipt;
    _merchantController = TextEditingController(text: p.merchant);
    _amountController = TextEditingController(
      text: p.amount > 0 ? p.amount.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(
      text: p.lineItems.isNotEmpty
          ? p.lineItems.map((i) => '${i.description} (${NumberFormat.compact().format(i.totalPrice)})').join(', ')
          : '',
    );
    _selectedDate = p.date;
    _selectedTime = TimeOfDay.fromDateTime(p.date);
    _selectedCategory = p.suggestedCategory;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      String? fullImagePath = widget.capturedImagePath;
      String? thumbPath;

      // If an image was captured, save with thumbnail
      if (widget.capturedImagePath != null && File(widget.capturedImagePath!).existsSync()) {
        final saved = await ReceiptStorageService.saveReceiptWithThumbnail(
          File(widget.capturedImagePath!),
        );
        fullImagePath = saved.fullImagePath;
        thumbPath = saved.thumbnailPath;
      }

      final transaction = ExpenseTransaction(
        merchant: _merchantController.text.trim(),
        amount: amount,
        date: fullDateTime,
        categoryId: _selectedCategory.id,
        notes: _notesController.text.trim(),
        rawOcrText: widget.parsedReceipt.rawText,
        imagePath: fullImagePath,
        thumbnailPath: thumbPath,
      );

      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      await provider.addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Đã lưu chi tiêu: ${_merchantController.text}'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận hóa đơn OCR'),
        actions: [
          IconButton(
            tooltip: 'Xem văn bản gốc OCR',
            icon: Icon(
              _showRawOcr ? Icons.text_snippet : Icons.text_snippet_outlined,
              color: AppColors.accent,
            ),
            onPressed: () => setState(() => _showRawOcr = !_showRawOcr),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confidence indicator card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Google ML Kit + Regex Heuristic',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                                Text(
                                  'Độ tin cậy trích xuất: ${(widget.parsedReceipt.confidence * 100).toInt()}% • Vui lòng kiểm tra lại trước khi lưu',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Receipt Image preview (if present)
                    if (widget.capturedImagePath != null &&
                        File(widget.capturedImagePath!).existsSync())
                      Container(
                        height: 140,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(widget.capturedImagePath!),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Ảnh đã cắt theo khung',
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Merchant Field
                    const Text(
                      'Tên cửa hàng / Đơn vị bán lẻ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập hoặc chỉnh sửa tên cửa hàng',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập tên cửa hàng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Total Amount Field
                    const Text(
                      'Số tiền thanh toán (VNĐ)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: 150000',
                        prefixIcon: Icon(Icons.payments_rounded, color: AppColors.error),
                        suffixText: '₫',
                        suffixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        final num = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
                        if (num == null || num <= 0) {
                          return 'Số tiền không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date & Time pickers
                    const Text(
                      'Thời gian giao dịch',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTime.format(context),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    const Text(
                      'Phân loại danh mục',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.allCategories.map((cat) {
                        return CategoryChip(
                          category: cat,
                          isSelected: _selectedCategory.id == cat.id,
                          onTap: () => setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Notes / Line items
                    const Text(
                      'Ghi chú / Các mặt hàng trích xuất',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Nhập ghi chú hoặc chỉnh sửa danh mục món...',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Raw OCR Text Inspector (Collapsible)
                    if (_showRawOcr) ...[
                      const Text(
                        'Văn bản thô từ Google ML Kit OCR:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: SelectableText(
                          widget.parsedReceipt.rawText.isNotEmpty
                              ? widget.parsedReceipt.rawText
                              : '(Không có văn bản nào được nhận diện)',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Hủy bỏ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _saveTransaction,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Lưu vào sổ chi tiêu'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
