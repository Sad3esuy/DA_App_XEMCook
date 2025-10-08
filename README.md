# 🍳 Recipe App - Ứng dụng Công thức Nấu ăn Cá nhân

![Flutter Version](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)
![Dart Version](https://img.shields.io/badge/Dart-3.5.0-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

Ứng dụng di động đa nền tảng giúp bạn lưu trữ, quản lý và chia sẻ công thức nấu ăn cá nhân. Xây dựng bằng Flutter với giao diện thân thiện và nhiều tính năng hữu ích.

## ✨ Tính năng chính

- 📝 **Quản lý công thức**: Thêm, sửa, xóa công thức với hình ảnh
- 🔍 **Tìm kiếm thông minh**: Tìm theo tên, nguyên liệu, tags
- 🛒 **Danh sách mua sắm**: Tự động tạo từ công thức
- 📅 **Kế hoạch thực đơn**: Lên lịch món ăn theo tuần/tháng
- 📤 **Chia sẻ**: Xuất PDF, chia sẻ qua mạng xã hội
- 🌙 **Dark mode**: Giao diện sáng/tối
- 📱 **Offline-first**: Làm việc không cần internet
- 🔄 **Đồng bộ**: Sync dữ liệu qua nhiều thiết bị
- 🌍 **Đa ngôn ngữ**: Tiếng Việt, Tiếng Anh

## 📸 Screenshots

```
[Thêm screenshots của app tại đây]
```

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.24.0
- **Language**: Dart 3.5.0
- **State Management**: Riverpod 2.5.0
- **Navigation**: go_router 14.0.0
- **Local Database**: Hive 2.2.3
- **Image Handling**: cached_network_image 3.3.1

### Backend
- **API**: Firebase (Auth, Firestore, Storage)
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Analytics**: Firebase Analytics
- **Crash Reporting**: Firebase Crashlytics

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.5.0
  
  # Navigation
  go_router: ^14.0.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_analytics: ^10.8.0
  
  # Image Handling
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  
  # UI
  flutter_svg: ^2.0.10
  google_fonts: ^6.1.0
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.3.3
  share_plus: ^7.2.2
  pdf: ^3.10.8
```

## 📋 Yêu cầu hệ thống

### Development Environment
- **Flutter SDK**: >= 3.24.0
- **Dart SDK**: >= 3.5.0
- **Android Studio** / **VS Code** với Flutter plugin
- **Xcode** (cho iOS development trên macOS)
- **CocoaPods** (cho iOS)

### Minimum Platform Versions
- **iOS**: 12.0+
- **Android**: API Level 24 (Android 7.0)+

## 🚀 Cài đặt và Chạy dự án

### 1. Clone Repository

```bash
git clone https://github.com/your-username/recipe-app.git
cd recipe-app
```

### 2. Cài đặt Flutter Dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase

#### 3.1. Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới hoặc chọn project có sẵn
3. Enable các services: Authentication, Firestore, Storage

#### 3.2. Cấu hình iOS
```bash
# Cài đặt FlutterFire CLI
dart pub global activate flutterfire_cli

# Cấu hình Firebase
flutterfire configure
```

Hoặc thủ công:
1. Download `GoogleService-Info.plist` từ Firebase Console
2. Copy vào `ios/Runner/`
3. Mở `ios/Runner.xcworkspace` bằng Xcode
4. Add file vào project

#### 3.3. Cấu hình Android
1. Download `google-services.json` từ Firebase Console
2. Copy vào `android/app/`

### 4. Cấu hình Environment Variables

Tạo file `.env` tại root project:

```env
# App Configuration
APP_NAME=Recipe App
APP_VERSION=1.0.0

# Firebase (Optional - if not using FlutterFire)
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_bucket

# API URLs (if using custom backend)
API_BASE_URL=https://api.yourapp.com
```

### 5. Generate Code (Hive, Freezed, etc.)

```bash
# Generate Hive adapters
flutter packages pub run build_runner build --delete-conflicting-outputs

# Hoặc watch mode cho development
flutter packages pub run build_runner watch
```

### 6. Chạy ứng dụng

#### Chạy trên Android Emulator/Device
```bash
# Liệt kê devices
flutter devices

# Chạy debug mode
flutter run

# Chạy release mode
flutter run --release
```

#### Chạy trên iOS Simulator/Device
```bash
# Mở simulator
open -a Simulator

# Chạy app
flutter run

# Chạy với device cụ thể
flutter run -d "iPhone 15 Pro"
```

#### Chạy trên Web (Optional)
```bash
flutter run -d chrome
```

## 🏗️ Cấu trúc Project

```
recipe-app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # App widget chính
│   │
│   ├── core/                     # Core functionalities
│   │   ├── constants/            # Constants, colors, strings
│   │   ├── theme/                # App theme
│   │   ├── utils/                # Utilities, helpers
│   │   ├── router/               # Navigation routing
│   │   └── di/                   # Dependency injection
│   │
│   ├── data/                     # Data layer
│   │   ├── models/               # Data models
│   │   ├── repositories/         # Repository implementations
│   │   ├── datasources/          # Local & Remote datasources
│   │   │   ├── local/            # Hive, SharedPreferences
│   │   │   └── remote/           # Firebase, API calls
│   │   └── dto/                  # Data transfer objects
│   │
│   ├── domain/                   # Business logic layer
│   │   ├── entities/             # Business entities
│   │   ├── repositories/         # Repository interfaces
│   │   └── usecases/             # Business use cases
│   │
│   ├── presentation/             # UI layer
│   │   ├── screens/              # App screens
│   │   │   ├── home/
│   │   │   ├── recipe_detail/
│   │   │   ├── add_recipe/
│   │   │   ├── shopping_list/
│   │   │   ├── meal_plan/
│   │   │   └── profile/
│   │   ├── widgets/              # Reusable widgets
│   │   └── providers/            # Riverpod providers
│   │
│   └── l10n/                     # Localization files
│       ├── app_en.arb
│       └── app_vi.arb
│
├── assets/                       # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── test/                         # Unit tests
├── integration_test/             # Integration tests
├── android/                      # Android specific code
├── ios/                          # iOS specific code
├── web/                          # Web specific code
│
├── .env                          # Environment variables
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```

## 🧪 Testing

### Chạy Unit Tests
```bash
flutter test
```

### Chạy Integration Tests
```bash
flutter test integration_test
```

### Test Coverage
```bash
# Generate coverage report
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📦 Build & Deploy

### Android

#### Debug APK
```bash
flutter build apk --debug
```

#### Release APK
```bash
flutter build apk --release --split-per-abi
```

#### App Bundle (cho Google Play)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
flutter build ios --release
```

Sau đó mở Xcode để archive và upload lên App Store:
```bash
open ios/Runner.xcworkspace
```

### Signing Configuration

#### Android
Cấu hình trong `android/key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=/path/to/keystore.jks
```

#### iOS
Cấu hình signing trong Xcode:
- Open `ios/Runner.xcworkspace`
- Select Runner target
- Configure Signing & Capabilities

## 🔧 Configuration Files

### pubspec.yaml
File cấu hình chính cho dependencies và assets

### analysis_options.yaml
Lint rules cho code quality
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - avoid_print
    - prefer_single_quotes
```

### firebase.json
Cấu hình Firebase hosting (nếu deploy web)

## 🐛 Troubleshooting

### Pod install fails (iOS)
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### Gradle build fails (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Firebase không kết nối
- Kiểm tra `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
- Chạy lại `flutterfire configure`
- Kiểm tra package name/bundle ID trùng khớp với Firebase

### Code generation không chạy
```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 📚 Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Project Wiki](https://github.com/your-username/recipe-app/wiki)

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `flutter analyze` before committing
- Format code với `flutter format .`

## 📝 Changelog

Xem [CHANGELOG.md](CHANGELOG.md) cho lịch sử thay đổi.

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/your-username)

## 🙏 Acknowledgments

- Flutter team cho framework tuyệt vời
- Firebase cho backend services
- Community contributors

## 📞 Support

- Email: support@recipeapp.com
- Issues: [GitHub Issues](https://github.com/your-username/recipe-app/issues)
- Discord: [Join our server](https://discord.gg/your-server)

## 🗺️ Roadmap

- [ ] Version 1.0 - MVP Release
  - [x] Basic CRUD operations
  - [x] Image upload
  - [ ] Shopping list
  - [ ] Meal planning
  
- [ ] Version 1.1 - Enhanced Features
  - [ ] Recipe sharing
  - [ ] Community features
  - [ ] Advanced search
  
- [ ] Version 2.0 - Major Update
  - [ ] AI recipe suggestions
  - [ ] Nutrition tracking
  - [ ] Voice commands

---

Made with ❤️ using Flutter