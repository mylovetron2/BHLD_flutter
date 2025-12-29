# BHLD Mobile App

Ứng dụng di động quản lý cấp phát Bảo hộ lao động (BHLD) được xây dựng bằng Flutter.

## Tính năng

### 🎯 Tính năng chính
- **Quét QR/Barcode**: Quét mã nhân viên để cấp phát nhanh
- **Quản lý nhân viên**: Tìm kiếm và xem thông tin nhân viên
- **Quản lý chứng từ**: Tạo, xem và theo dõi chứng từ cấp phát
- **Cấp phát thiết bị**: Cấp phát và thu hồi thiết bị BHLD
- **Lịch sử**: Theo dõi lịch sử cấp phát và trả thiết bị

### 🔐 Tự động hóa nghiệp vụ
- ✅ Tự động tạo chứng từ kỳ sau khi cấp phát (sl: 0 → 1)
- ✅ Tự động xóa chứng từ kỳ sau khi trả thiết bị (sl: 1 → 0)
- ✅ Tính toán ngày hẹn trả dựa trên định mức thời gian
- ✅ Hỗ trợ nhiều loại mã nhân viên (4-5 chữ số, có ký tự)

## Yêu cầu hệ thống

- Flutter SDK >= 3.8.1
- Dart SDK >= 3.8.1
- Android Studio / VS Code
- Backend PHP API (XAMPP/LAMP)

## Cài đặt

### 1. Cài đặt dependencies

```bash
flutter pub get
```

### 2. Cấu hình API endpoint

Mở file `lib/core/constants/api_constants.dart` và cập nhật `baseUrl`:

```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS/BHLD/api';
```

**Lưu ý:** 
- Không dùng `localhost` trên thiết bị thật
- Dùng địa chỉ IP máy tính (VD: `http://192.168.1.100/BHLD/api`)
- Đảm bảo firewall cho phép kết nối

### 3. Chạy ứng dụng

```bash
flutter run
```

## Cấu trúc project

```
lib/
├── core/
│   └── constants/          # API endpoints, strings, themes
├── data/
│   ├── models/            # Data models
│   ├── repositories/      # Repository pattern
│   └── services/          # API service
└── presentation/
    ├── providers/         # State management (Provider)
    ├── screens/           # UI screens
    └── widgets/           # Reusable widgets
```

## Build APK

```bash
flutter build apk --release
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
