# 🍳 XEMCook - Ứng dụng Chia sẻ Công thức Nấu ăn

![Flutter Version](https://img.shields.io/badge/Flutter-3.24.0+-02569B?logo=flutter)
![Dart Version](https://img.shields.io/badge/Dart-3.5.0+-0175C2?logo=dart)
![Node.js Version](https://img.shields.io/badge/Node.js-18.0+-339933?logo=node.js)

**XEMCook** là nền tảng mạng xã hội chia sẻ công thức nấu ăn, nơi mọi người có thể khám phá, lưu trữ, và chia sẻ những món ăn yêu thích. Ứng dụng kết hợp giữa tính năng mạng xã hội và quản lý công thức cá nhân, mang đến trải nghiệm nấu ăn thú vị và kết nối cộng đồng đam mê ẩm thực.

## ✨ Tính năng chính

### 🏠 Trang chủ & Khám phá
- **Feed động**: Xem công thức mới nhất từ cộng đồng
- **Món ăn trong ngày**: Gợi ý công thức hot trends
- **Đầu bếp nổi bật**: Khám phá các chef có nhiều followers
- **Danh mục phong phú**: Dễ dàng tìm món ăn theo loại

### 📖 Quản lý Công thức
- **Tạo & Chỉnh sửa**: Thêm công thức với ảnh, nguyên liệu, và hướng dẫn chi tiết
- **Upload ảnh**: Chụp hoặc chọn ảnh từ thư viện
- **Công thức của tôi**: Quản lý tất cả công thức đã tạo
- **Yêu thích**: Lưu công thức yêu thích để nấu sau

### 🔍 Tìm kiếm & Lọc
- **Tìm kiếm thông minh**: Tìm theo tên món, nguyên liệu, tag
- **Lọc nâng cao**: Theo danh mục, độ khó, thời gian
- **Lịch sử tìm kiếm**: Lưu các từ khóa đã tìm gần đây
- **Gợi ý tìm kiếm**: Suggestions dựa trên lịch sử

### 👤 Hồ sơ & Cộng đồng
- **Profile cá nhân**: Hiển thị thông tin, ảnh đại diện, thống kê
- **Theo dõi**: Follow/Unfollow đầu bếp yêu thích
- **Đánh giá & Review**: Đánh giá công thức, để lại bình luận
- **Xem profile người khác**: Khám phá công thức của các chef khác

### 🛒 Danh sách Mua sắm
- **Tạo danh sách**: Từ công thức hoặc tự thêm
- **Quản lý items**: Check/uncheck, thêm, xóa
- **Chia sẻ danh sách**: Share qua tin nhắn, email

### 🔔 Thông báo
- **Push Notifications**: Nhận thông báo realtime
- **Nhiều loại thông báo**: 
  - Người khác follow bạn
  - Có người like/comment công thức
  - Công thức mới từ chef bạn theo dõi
- **Cài đặt thông báo**: Tùy chỉnh loại thông báo nhận

### 🔐 Xác thực & Bảo mật
- **Đăng ký/Đăng nhập**: Email/Password
- **Google Sign In**: Đăng nhập nhanh với Google
- **Quên mật khẩu**: Khôi phục qua email với OTP
- **Đổi mật khẩu**: Cập nhật mật khẩu trong app

### 📱 Giao diện & UX
- **Material Design 3**: Giao diện hiện đại, mượt mà
- **Custom Theme**: Màu sắc nhẹ nhàng, thân thiện
- **Animations**: Hiệu ứng chuyển trang, loading đẹp mắt
- **Bottom Navigation**: Điều hướng nhanh giữa các trang chính

## 📸 Screenshots

```
[Thêm screenshots của app tại đây]
```

## 🛠️ Tech Stack

### Frontend (Flutter App)

#### Framework & Language
- **Flutter**: 3.24.0+
- **Dart**: 3.5.0+

#### State Management
- **Provider**: 6.1.1 - Quản lý state đơn giản, hiệu quả
- **ValueNotifier**: Cho state cục bộ (shopping list, favorites)

#### UI Components
- **Material 3**: useMaterial3: true
- **google_fonts**: 6.1.0 - Custom fonts (Poppins)
- **flutter_svg**: 2.0.9 - SVG icons
- **animated_text_kit**: 4.2.2 - Text animations
- **google_nav_bar**: 5.0.7 - Custom bottom navigation
- **dotted_border**: 3.1.0 - UI decorations

#### Navigation
- Native Navigator với named routes

#### Firebase Integration
- **firebase_core**: 3.8.0
- **firebase_auth**: 5.3.3 - Authentication
- **cloud_firestore**: 5.6.0 - Database (lưu favorites)
- **firebase_storage**: 12.0.0 - Lưu trữ ảnh
- **firebase_messaging**: 15.1.0 - Push notifications
- **flutter_local_notifications**: 17.2.1 - Local notifications

#### Image Handling
- **image_picker**: 1.1.2 - Chọn/chụp ảnh
- File system caching cho offline support

#### Storage & Persistence
- **shared_preferences**: 2.2.2 - Local storage (token, settings, onboarding)

#### Authentication
- **google_sign_in**: 6.2.1 - Google OAuth
- JWT tokens cho API authentication

#### Network & API
- **http**: 1.1.2 - HTTP client cho REST API

#### Utilities
- **uuid**: 4.5.1 - Generate unique IDs
- **email_validator**: 2.1.17 - Validate email format
- **url_launcher**: 6.3.0 - Launch external URLs
- **share_plus**: 12.0.0 - Share content

### Backend (Node.js API)

#### Framework & Runtime
- **Node.js**: 18.0+
- **Express.js**: 5.1.0 - Web framework

#### Database
- **PostgreSQL**: 14+ - Relational database
- **Sequelize**: 6.37.7 - ORM
- **pg**: 8.16.3 - PostgreSQL client
- **pg-hstore**: 2.3.4 - JSON serialization

#### Authentication & Security
- **bcryptjs**: 3.0.2 - Password hashing
- **jsonwebtoken**: 9.0.2 - JWT authentication
- **passport**: 0.7.0 - Authentication middleware
- **passport-google-oauth20**: 2.0.0 - Google OAuth
- **passport-jwt**: 4.0.1 - JWT strategy
- **helmet**: 7.1.0 - Security headers
- **express-rate-limit**: 7.1.5 - Rate limiting
- **cors**: 2.8.5 - CORS handling

#### File Upload & Storage
- **multer**: 1.4.5-lts.1 - File upload middleware
- **cloudinary**: 2.7.0 - Cloud image storage & CDN

#### Email & Notifications
- **nodemailer**: 6.9.14 - Email service
- **firebase-admin**: 12.0.0 - FCM push notifications

#### Validation & Logging
- **express-validator**: 7.0.1 - Request validation
- **morgan**: 1.10.0 - HTTP request logger

#### Development
- **nodemon**: 3.1.10 - Auto-restart server
- **dotenv**: 17.2.3 - Environment variables

## 📋 Yêu cầu hệ thống

### Development Environment

#### Flutter Development
- **Flutter SDK**: >= 3.24.0
- **Dart SDK**: >= 3.5.0
- **Android Studio** hoặc **VS Code** với Flutter extension
- **Xcode** 14+ (cho iOS development trên macOS)
- **CocoaPods** (cho iOS dependencies)

#### Backend Development
- **Node.js**: >= 18.0
- **npm** hoặc **yarn**
- **PostgreSQL**: >= 14.0
- **Git**: Để quản lý source code

### Minimum Platform Versions
- **Android**: API Level 24 (Android 7.0+)
- **iOS**: 12.0+
- **Web**: Chrome, Firefox, Safari (modern browsers)

### Hardware Requirements
- **RAM**: Tối thiểu 8GB (recommended 16GB)
- **Storage**: 10GB free space
- **Internet**: Cần kết nối để sync dữ liệu

## 🚀 Cài đặt và Chạy dự án

### 1. Clone Repository

```bash
git clone https://github.com/Sad3esuy/DA_App_XEMCook.git
cd DA_App_XEMCook
```

### 2. Setup Backend API

#### 2.1. Di chuyển vào thư mục backend
```bash
cd xemcook_be_api
```

#### 2.2. Cài đặt dependencies
```bash
npm install
```

#### 2.3. Cấu hình Database
Tạo PostgreSQL database:
```sql
CREATE DATABASE xemcook_db;
```

#### 2.4. Cấu hình Environment Variables
Tạo file `.env` trong thư mục `xemcook_be_api/`:

```env
# Server Configuration
PORT=5000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=xemcook_db
DB_USER=your_db_user
DB_PASSWORD=your_db_password

# JWT Secret
JWT_SECRET=your_super_secret_jwt_key_here_change_in_production
JWT_EXPIRES_IN=7d

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=http://localhost:5000/api/auth/google/callback

# Cloudinary (Image Upload)
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Email Service (Nodemailer)
EMAIL_SERVICE=gmail
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password

# Firebase Admin (Push Notifications)
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_PRIVATE_KEY="your_firebase_private_key"

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:3000
```

#### 2.5. Chạy migrations (nếu có)
```bash
npm run migrate
# Hoặc
npx sequelize-cli db:migrate
```

#### 2.6. Khởi động server
```bash
# Development mode
npm run dev

# Production mode
npm start
```

Server sẽ chạy tại: `http://localhost:5000`

### 3. Setup Flutter App

#### 3.1. Di chuyển vào thư mục Flutter
```bash
cd ../test_ui_app
```

#### 3.2. Cài đặt Flutter dependencies
```bash
flutter pub get
```

#### 3.3. Cấu hình Firebase

##### Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới: **XEMCook**
3. Enable các services:
   - **Authentication**: Email/Password, Google Sign-In
   - **Cloud Firestore**: Database cho favorites
   - **Storage**: Lưu trữ ảnh
   - **Cloud Messaging**: Push notifications

##### Cấu hình Android
1. Trong Firebase Console, thêm Android app
2. Package name: `com.example.test_ui_app` (hoặc theo config của bạn)
3. Download `google-services.json`
4. Copy vào `android/app/google-services.json`

##### Cấu hình iOS
1. Trong Firebase Console, thêm iOS app
2. Bundle ID: `com.example.testUiApp` (hoặc theo config của bạn)
3. Download `GoogleService-Info.plist`
4. Copy vào `ios/Runner/GoogleService-Info.plist`
5. Chạy pod install:
```bash
cd ios
pod install
cd ..
```

#### 3.4. Cập nhật API Base URL

Mở file `lib/services/auth_service.dart` và cập nhật baseUrl:

```dart
// Cho Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Cho iOS Simulator
static const String baseUrl = 'http://localhost:5000/api';

// Cho device thật (dùng IP máy)
static const String baseUrl = 'http://192.168.1.x:5000/api';
```

Tương tự cho các service khác:
- `lib/services/recipe_api_service.dart`
- `lib/services/notification_api_service.dart`
- `lib/services/shopping_list_remote.dart`

#### 3.5. Chạy ứng dụng

##### Kiểm tra devices
```bash
flutter devices
```

##### Chạy trên Android
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Chọn device cụ thể
flutter run -d <device-id>
```

##### Chạy trên iOS
```bash
# Mở simulator
open -a Simulator

# Chạy app
flutter run

# Chạy trên device cụ thể
flutter run -d "iPhone 15 Pro"
```

##### Chạy trên Chrome (Web)
```bash
flutter run -d chrome
```

## 🏗️ Cấu trúc Project

### Flutter App Structure
```
test_ui_app/
├── lib/
│   ├── main.dart                      # Entry point, Firebase init
│   │
│   ├── model/                         # Data models
│   │   ├── recipe.dart                # Recipe model
│   │   ├── user.dart                  # User model
│   │   ├── auth.dart                  # Auth request/response
│   │   ├── ingredient.dart            # Ingredient model
│   │   ├── instruction.dart           # Instruction model
│   │   ├── chef_profile.dart          # Chef profile model
│   │   ├── collection.dart            # Recipe collection model
│   │   ├── shopping_list.dart         # Shopping list model
│   │   ├── shopping_item.dart         # Shopping item model
│   │   ├── app_notification.dart      # Notification model
│   │   ├── notification_settings.dart # Settings model
│   │   └── home_feed.dart             # Home feed data model
│   │
│   ├── screens/                       # UI Screens
│   │   ├── main_shell.dart            # Main navigation shell
│   │   ├── home_screen.dart           # Home feed screen
│   │   │
│   │   ├── auth/                      # Authentication screens
│   │   │   ├── welcome_screen.dart    # Onboarding/Welcome
│   │   │   ├── login_screen.dart      # Login
│   │   │   ├── register_screen.dart   # Sign up
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── verify_pin_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   │
│   │   ├── recipe/                    # Recipe screens
│   │   │   ├── recipe_detail_screen.dart
│   │   │   ├── recipe_form_screen.dart     # Create/Edit recipe
│   │   │   ├── recipe_collection_screen.dart
│   │   │   ├── my_recipes_screen.dart
│   │   │   ├── favorite_screen.dart
│   │   │   ├── collection/            # Collection management
│   │   │   │   ├── create_collection_screen.dart
│   │   │   │   ├── collection_detail_screen.dart
│   │   │   │   └── add_recipe_to_collection_sheet.dart
│   │   │   └── reviews/               # Review & rating
│   │   │       ├── recipe_reviews_screen.dart
│   │   │       ├── recipe_review_form_screen.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── search/                    # Search & discover
│   │   │   ├── search_screen.dart
│   │   │   └── result_recipes_screen.dart
│   │   │
│   │   ├── shopping/                  # Shopping list
│   │   │   ├── shopping_list_screen.dart
│   │   │   └── add_to_list_bottom_sheet.dart
│   │   │
│   │   ├── notifications/             # Notifications
│   │   │   └── notifications_screen.dart
│   │   │
│   │   └── profile/                   # Profile & settings
│   │       ├── profile_screen.dart
│   │       ├── edit_profile_screen.dart
│   │       ├── chef_profile_screen.dart    # View other users
│   │       ├── change_password_screen.dart
│   │       ├── notification_settings_screen.dart
│   │       ├── about_us_screen.dart
│   │       ├── privacy_policy_screen.dart
│   │       └── widget/                # Profile widgets
│   │
│   ├── services/                      # Business logic & API
│   │   ├── auth_service.dart          # Auth API calls
│   │   ├── recipe_api_service.dart    # Recipe CRUD
│   │   ├── notification_api_service.dart
│   │   ├── shopping_list_service.dart # Local shopping list
│   │   ├── shopping_list_remote.dart  # Remote shopping API
│   │   ├── search_history_service.dart
│   │   ├── favorite_state.dart        # Favorite state management
│   │   ├── push_notification_service.dart # FCM
│   │   └── database/                  # Local database helpers
│   │
│   ├── widgets/                       # Reusable widgets
│   │   ├── recipe_card.dart
│   │   └── my_recipe_cards.dart
│   │
│   ├── theme/                         # App theming
│   │   └── app_theme.dart
│   │
│   └── utils/                         # Utilities & helpers
│
├── assets/                            # Static assets
│   ├── images/                        # App images
│   │   └── app_icon_v2.png
│   └── icons/                         # App icons
│       └── app_icon_v3.jpg
│
├── android/                           # Android native code
│   ├── app/
│   │   ├── google-services.json       # Firebase config
│   │   └── build.gradle.kts
│   └── build.gradle.kts
│
├── ios/                               # iOS native code
│   └── Runner/
│       └── GoogleService-Info.plist   # Firebase config
│
├── pubspec.yaml                       # Flutter dependencies
└── README.md
```

### Backend API Structure
```
xemcook_be_api/
├── server.js                          # Entry point
├── src/
│   ├── app.js                         # Express app setup
│   └── utils/                         # Shared utilities
│
├── config/                            # Configurations
│   ├── db.js                          # Sequelize database config
│   └── passport.js                    # Passport strategies
│
├── models/                            # Sequelize models
│   └── Recipe.js                      # Recipe model (example)
│
├── controllers/                       # Business logic
│   ├── authController.js              # Auth logic
│   ├── userController.js              # User CRUD
│   ├── recipeController.js            # Recipe CRUD
│   └── notificationController.js      # Notification logic
│
├── routes/                            # API routes
│   ├── auth.js                        # /api/auth/*
│   ├── users.js                       # /api/users/*
│   ├── recipes.js                     # /api/recipes/*
│   └── notifications.js               # /api/notifications/*
│
├── middleware/                        # Custom middleware
│   ├── auth.js                        # JWT verification
│   ├── optionalAuth.js                # Optional auth
│   └── validateRequest.js             # Request validation
│
├── validators/                        # Input validation schemas
│   └── authValidators.js
│
├── utils/                             # Utilities
│   ├── cloudinary.js                  # Image upload
│   ├── emailService.js                # Send emails
│   ├── firebaseAdmin.js               # Firebase admin SDK
│   └── notificationDispatcher.js      # Push notifications
│
├── uploads/                           # Temporary file uploads
│
├── package.json                       # Node dependencies
└── .env                               # Environment variables
```

## 🧪 Testing

### Backend API Testing

#### Sử dụng Postman hoặc cURL

```bash
# Test server health
curl http://localhost:5000/api/auth/test

# Register new user
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "fullName": "Test User",
    "username": "testuser"
  }'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Flutter Testing

#### Unit Tests
```bash
flutter test
```

#### Widget Tests
```bash
flutter test test/widget_test.dart
```

#### Integration Tests
```bash
flutter test integration_test
```

## 📦 Build & Deploy

### Build Flutter App

#### Android APK
```bash
# Debug APK
flutter build apk --debug

# Release APK (split by ABI)
flutter build apk --release --split-per-abi

# Release APK (single file)
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/`

#### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### iOS
```bash
# Build iOS
flutter build ios --release

# Mở Xcode để archive
open ios/Runner.xcworkspace
```

Trong Xcode:
1. Product > Archive
2. Distribute App
3. Upload to App Store Connect

### Deploy Backend

#### Local/Development
```bash
npm run dev
```

#### Production (VPS/Cloud)

##### Using PM2
```bash
# Cài đặt PM2
npm install -g pm2

# Khởi động app
pm2 start server.js --name xemcook-api

# Xem logs
pm2 logs xemcook-api

# Restart
pm2 restart xemcook-api

# Stop
pm2 stop xemcook-api
```

##### Using Docker
```dockerfile
# Tạo Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

```bash
# Build image
docker build -t xemcook-api .

# Run container
docker run -p 5000:5000 --env-file .env xemcook-api
```

## 🔧 Configuration

### Firebase Configuration

#### Enable Authentication Methods
1. Firebase Console > Authentication > Sign-in method
2. Enable:
   - Email/Password
   - Google

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Favorites collection
    match /favorites/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // User settings
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /recipes/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /profiles/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Database Migrations

Tạo migrations với Sequelize CLI:

```bash
# Tạo migration mới
npx sequelize-cli migration:generate --name create-users-table

# Chạy migrations
npx sequelize-cli db:migrate

# Rollback migration
npx sequelize-cli db:migrate:undo
```

## 🐛 Troubleshooting

### Flutter Issues

#### 1. Pod install fails (iOS)
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

#### 2. Gradle build fails (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --debug
```

#### 3. Firebase không kết nối
- Kiểm tra `google-services.json` và `GoogleService-Info.plist`
- Verify package name/bundle ID match với Firebase
- Rebuild app: `flutter clean && flutter run`

#### 4. Image picker không hoạt động

**Android**: Thêm vào `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

**iOS**: Thêm vào `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Need camera access to take photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Need library access to select photos</string>
```

#### 5. API connection timeout
- Check baseUrl trong auth_service.dart
- Android Emulator: Dùng `10.0.2.2` thay vì `localhost`
- iOS Simulator: Dùng `localhost` hoặc IP máy
- Real device: Dùng IP máy trong cùng network

### Backend Issues

#### 1. Database connection error
```bash
# Check PostgreSQL đã chạy chưa
sudo service postgresql status

# Restart PostgreSQL
sudo service postgresql restart

# Verify credentials trong .env
```

#### 2. JWT token expired
- Token mặc định expire sau 7 ngày
- User cần login lại
- Có thể tăng `JWT_EXPIRES_IN` trong .env

#### 3. Cloudinary upload fails
- Verify credentials trong .env
- Check file size limit (default 10MB)
- Check internet connection

#### 4. Firebase Admin errors
- Verify service account credentials
- Check FIREBASE_PRIVATE_KEY format (phải có quotes)
- Ensure Firebase Admin SDK enabled

#### 5. CORS errors
- Thêm frontend URL vào CORS whitelist
- Check FRONTEND_URL trong .env
- Verify origin header trong request

## 📚 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication Endpoints

#### Register
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "John Doe",
  "username": "johndoe"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "John Doe",
    ...
  }
}
```

#### Google Login
```http
POST /auth/google
Content-Type: application/json

{
  "idToken": "google_id_token"
}
```

### Recipe Endpoints

#### Get All Recipes
```http
GET /recipes
Authorization: Bearer {token}

Query params:
  - page: number (default 1)
  - limit: number (default 20)
  - category: string
  - search: string
```

#### Get Recipe Detail
```http
GET /recipes/:id
Authorization: Bearer {token} (optional)
```

#### Create Recipe
```http
POST /recipes
Authorization: Bearer {token}
Content-Type: multipart/form-data

Form data:
  - title: string
  - description: string
  - category: string
  - difficulty: string
  - cookingTime: number
  - servings: number
  - ingredients: JSON array
  - instructions: JSON array
  - image: file
```

#### Update Recipe
```http
PUT /recipes/:id
Authorization: Bearer {token}
```

#### Delete Recipe
```http
DELETE /recipes/:id
Authorization: Bearer {token}
```

### User Endpoints

#### Get User Profile
```http
GET /users/profile
Authorization: Bearer {token}
```

#### Update Profile
```http
PUT /users/profile
Authorization: Bearer {token}
```

#### Follow User
```http
POST /users/:id/follow
Authorization: Bearer {token}
```

### Notification Endpoints

#### Get Notifications
```http
GET /notifications
Authorization: Bearer {token}

Query params:
  - page: number
  - unreadOnly: boolean
```

#### Mark as Read
```http
PUT /notifications/:id/read
Authorization: Bearer {token}
```

## 🤝 Contributing

Contributions are welcome! Vui lòng follow các bước sau:

### Development Workflow
1. Fork repository
2. Create feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit changes
   ```bash
   git commit -m 'Add some amazing feature'
   ```
4. Push to branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open Pull Request

### Code Style

#### Flutter/Dart
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` để check issues
- Format code: `flutter format .`
- Naming:
  - Classes: PascalCase
  - Variables/Functions: camelCase
  - Constants: lowerCamelCase
  - Private: _prefixed

#### JavaScript/Node.js
- Follow [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- Use ESLint
- Naming:
  - Variables/Functions: camelCase
  - Classes: PascalCase
  - Constants: UPPER_SNAKE_CASE

### Commit Messages
```
feat: Add new feature
fix: Bug fix
docs: Documentation update
style: Code style changes
refactor: Code refactoring
test: Add tests
chore: Build/config changes
```

## 📝 Changelog

### Version 0.1.0 (Current)
- ✅ Authentication system (Email, Google)
- ✅ Recipe CRUD operations
- ✅ Home feed with recipe discovery
- ✅ Search and filter recipes
- ✅ User profiles and follow system
- ✅ Favorites with Firebase sync
- ✅ Shopping list (local)
- ✅ Push notifications
- ✅ Recipe reviews and ratings
- ✅ Collection management
- 🚧 Shopping list sync (in progress)
- 🚧 Meal planning (planned)

## 📄 License

This project is currently proprietary. All rights reserved.

## 👥 Team

### Development Team
- **Sadmesuy** - Full Stack Developer
  - GitHub: [@Sad3esuy](https://github.com/Sad3esuy)

## 🙏 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Firebase** - Backend infrastructure
- **Node.js Community** - Server-side runtime
- **PostgreSQL** - Robust database system
- **Cloudinary** - Image CDN and storage
- **Material Design** - UI/UX guidelines

## 📞 Support & Contact

- **Email**: support@xemcook.com *(tạm thời chưa có)*
- **GitHub Issues**: [DA_App_XEMCook/issues](https://github.com/Sad3esuy/DA_App_XEMCook/issues)
- **Repository**: [DA_App_XEMCook](https://github.com/Sad3esuy/DA_App_XEMCook)

## 🗺️ Roadmap

### Version 1.0 (MVP) - Q1 2025
- [x] Core authentication
- [x] Recipe management
- [x] Social features (follow, like)
- [x] Search and discovery
- [x] Push notifications
- [ ] Shopping list sync
- [ ] Performance optimization
- [ ] Unit & Integration tests

### Version 1.1 - Q2 2025
- [ ] Meal planning calendar
- [ ] Recipe import from URL
- [ ] Offline mode enhancement
- [ ] Multi-language support (English, Vietnamese)
- [ ] Dark mode theme
- [ ] Recipe video support

### Version 2.0 - Q3 2025
- [ ] AI recipe suggestions
- [ ] Nutrition tracking
- [ ] Voice-guided cooking
- [ ] Social recipe challenges
- [ ] Recipe marketplace
- [ ] Advanced analytics

### Future Ideas
- [ ] AR cooking instructions
- [ ] Smart kitchen device integration
- [ ] Ingredient price comparison
- [ ] Meal prep planning
- [ ] Dietary restrictions filtering

---

Made with ❤️ by XEMCook Team | Flutter + Node.js + PostgreSQL + Firebase
