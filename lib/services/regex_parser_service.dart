import '../models/expense_category.dart';
import '../models/parsed_receipt.dart';

class RegexParserService {
  // Known merchants dictionary for high-precision recognition
  static const List<Map<String, dynamic>> knownMerchants = [
    {
      'name': 'Highlands Coffee',
      'category': 'food',
      'patterns': ['highlands', 'high lands', 'highland coffee'],
    },
    {
      'name': 'WinMart',
      'category': 'food',
      'patterns': ['winmart', 'winmart+', 'vinmart', 'vinmart+'],
    },
    {
      'name': 'Co.opmart',
      'category': 'food',
      'patterns': ['co.opmart', 'coopmart', 'co.op mart', 'coop mart', 'co.op'],
    },
    {
      'name': 'Bách Hóa Xanh',
      'category': 'food',
      'patterns': ['bach hoa xanh', 'bách hóa xanh', 'bhx'],
    },
    {
      'name': 'Circle K',
      'category': 'food',
      'patterns': ['circle k', 'circlek', 'circle-k'],
    },
    {
      'name': 'Phúc Long Coffee & Tea',
      'category': 'food',
      'patterns': ['phuc long', 'phúc long'],
    },
    {
      'name': 'The Coffee House',
      'category': 'food',
      'patterns': ['the coffee house', 'coffee house'],
    },
    {
      'name': 'Starbucks Coffee',
      'category': 'food',
      'patterns': ['starbucks'],
    },
    {
      'name': 'KFC Vietnam',
      'category': 'food',
      'patterns': ['kfc', 'kentucky fried'],
    },
    {
      'name': 'Lotteria',
      'category': 'food',
      'patterns': ['lotteria'],
    },
    {
      'name': 'Jollibee',
      'category': 'food',
      'patterns': ['jollibee'],
    },
    {
      'name': 'Pizza Hut',
      'category': 'food',
      'patterns': ['pizza hut'],
    },
    {
      'name': 'Fahasa Bookstore',
      'category': 'study',
      'patterns': ['fahasa', 'nha sach fahasa', 'nhà sách fahasa'],
    },
    {
      'name': 'Nhà sách Phương Nam',
      'category': 'study',
      'patterns': ['phuong nam', 'phương nam', 'nha sach phuong nam'],
    },
    {
      'name': 'Grab',
      'category': 'travel',
      'patterns': ['grab', 'grabcar', 'grabbike', 'grab ride'],
    },
    {
      'name': 'Xanh SM',
      'category': 'travel',
      'patterns': ['xanh sm', 'gsm', 'taxi xanh'],
    },
    {
      'name': 'Be Group',
      'category': 'travel',
      'patterns': ['be bike', 'be car', 'be group'],
    },
    {
      'name': 'Petrolimex',
      'category': 'travel',
      'patterns': ['petrolimex', 'cay xang', 'cửa hàng xăng dầu'],
    },
    {
      'name': 'Thế Giới Di Động',
      'category': 'gear',
      'patterns': ['the gioi di dong', 'thế giới di động', 'tgdd'],
    },
    {
      'name': 'FPT Shop',
      'category': 'gear',
      'patterns': ['fpt shop', 'fptshop', 'fpt retail'],
    },
    {
      'name': 'CellphoneS',
      'category': 'gear',
      'patterns': ['cellphones', 'cellphone s'],
    },
    {
      'name': 'CGV Cinemas',
      'category': 'entertainment',
      'patterns': ['cgv', 'cgv cinemas'],
    },
    {
      'name': 'Lotte Cinema',
      'category': 'entertainment',
      'patterns': ['lotte cinema'],
    },
  ];

