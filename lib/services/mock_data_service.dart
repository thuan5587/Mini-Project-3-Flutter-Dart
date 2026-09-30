import '../database/database_helper.dart';
import '../models/expense_transaction.dart';

class SampleReceiptItem {
  final String title;
  final String merchant;
  final String categoryId;
  final double expectedAmount;
  final String rawOcrText;
  final String notes;

  const SampleReceiptItem({
    required this.title,
    required this.merchant,
    required this.categoryId,
    required this.expectedAmount,
    required this.rawOcrText,
    required this.notes,
  });
}

class MockDataService {
  static const List<SampleReceiptItem> sampleReceipts = [
    SampleReceiptItem(
      title: 'Highlands Coffee - Cà phê sáng',
      merchant: 'Highlands Coffee',
      categoryId: 'food',
      expectedAmount: 113000,
      notes: 'Hóa đơn uống nước với bạn nhóm',
      rawOcrText: '''
HIGHLANDS COFFEE
Chi Nhanh 72 Le Duan, Da Nang
HD: 0048291  Thu ngan: Tram
Ngay: 28/09/2026  08:45
--------------------------------
1. Phin Sua Da (L)        39.000
2. Freeze Tra Xanh (M)    55.000
3. Banh Mi Que Ga         19.000
--------------------------------
TONG CONG:               113.000 đ
TIEN MAT:                120.000
TIEN THUA:                 7.000
Cam on Quy khach & Hen gap lai!
''',
    ),
    SampleReceiptItem(
      title: 'WinMart - Mua sắm thực phẩm',
      merchant: 'WinMart',
      categoryId: 'food',
      expectedAmount: 99360,
      notes: 'Mua đồ ăn tuần mới',
      rawOcrText: '''
WINMART CONG HOA
Sieu Thi WinMart Cong Hoa - TP.HCM
HD: 921048  Thu ngan: Mai Lan
Ngay in: 29/09/2026  17:15
--------------------------------
Sua tuoi Vinamilk 1L      36.500
Mi Omachi Bo Sot Vang     10.500
Nuoc ngot Coca Cola       11.000
Snack Oishi Tom Cay       12.000
Banh mi Sandwich          22.000
--------------------------------
Cong tien hang:           92.000
VAT (8%):                  7.360
TONG CONG:                99.360 VND
Tien khach dua:          100.000
Tien tra lai:                640
''',
    ),
    SampleReceiptItem(
      title: 'Nhà sách Fahasa - Giáo trình',
      merchant: 'Fahasa Bookstore',
      categoryId: 'study',
      expectedAmount: 217000,
      notes: 'Giáo trình Flutter và sổ ghi chép',
      rawOcrText: '''
NHA SACH FAHASA
Nha Sach Da Nang - 300 Bach Dang
Phieu Thanh Toan #88412
Date: 27/09/2026 15:20
--------------------------------
1. So Tay Kepper A5       45.000
2. But Bi Gel Pentel      32.000
3. Giao Trinh Flutter    140.000
--------------------------------
TONG TIEN:               217.000 VND
Thanh toan: The ATM
Xin cam on va hen gap lai!
''',
    ),
    SampleReceiptItem(
      title: 'GrabCar - Đi học đồ án',
      merchant: 'Grab',
      categoryId: 'travel',
      expectedAmount: 63000,
      notes: 'Trời mưa đi taxi đến trường',
      rawOcrText: '''
GRAB VIETNAM
Hoa Don Dien Tu / e-Receipt
Ngay: 26/09/2026 07:30
Dich vu: GrabCar 4 cho
Diem don: KTX Dai Hoc
Diem den: VKU Campus
--------------------------------
Cuoc phi chuyen di:       68.000
Phi cau duong:            10.000
Giam gia khuyen mai:     -15.000
--------------------------------
TONG THANH TOAN:          63.000 đ
Phuong thuc: MoMo
''',
    ),
    SampleReceiptItem(
      title: 'Thế Giới Di Động - Phụ kiện',
      merchant: 'Thế Giới Di Động',
      categoryId: 'gear',
      expectedAmount: 350000,
      notes: 'Cáp sạc Type-C và chuột không dây',
      rawOcrText: '''
CONG TY CP THE GIOI DI DONG
Sieu thi Dien thoai & Phu kien
Dia chi: 246 Nguyen Van Linh, Da Nang
Ngay: 25/09/2026  11:10
Hoa don ban le: TGDD-99214
--------------------------------
1. Chuot Khong Day Logitech M331  250.000
2. Cap Sac Nhanh Type-C 100W      100.000
--------------------------------
PHAI TRA:                         350.000 đ
Thanh toan: Quet ma QR VietQR
Bao hanh 12 thang chinh hang.
''',
    ),
    SampleReceiptItem(
      title: 'CGV Cinemas - Xem phim cuối tuần',
      merchant: 'CGV Cinemas',
      categoryId: 'entertainment',
      expectedAmount: 185000,
      notes: 'Vé xem phim và combo bắp rang',
      rawOcrText: '''
CGV CINEMAS VIETNAM
CGV Vincom Da Nang - Rap 03
Phieu Dat Ve Phim: #CGV-4412
Date: 24/09/2026 19:45
--------------------------------
Ve 2D Standard Ghế H10      105.000
Combo Sweet Popcorn + Coke   80.000
--------------------------------
TONG CONG:                  185.000 VND
Cam on Quy khach! Chuc xem phim vui ve.
''',
    ),
  ];

