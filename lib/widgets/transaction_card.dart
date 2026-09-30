import 'dart:io';
import 'package:flutter/material.dart';
import '../models/expense_transaction.dart';
import '../theme/app_colors.dart';

class TransactionCard extends StatelessWidget {
  final ExpenseTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = transaction.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category Icon or Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: transaction.thumbnailPath != null &&
                          File(transaction.thumbnailPath!).existsSync()
                      ? Image.file(
                          File(transaction.thumbnailPath!),
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 24,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Merchant & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.nameVi,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: category.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            transaction.formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${transaction.formattedAmount}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    if (transaction.rawOcrText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.document_scanner_rounded,
                              size: 11,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'OCR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
