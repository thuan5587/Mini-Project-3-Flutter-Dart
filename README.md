# Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

> **Môn học:** Lập trình Đa nền tảng (Cross-Platform Mobile Development)  
> **Thời lượng:** Tuần 7 - 8 | **Trọng số:** 10%  
> **Công nghệ:** Flutter 3.x, Dart 3, Google ML Kit Text Recognition, SQLite (`sqflite` & `sqflite_common_ffi`), `CustomPainter`, `Provider`.

---

## 🎯 Giới thiệu Dự án & Vấn đề Thực tế (Problem Scenario)
Sinh viên, thủ quỹ các câu lạc bộ và cá nhân thường xuyên phải đối mặt với một lượng lớn hóa đơn giấy từ siêu thị, quán cà phê, nhà sách, tiền xe taxi... Việc nhập tay từng con số vào bảng tính Excel/Google Sheets rất tốn thời gian, nhàm chán và dễ nhầm lẫn.

**OCR Expense Tracker** giải quyết bài toán này bằng cách:
1. **Chụp hóa đơn nhanh:** Khung ngắm camera trực tiếp có đèn flash, chạm lấy nét (tap-to-focus), khung cắt chuẩn (framing crop overlay) kèm tia laser quét động.
2. **AI nhận diện chữ trên thiết bị (On-Device OCR):** Tích hợp **Google ML Kit Text Recognition**, hoạt động hoàn toàn offline (dưới 100ms, không tốn chi phí server hay cloud API, bảo mật dữ liệu tài chính 100%).
3. **Bộ phân tích Heuristic Regex thông minh:** Tự động trích xuất:
   - **Tổng tiền thanh toán** (hỗ trợ định dạng Việt Nam: `150.000 đ`, `150,000 VND`, `150k`, lọc bỏ số điện thoại/mã số thuế).
   - **Ngày & giờ giao dịch** (`DD/MM/YYYY`, `YYYY-MM-DD`, `HH:mm`).
   - **Tên cửa hàng/đơn vị** (Highlands, WinMart, Fahasa, Grab, Thế Giới Di Động, CGV...).
   - **Tự động gợi ý danh mục** (Ăn uống, Học tập, Di chuyển, Thiết bị, Giải trí).
4. **Màn hình xác nhận tương tác:** Cho phép người dùng kiểm tra ảnh hóa đơn, chỉnh sửa các trường đã trích xuất, gán danh mục và xem văn bản gốc OCR.
5. **Lưu trữ SQLite nội bộ:** Quản lý vòng đời giao dịch, bộ nhớ đệm ảnh thumbnail thu nhỏ (kích thước < 25KB) giúp lướt danh sách siêu mượt.
6. **Biểu đồ thuần `CustomPainter`:** Vẽ trực tiếp trên Canvas Flutter **không dùng bất kỳ thư viện bên thứ 3 nào**:
   - **Animated Donut Chart:** Biểu đồ tròn/donut xoay động, hỗ trợ chạm cảm ứng chọn từng lát cắt (tính góc bằng $\arctan2(y, x)$), phóng to lát cắt và hiển thị thông tin ở tâm biểu đồ.
   - **Weekly Bar Chart:** Biểu đồ cột chi tiêu 7 ngày trong tuần với hiệu ứng nảy (ease-out curve), thang đo trục Y tự co giãn, nhãn thứ T2-CN và tooltip chi tiết khi chạm.

---

## 🏗️ Cấu trúc Thư mục Dự án

