import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'xemcook_users';
  static const String _currentUserKey = 'xemcook_current_user';

  // Đăng ký người dùng mới
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Mô phỏng network delay

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));

      // Kiểm tra email đã tồn tại
      if (users.containsKey(email)) {
        return AuthResult(
          success: false,
          message: 'Email đã được sử dụng. Vui lòng thử email khác.',
        );
      }

      // Lưu thông tin người dùng
      users[email] = {
        'fullName': fullName,
        'email': email,
        'password': password, // Trong thực tế, phải hash password
        'createdAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_usersKey, jsonEncode(users));

      // Tự động đăng nhập sau khi đăng ký
      await prefs.setString(_currentUserKey, email);

      return AuthResult(
        success: true,
        message: 'Đăng ký thành công!',
        user: UserData(fullName: fullName, email: email),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }

  // Đăng nhập
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));

      if (!users.containsKey(email)) {
        return AuthResult(
          success: false,
          message: 'Email không tồn tại.',
        );
      }

      final userData = users[email];
      if (userData['password'] != password) {
        return AuthResult(
          success: false,
          message: 'Mật khẩu không chính xác.',
        );
      }

      await prefs.setString(_currentUserKey, email);

      return AuthResult(
        success: true,
        message: 'Đăng nhập thành công!',
        user: UserData(
          fullName: userData['fullName'],
          email: userData['email'],
        ),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }

  // Quên mật khẩu (Gửi mã xác nhận)
  Future<AuthResult> forgotPassword(String email) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));

      if (!users.containsKey(email)) {
        return AuthResult(
          success: false,
          message: 'Email không tồn tại trong hệ thống.',
        );
      }

      // Mô phỏng gửi email (trong thực tế sẽ gửi OTP qua email)
      final verificationCode = '123456'; // Code mẫu
      await prefs.setString('reset_code_$email', verificationCode);
      await prefs.setString('reset_email', email);

      return AuthResult(
        success: true,
        message: 'Mã xác nhận đã được gửi đến email của bạn.\nMã xác nhận: $verificationCode',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }

  // Xác nhận mã và đặt lại mật khẩu
  Future<AuthResult> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('reset_email');
      
      if (email == null) {
        return AuthResult(
          success: false,
          message: 'Phiên làm việc đã hết hạn.',
        );
      }

      final savedCode = prefs.getString('reset_code_$email');
      
      if (savedCode != code) {
        return AuthResult(
          success: false,
          message: 'Mã xác nhận không chính xác.',
        );
      }

      // Cập nhật mật khẩu mới
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));
      
      if (users.containsKey(email)) {
        users[email]['password'] = newPassword;
        await prefs.setString(_usersKey, jsonEncode(users));
        
        // Xóa mã xác nhận
        await prefs.remove('reset_code_$email');
        await prefs.remove('reset_email');

        return AuthResult(
          success: true,
          message: 'Đặt lại mật khẩu thành công!',
        );
      }

      return AuthResult(
        success: false,
        message: 'Không tìm thấy tài khoản.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }

  // Kiểm tra trạng thái đăng nhập
  Future<UserData?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_currentUserKey);
    
    if (email == null) return null;

    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));
    
    if (users.containsKey(email)) {
      final userData = users[email];
      return UserData(
        fullName: userData['fullName'],
        email: userData['email'],
      );
    }
    
    return null;
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}

class AuthResult {
  final bool success;
  final String message;
  final UserData? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class UserData {
  final String fullName;
  final String email;

  UserData({
    required this.fullName,
    required this.email,
  });
}