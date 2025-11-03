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