```
Flutter & Dart/
├── assets/
│   └── sample_receipts/
│       └── receipts.json               # Dữ liệu hóa đơn mẫu offline
├── lib/
│   ├── database/
│   │   └── database_helper.dart        # SQLite CRUD, migration, bộ lọc & thống kê biểu đồ
│   ├── models/
│   │   ├── expense_category.dart       # Danh mục: Food, Study, Travel, Gear, Entertainment
│   │   ├── expense_transaction.dart    # Model giao dịch, format tiền tệ VNĐ
│   │   └── parsed_receipt.dart         # Cấu trúc dữ liệu sau khi Regex bóc tách OCR
│   ├── providers/
│   │   ├── expense_provider.dart       # Quản lý state danh sách, bộ lọc, tổng chi tiêu
│   │   └── theme_provider.dart         # Quản lý chế độ Sáng / Tối (Light / Dark mode)
│   ├── screens/
│   │   ├── analytics_screen.dart       # Màn hình chuyên sâu phân tích biểu đồ
│   │   ├── camera_scanner_screen.dart  # Camera trực tiếp, flash, tap-focus, framing overlay
│   │   ├── dashboard_screen.dart       # Tổng quan, thẻ số liệu, 2 biểu đồ CustomPainter
│   │   ├── main_navigation_screen.dart # Thanh điều hướng Bottom Bar + FAB quét
│   │   ├── receipt_review_screen.dart  # Màn hình review & chỉnh sửa sau khi quét
│   │   ├── sample_receipts_screen.dart # Sân chơi thử nghiệm 6 hóa đơn mẫu offline 1-chạm
│   │   ├── transaction_detail_screen.dart # Chi tiết giao dịch, zoom ảnh hóa đơn & OCR text
│   │   └── transaction_history_screen.dart# Lịch sử tìm kiếm, lọc đa tiêu chí, vuốt để xóa
│   ├── services/
│   │   ├── mock_data_service.dart      # Dữ liệu mẫu hóa đơn thực tế Việt Nam
│   │   ├── ocr_service.dart            # Wrapper Google ML Kit Text Recognition
│   │   ├── receipt_storage_service.dart# Lưu trữ ảnh gốc & tạo thumbnail nén
│   │   └── regex_parser_service.dart   # Engine Regex Heuristic bóc tách tiền/ngày/cửa hàng
│   ├── theme/
│   │   ├── app_colors.dart             # Bảng màu HSL hiện đại, gradient, glassmorphism
│   │   └── app_theme.dart              # Cấu hình Material 3 ThemeData Light & Dark
│   ├── widgets/
│   │   ├── camera/
│   │   │   └── crop_framing_overlay.dart # CustomPainter vẽ khung chữ L & laser quét
│   │   ├── charts/
│   │   │   ├── animated_donut_chart.dart # Widget Donut Chart có GestureDetector
│   │   │   ├── donut_chart_painter.dart  # CustomPainter vẽ các cung tròn tỷ lệ
│   │   │   ├── weekly_bar_chart.dart     # Widget Weekly Bar Chart có chạm xem chi tiết
│   │   │   └── weekly_bar_chart_painter.dart # CustomPainter vẽ 7 cột, lưới Y, nhãn ngày
│   │   ├── category_chip.dart          # Pill chọn danh mục kèm icon & màu sắc
│   │   ├── summary_card.dart           # Thẻ tổng quan số liệu tài chính
│   │   └── transaction_card.dart       # Thẻ giao dịch có ảnh thumbnail & tag OCR
│   └── main.dart                       # Điểm khởi chạy ứng dụng, sqflite_common_ffi
├── test/
│   ├── regex_parser_test.dart          # Unit test kiểm tra độ chính xác thuật toán Regex
│   └── transaction_model_test.dart     # Unit test kiểm tra serialization & format tiền tệ
├── android/                            # Cấu hình Android (minSdk 21 cho ML Kit, quyền Camera)
├── ios/                                # Cấu hình iOS (Camera/Photo Library descriptions)
├── pubspec.yaml                        # Danh sách dependencies & assets
└── MINI_PROJECT_3_REPORT.md            # Báo cáo học thuật chi tiết 100%
```

---

## 🚀 Hướng dẫn Cài đặt & Chạy ứng dụng

### Yêu cầu Tiên quyết
- **Flutter SDK:** Phiên bản `>= 3.0.0`
- **Dart SDK:** Phiên bản `>= 3.0.0`
- **Android Studio** hoặc **Visual Studio Code** với Flutter extension
- Thiết bị thật Android/iOS (hoặc máy ảo Android Emulator / Windows Desktop)

### Các bước thực hiện:
```bash
# 1. Cài đặt các gói thư viện
flutter pub get

# 2. Chạy bộ Unit Tests để kiểm tra thuật toán Regex bóc tách hóa đơn
flutter test

# 3. Khởi chạy ứng dụng
# Chạy trên thiết bị Android:
flutter run -d android

# Chạy trên máy ảo iOS:
flutter run -d ios

# Chạy trên Windows Desktop (hỗ trợ đầy đủ SQLite FFI & Mock OCR Playground):
flutter run -d windows
```

---

## 🧠 Chi tiết Giải thuật Heuristic Regex (`RegexParserService`)

Bộ phân giải nhận chuỗi văn bản thô từ Google ML Kit và xử lý qua 4 bước:

### 1. Bóc tách Tổng Tiền (Monetary Total)
- Phát hiện từ khóa báo hiệu tổng kết: `TỔNG CỘNG`, `THANH TOÁN`, `TỔNG TIỀN`, `TIỀN MẶT`, `PHẢI TRẢ`, `TOTAL`, `GRAND TOTAL`, `AMOUNT DUE`...
- Hỗ trợ các kiểu biểu diễn tiền tệ:
  - Phân cách hàng nghìn bằng dấu chấm: `113.000 đ`, `99.360 VND`, `1.500.000`
  - Phân cách bằng dấu phẩy: `150,000`
  - Ký hiệu viết tắt `k`: `150k` $\rightarrow 150000$