  // Noise lines in header to filter out
  static final List<RegExp> noiseHeaderPatterns = [
    RegExp(r'hoa\s*don|hóa\s*đơn', caseSensitive: false),
    RegExp(r'phieu\s*thanh\s*toan|phiếu\s*thanh\s*toán', caseSensitive: false),
    RegExp(r'phieu\s*tinh\s*tien|phiếu\s*tính\s*tiền', caseSensitive: false),
    RegExp(r'vat\s*invoice|receipt|bill', caseSensitive: false),
    RegExp(r'chao\s*mung|chào\s*mừng|welcome', caseSensitive: false),
    RegExp(r'cam\s*on|cảm\s*ơn|thank\s*you', caseSensitive: false),
    RegExp(r'^(d\/c|đ\/c|dia\s*chi|địa\s*chỉ|address)', caseSensitive: false),
    RegExp(r'^(tel|hotline|dt|đt|mst|so\s*mst|ma\s*so\s*thue)', caseSensitive: false),
    RegExp(r'^\d+$'), // Just a number
    RegExp(r'^[=\-_*#\s]+$'), // Separator line
  ];

  /// Core parsing entry point
  static ParsedReceipt parse(String ocrRawText, {String? imagePath}) {
    final lines = ocrRawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ParsedReceipt(
        merchant: 'Hóa đơn chưa xác định',
        amount: 0.0,
        date: DateTime.now(),
        suggestedCategory: ExpenseCategory.fromId('other'),
        rawText: ocrRawText,
        confidence: 0.1,
        imagePath: imagePath,
      );
    }

    final merchantResult = extractMerchant(lines);
    final amountResult = extractAmount(lines);
    final dateResult = extractDate(lines);
    final lineItems = extractLineItems(lines);

    // Auto-detect category
    ExpenseCategory category;
    if (merchantResult.suggestedCategory != null) {
      category = ExpenseCategory.fromId(merchantResult.suggestedCategory!);
    } else {
      category = ExpenseCategory.matchFromText('$ocrRawText ${merchantResult.name}');
    }

    // Confidence calculation based on whether merchant, amount, date were detected
    double confidence = 0.5;
    if (merchantResult.confidence > 0.7) confidence += 0.2;
    if (amountResult > 0) confidence += 0.2;
    if (dateResult != null) confidence += 0.1;
    confidence = confidence.clamp(0.1, 0.99);