  /// Populates SQLite with realistic transactions if the database is currently empty
  static Future<void> seedInitialDataIfEmpty(DatabaseHelper db) async {
    final existing = await db.getTransactions(limit: 1);
    if (existing.isNotEmpty) return;

    final now = DateTime.now();

    final seedItems = [
      ExpenseTransaction(
        merchant: 'WinMart',
        amount: 99360,
        date: now.subtract(const Duration(hours: 3)),
        categoryId: 'food',
        notes: 'Mua đồ ăn tuần mới',
        rawOcrText: sampleReceipts[1].rawOcrText,
      ),
      ExpenseTransaction(
        merchant: 'Highlands Coffee',
        amount: 113000,
        date: now.subtract(const Duration(days: 1, hours: 2)),
        categoryId: 'food',
        notes: 'Học nhóm đồ án tại Highlands',
        rawOcrText: sampleReceipts[0].rawOcrText,
      ),
      ExpenseTransaction(
        merchant: 'Fahasa Bookstore',
        amount: 217000,
        date: now.subtract(const Duration(days: 2, hours: 5)),
        categoryId: 'study',
        notes: 'Sách Flutter và văn phòng phẩm',
        rawOcrText: sampleReceipts[2].rawOcrText,
      ),
      ExpenseTransaction(
        merchant: 'Grab',
        amount: 63000,
        date: now.subtract(const Duration(days: 3, hours: 1)),
        categoryId: 'travel',
        notes: 'GrabCar đến trường thi',
        rawOcrText: sampleReceipts[3].rawOcrText,
      ),
      ExpenseTransaction(
        merchant: 'Thế Giới Di Động',
        amount: 350000,
        date: now.subtract(const Duration(days: 4, hours: 4)),
        categoryId: 'gear',
        notes: 'Chuột Logitech và cáp Type-C',
        rawOcrText: sampleReceipts[4].rawOcrText,
      ),
      ExpenseTransaction(
        merchant: 'CGV Cinemas',
        amount: 185000,
        date: now.subtract(const Duration(days: 5, hours: 3)),
        categoryId: 'entertainment',
        notes: 'Vé xem phim cuối tuần',
        rawOcrText: sampleReceipts[5].rawOcrText,
      ),
      ExpenseTransaction(
        merchant: 'Phúc Long Coffee',
        amount: 75000,
        date: now.subtract(const Duration(days: 6, hours: 6)),
        categoryId: 'food',
        notes: 'Trà đào cam sả',
      ),
    ];

    for (final tx in seedItems) {
      await db.insertTransaction(tx);
    }
  }
}