- **Hệ số chấm điểm vị trí (Scoring Heuristic):** Dòng chứa từ khóa tổng tiền được cộng 100 điểm; nếu số nằm ở dòng kế tiếp (dạng label/value) được cộng 90 điểm; vị trí nằm ở nửa cuối hóa đơn được tính trọng số theo độ sâu.
- **Bộ lọc nhiễu (Noise Filter):** Loại trừ số điện thoại (10 chữ số bắt đầu bằng 0), mã số thuế (MST), số hóa đơn, ngày tháng.

### 2. Bóc tách Ngày & Giờ Giao dịch (Date & Time)
- Regex ngày: `\b([0-2]?\d|3[01])[\/\-\.](0?\d|1[0-2])[\/\-\.](20\d{2})\b` (định dạng `DD/MM/YYYY`)
- Regex giờ: `\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b` (định dạng `HH:mm`)
- Tự động ghép nối thành đối tượng `DateTime` chuẩn. Nếu hóa đơn mờ hoặc không có ngày, hệ thống lấy ngày hiện tại.

### 3. Bóc tách Tên Đơn vị Bán lẻ (Merchant Identification)
- Tra cứu danh bạ chuỗi bán lẻ phổ biến: *Highlands Coffee, WinMart, Co.opmart, Bách Hóa Xanh, Circle K, Phúc Long, The Coffee House, Fahasa, Grab, Xanh SM, Thế Giới Di Động, FPT Shop, CGV Cinemas...*
- Loại trừ dòng tiêu đề chuẩn như `HÓA ĐƠN BÁN HÀNG`, `PHIẾU THANH TOÁN`, `VAT INVOICE`, địa chỉ bắt đầu bằng `Đ/C`, `Số`, `Hotline`...

---

## 🎨 Toán học & Kỹ thuật CustomPainter

### 1. Animated Donut Chart (Biểu đồ Vành khăn)
- Tọa độ tâm: $C = (W/2, H/2)$
- Bán kính ngoài $R = \min(W, H)/2 - 18$, bán kính trong $r = 0.62 \times R$.
- Với mỗi danh mục có số tiền $A_i$ trên tổng $T$:
  $$\theta_i = \frac{A_i}{T} \times 2\pi \times \text{progress}$$
- **Phát hiện tương tác chạm (Touch Detection):**
  Lấy tọa độ chạm $P(x, y)$ từ `TapUpDetails`:
  $$dx = x - C_x, \quad dy = y - C_y$$
  $$d = \sqrt{dx^2 + dy^2}$$
  Nếu $r \le d \le R + 12$:
  $$\alpha = \arctan2(dy, dx) + \frac{\pi}{2}$$
  Duyệt góc tích lũy $\sum \theta_i$ để xác định chính xác danh mục được nhấn, kích hoạt hiệu ứng pop-out mở rộng bán kính ngoài thêm $+8\text{px}$ kèm bóng sáng (glow shadow).

### 2. Weekly Bar Chart (Biểu đồ Cột Tuần)
- Tự động chuẩn hóa chiều cao cột theo giá trị chi tiêu lớn nhất:
  $$H_{\text{bar}} = \frac{\text{amount}_i}{\text{maxAmount}} \times H_{\text{chart}} \times \text{progress}$$
- Đỉnh cột bo tròn bằng `RRect.fromRectAndCorners(topLeft: Radius.circular(6), topRight: Radius.circular(6))`.
- Vẽ đường lưới phụ Y bằng `canvas.drawLine` và nhãn đơn vị tiền tệ (`50k`, `100k`, `1M`).
- Cột của ngày hiện tại được gắn viền sáng và gradient phân biệt.

---

## 🧪 Sân chơi Hóa đơn Mẫu (Offline Sample Playground)
Khi chạy trên máy ảo hoặc thiết bị không có hóa đơn giấy, bạn có thể:
1. Nhấn nút **"Hóa Đơn Mẫu"** trên màn hình chính hoặc nút **"Mẫu test"** trong màn hình camera.
2. Ứng dụng cung cấp sẵn 6 hóa đơn thực tế:
   - **Highlands Coffee** (113.000 ₫ - Ăn uống)
   - **WinMart Cộng Hòa** (99.360 ₫ - Ăn uống)
   - **Nhà sách Fahasa** (217.000 ₫ - Học tập)
   - **GrabCar** (63.000 ₫ - Di chuyển)
   - **Thế Giới Di Động** (350.000 ₫ - Thiết bị)
   - **CGV Cinemas** (185.000 ₫ - Giải trí)
3. Xem kết quả trích xuất Heuristic trực tiếp và nhấn **"Mở trang Review & Lưu"** để nạp ngay vào cơ sở dữ liệu SQLite!