    return ParsedReceipt(
      merchant: merchantResult.name,
      amount: amountResult,
      date: dateResult ?? DateTime.now(),
      suggestedCategory: category,
      lineItems: lineItems,
      rawText: ocrRawText,
      confidence: confidence,
      imagePath: imagePath,
    );
  }

  /// 1. Extract Merchant Name
  static ({String name, String? suggestedCategory, double confidence}) extractMerchant(
    List<String> lines,
  ) {
    // A. Check against known merchant database first (case-insensitive substring)
    final topSearchLines = lines.take(6).toList();
    final combinedHeader = topSearchLines.join(' ').toLowerCase();

    for (final km in knownMerchants) {
      final patterns = km['patterns'] as List<String>;
      for (final p in patterns) {
        if (combinedHeader.contains(p)) {
          return (
            name: km['name'] as String,
            suggestedCategory: km['category'] as String?,
            confidence: 0.95,
          );
        }
      }
    }

    // B. Heuristic: inspect first 5 non-noise lines
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (isNoiseHeader(line)) continue;

      // Filter out phone numbers or tax IDs
      if (RegExp(r'0\d{9,10}').hasMatch(line)) continue;

      // Look for clean merchant line: length 3..40, letters present
      final clean = line.replaceAll(RegExp(r'[^\p{L}\p{N}\s&.-]', unicode: true), '').trim();
      if (clean.length >= 3 && clean.length <= 45) {
        return (
          name: clean,
          suggestedCategory: null,
          confidence: 0.75,
        );
      }
    }

    return (
      name: lines.first,
      suggestedCategory: null,
      confidence: 0.5,
    );
  }

  static bool isNoiseHeader(String line) {
    for (final pattern in noiseHeaderPatterns) {
      if (pattern.hasMatch(line)) return true;
    }
    return false;
  }

  /// 2. Extract Total Amount
  static double extractAmount(List<String> lines) {
    // Keywords indicating the final total
    final totalKeywords = [
      'tong cong', 'tổng cộng', 'thanh toan', 'thanh toán', 'tong tien',
      'tổng tiền', 'tong thanh toan', 'tổng thanh toán', 'khach phai tra',
      'khách phải trả', 'tien mat', 'tiền mặt', 'phai tra', 'phải trả',
      'cong tien hang', 'cộng tiền hàng', 'thanh tien', 'thành tiền',
      'total', 'grand total', 'amount due', 'net total', 'balance due'
    ];

    double? bestAmount;
    double highestScore = -1.0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // Check if line contains a total keyword
      bool hasKeyword = false;
      for (final kw in totalKeywords) {
        if (lineLower.contains(kw)) {
          hasKeyword = true;
          break;
        }
      }

      // Check numbers on current line
      final amountsOnLine = parseMonetaryNumbers(line);
      if (amountsOnLine.isNotEmpty) {
        for (final numVal in amountsOnLine) {
          double score = 0;
          if (hasKeyword) {
            score = 100.0;
            // Prefer numbers >= 1000 for VND
            if (numVal >= 1000) score += 20;
          } else {
            // Position bias: lines in the second half of receipt are more likely totals
            final relativePos = i / lines.length;
            score = relativePos * 40.0;
          }

          if (score > highestScore) {
            highestScore = score;
            bestAmount = numVal;
          }
        }
      } else if (hasKeyword && i + 1 < lines.length) {
        // Keyword on current line, number on next line (e.g., "TỔNG CỘNG:\n150.000")
        final nextLineAmounts = parseMonetaryNumbers(lines[i + 1]);
        if (nextLineAmounts.isNotEmpty) {
          final numVal = nextLineAmounts.first;
          final score = 90.0 + (numVal >= 1000 ? 20 : 0);
          if (score > highestScore) {
            highestScore = score;
            bestAmount = numVal;
          }
        }
      }
    }

    if (bestAmount != null && bestAmount > 0) {
      return bestAmount;
    }

    // Fallback: search for maximum reasonable number in the receipt
    double maxNum = 0.0;
    for (final line in lines) {
      final nums = parseMonetaryNumbers(line);
      for (final n in nums) {
        // Avoid phone numbers, tax ids (> 1,000,000,000) or tiny numbers
        if (n > maxNum && n < 500000000) {
          maxNum = n;
        }
      }
    }

    return maxNum;
  }

  /// Parses monetary amounts from string, handling Vietnamese '.' or ',' separators and 'k' shorthand
  static List<double> parseMonetaryNumbers(String line) {
    final results = <double>[];

    // Filter out obvious phone numbers (10 digits starting with 0)
    final lineFiltered = line.replaceAll(RegExp(r'\b0\d{9}\b'), '');

    // Pattern 1: Shorthand like "150k", "150K", "150 k"
    final kMatches = RegExp(r'\b(\d+(?:[.,]\d+)?)\s*[kK]\b').allMatches(lineFiltered);
    for (final m in kMatches) {
      final raw = m.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(raw);
      if (val != null) {
        results.add(val * 1000);
      }
    }

    // Pattern 2: Vietnamese currency: 150.000 or 150,000 or 1.500.000 (with optional đ, VND, vnđ)
    // Matches e.g., 150.000đ, 150,000 VND, 150 000
    final vnCurrencyPattern = RegExp(
      r'(?:^|[^\d])(\d{1,3}(?:[.,\s]\d{3})+(?:[.,]\d{2})?)\s*(?:đ|vnd|vnđ|d)?(?=[^\d]|$)',
      caseSensitive: false,
    );

    final vnMatches = vnCurrencyPattern.allMatches(lineFiltered);
    for (final m in vnMatches) {
      final rawNum = m.group(1)!;
      final parsed = cleanCurrencyString(rawNum);
      if (parsed != null && parsed > 0) {
        results.add(parsed);
      }
    }

    // Pattern 3: Standard decimal or integer numbers e.g. 50000 or 45.50
    final plainNumPattern = RegExp(
      r'(?:^|[^\d])(\d{4,9})(?:\.00)?\s*(?:đ|vnd|vnđ)?(?=[^\d]|$)',
      caseSensitive: false,
    );
    for (final m in plainNumPattern.allMatches(lineFiltered)) {
      final val = double.tryParse(m.group(1)!);
      if (val != null && val > 0) {
        results.add(val);
      }
    }

    return results;
  }

  static double? cleanCurrencyString(String raw) {
    var cleaned = raw.trim();
    // Count occurrences of '.' and ','
    final dotCount = '.'.allMatches(cleaned).length;
    final commaCount = ','.allMatches(cleaned).length;

    if (dotCount > 0 && commaCount == 0) {
      // Typically Vietnamese thousands separator: "150.000" or "1.500.000"
      cleaned = cleaned.replaceAll('.', '');
    } else if (commaCount > 0 && dotCount == 0) {
      // Could be English thousands: "150,000"
      cleaned = cleaned.replaceAll(',', '');
    } else if (dotCount > 0 && commaCount > 0) {
      // Mixed e.g. "1,500.00" or "1.500,00"
      if (cleaned.lastIndexOf('.') > cleaned.lastIndexOf(',')) {
        // 1,500.50 -> remove commas
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // 1.500,50 -> remove dots, replace comma with dot
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    }
    // Remove whitespace
    cleaned = cleaned.replaceAll(' ', '');

    return double.tryParse(cleaned);
  }

  /// 3. Extract Transaction Date & Time
  static DateTime? extractDate(List<String> lines) {
    // Regex for date patterns: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, YYYY-MM-DD
    final dmyRegex = RegExp(r'\b([0-2]?\d|3[01])[\/\-\.](0?\d|1[0-2])[\/\-\.](20\d{2})\b');
    final ymdRegex = RegExp(r'\b(20\d{2})[\/\-\.](0?\d|1[0-2])[\/\-\.]([0-2]?\d|3[01])\b');
    final timeRegex = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b');

    DateTime? parsedDate;
    int hour = 12;
    int minute = 0;
    int second = 0;

    // Scan for time first or along the way
    for (final line in lines) {
      final timeMatch = timeRegex.firstMatch(line);
      if (timeMatch != null) {
        hour = int.tryParse(timeMatch.group(1)!) ?? hour;
        minute = int.tryParse(timeMatch.group(2)!) ?? minute;
        if (timeMatch.group(3) != null) {
          second = int.tryParse(timeMatch.group(3)!) ?? 0;
        }
      }

      // Check DMY
      final dmyMatch = dmyRegex.firstMatch(line);
      if (dmyMatch != null) {
        final day = int.tryParse(dmyMatch.group(1)!);
        final month = int.tryParse(dmyMatch.group(2)!);
        final year = int.tryParse(dmyMatch.group(3)!);
        if (day != null && month != null && year != null) {
          try {
            parsedDate = DateTime(year, month, day, hour, minute, second);
            break;
          } catch (_) {}
        }
      }

      // Check YMD
      final ymdMatch = ymdRegex.firstMatch(line);
      if (ymdMatch != null) {
        final year = int.tryParse(ymdMatch.group(1)!);
        final month = int.tryParse(ymdMatch.group(2)!);
        final day = int.tryParse(ymdMatch.group(3)!);
        if (day != null && month != null && year != null) {
          try {
            parsedDate = DateTime(year, month, day, hour, minute, second);
            break;
          } catch (_) {}
        }
      }
    }

    return parsedDate;
  }

  /// 4. Extract Line Items (optional heuristic)
  static List<ReceiptLineItem> extractLineItems(List<String> lines) {
    final items = <ReceiptLineItem>[];
    // Line pattern matching: <Text> <Number> (e.g. "Caphe sua da 35.000")
    final itemPattern = RegExp(r'^(.+?)\s+(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:đ|vnd)?$', caseSensitive: false);

    for (final line in lines) {
      if (isNoiseHeader(line)) continue;
      if (line.toLowerCase().contains('tong') || line.toLowerCase().contains('total')) continue;

      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final desc = match.group(1)!.trim();
        final rawPrice = match.group(2)!;
        final price = cleanCurrencyString(rawPrice);
        if (price != null && price >= 1000 && desc.length >= 3 && !RegExp(r'^\d+$').hasMatch(desc)) {
          items.add(ReceiptLineItem(
            description: desc,
            totalPrice: price,
          ));
        }
      }
    }

    return items;
  }
}
