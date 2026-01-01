import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'push_notification_service.dart';
// Import models của bạn
import '../model/user.dart';
import '../model/auth.dart';
import '../model/chef_profile.dart';

/// Service xử lý tất cả API calls liên quan đến Authentication và User
class AuthService {
  // ========== CONFIG ==========
  
  // // Base URL của API backend
  // static const String baseUrl = 'https://be-da-xemcook-app.onrender.com/api';
  
  // /// Test kết nối đến server
  // Future<bool> testConnection() async {
  //   try {
  //     print('Testing connection to: $baseUrl');
  //     // Thử kết nối đến endpoint auth để test
  //     final response = await http.get(
  //       Uri.parse('$_authEndpoint/test'),
  //       headers: _getHeaders(),
  //     ).timeout(const Duration(seconds: 30));
      
  //     print('Connection test response: ${response.statusCode}');
  //     print('Connection test body: ${response.body}');
  //     // Chấp nhận cả 200 và 404 (endpoint không tồn tại nhưng server phản hồi)
  //     return response.statusCode == 200 || response.statusCode == 404;
  //   } catch (e) {
  //     print('Connection test failed: $e');
  //     return false;
  //   }
  // }

  // Base URL của API backend
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  /// Test kết nối đến server
  Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl');
      // Thử kết nối đến endpoint auth để test
      final response = await http.get(
        Uri.parse('$_authEndpoint/test'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      print('Connection test response: ${response.statusCode}');
      print('Connection test body: ${response.body}');
      // Chấp nhận cả 200 và 404 (endpoint không tồn tại nhưng server phản hồi)
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  /// Debug method để test login với response chi tiết
  Future<void> debugLogin(String email, String password) async {
    try {
      print('=== DEBUG LOGIN ===');
      print('Email: $email');
      print('URL: $_authEndpoint/login');
      
      final request = Auth.login(email: email, password: password);
      print('Request body: ${jsonEncode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$_authEndpoint/login'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          print('Parsed JSON: $jsonData');
          final auth = _parseAuthResponse(jsonData);
          print('Parsed Auth: success=${auth.isSuccess}, message=${auth.message}');
        } catch (parseError) {
          print('Parse error: $parseError');
        }
      }
    } catch (e) {
      print('Debug login error: $e');
    }
  }
  
  // Endpoints
  static const String _authEndpoint = '$baseUrl/auth';
  static const String _usersEndpoint = '$baseUrl/users';
  
  // Key để lưu token trong SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // ========== TOKEN MANAGEMENT ==========
  
  /// Lưu token vào local storage
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Lấy token từ local storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Xóa token khỏi local storage
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Lưu thông tin user vào local storage
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Lấy thông tin user từ local storage
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  /// Kiểm tra user đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ========== HEADERS ==========
  
  /// Tạo headers cho request (không có token)
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Tạo headers cho request có token (authenticated)
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ========== ERROR HANDLING ==========
  
  /// Xử lý response từ API
  Auth _handleResponse(http.Response response) {
    try {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Parsing successful response...');
        // Thử parse với cấu trúc linh hoạt hơn
        return _parseAuthResponse(jsonData);
      } else {
        // Trả về response với error
        print('Error response received');
        return Auth(
          success: false,
          message: jsonData['message'] ?? 'Đã có lỗi xảy ra',
          error: jsonData['error'],
        );
      }
    } catch (e) {
      print('Error parsing response: $e');
      print('Raw response body: ${response.body}');
      return Auth(
        success: false,
        message: 'Lỗi xử lý response từ server',
        error: e.toString(),
      );
    }
  }

  /// Parse response với cấu trúc linh hoạt
  Auth _parseAuthResponse(Map<String, dynamic> jsonData) {
    try {
      // Thử parse với cấu trúc chuẩn trước
      return Auth.fromJson(jsonData);
    } catch (e) {
      print('Failed to parse with standard structure: $e');
      
      // Thử parse với cấu trúc đơn giản hơn
      try {
        final success = jsonData['success'] ?? true;
        final message = jsonData['message'] ?? 'Thành công';
        final token = jsonData['token'] ?? jsonData['data']?['token'];
        // Hỗ trợ cả dạng data.user và data (user object trực tiếp)
        dynamic userData = jsonData['user'] ?? jsonData['data']?['user'];
        if (userData == null && jsonData['data'] is Map) {
          final d = jsonData['data'] as Map;
          final looksLikeUser = d.containsKey('id') && (d.containsKey('email') || d.containsKey('fullName'));
          if (looksLikeUser) userData = d;
        }
        
        User? user;
        if (userData != null) {
          try {
            user = User.fromJson(userData);
          } catch (userError) {
            print('Failed to parse user: $userError');
            // Tạo user đơn giản với dữ liệu có sẵn
            user = User(
              id: userData['id']?.toString() ?? userData['_id']?.toString() ?? 'unknown',
              fullName: userData['fullName'] ?? userData['name'] ?? 'User',
              email: userData['email'] ?? '',
              avatar: userData['avatar'] ?? userData['photoURL'],
              bio: userData['bio'],
              authProvider: userData['authProvider'] ?? 'local',
              isActive: userData['isActive'] ?? true,
              lastLogin: userData['lastLogin'] != null 
                  ? DateTime.tryParse(userData['lastLogin']) 
                  : null,
              createdAt: userData['createdAt'] != null 
                  ? DateTime.tryParse(userData['createdAt']) ?? DateTime.now()
                  : DateTime.now(),
              updatedAt: userData['updatedAt'] != null 
                  ? DateTime.tryParse(userData['updatedAt']) ?? DateTime.now()
                  : DateTime.now(),
            );
          }
        }
        
        return Auth(
          success: success,
          message: message,
          user: user,
          token: token,
          error: jsonData['error'],
        );
      } catch (fallbackError) {
        print('Failed to parse with fallback structure: $fallbackError');
        return Auth(
          success: false,
          message: 'Không thể parse response từ server',
          error: fallbackError.toString(),
        );
      }
    }
  }

  /// Xử lý exception
  Auth _handleException(dynamic error) {
    print('API Error: $error');
    return Auth(
      success: false,
      message: 'Không thể kết nối đến server',
      error: error.toString(),
    );
  }

  // ========== AUTH APIs ==========
  
  /// Đăng ký tài khoản mới
  /// 
  /// POST /api/auth/register
  Future<Auth> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final request = Auth.register(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      final response = await http.post(
        Uri.parse('$_authEndpoint/register'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      final result = _handleResponse(response);

      // Nếu đăng ký thành công, lưu token và user
      if (result.isSuccess && result.hasToken) {
        await saveToken(result.token!);
        if (result.user != null) {
          await saveUser(result.user!);
        }
      }

      return result;
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Quên mật khẩu - gửi email đặt lại
  ///
  /// POST /api/auth/forgot-password
  Future<Auth> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_authEndpoint/forgot-password'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email.trim()}),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Xác minh mã PIN đặt lại mật khẩu
  ///
  /// POST /api/auth/verify-reset-pin
  Future<Auth> verifyResetPin({
    required String email,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_authEndpoint/verify-reset-pin'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'pin': pin.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      return _parseAuthResponse(jsonDecode(response.body));
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Đặt lại mật khẩu bằng token
  ///
  /// POST /api/auth/reset-password
  Future<Auth> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_authEndpoint/reset-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Đặt lại mật khẩu bằng email + PIN
  ///
  /// POST /api/auth/reset-password (email+pin)
  Future<Auth> resetPasswordWithPin({
    required String email,
    required String pin,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_authEndpoint/reset-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'pin': pin.trim(),
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      return _parseAuthResponse(jsonDecode(response.body));
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Đăng nhập
  /// 
  /// POST /api/auth/login
  Future<Auth> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = Auth.login(
        email: email,
        password: password,
      );

      final response = await http.post(
        Uri.parse('$_authEndpoint/login'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 5)); ////30

      final result = _handleResponse(response);

      // Nếu đăng nhập thành công, lưu token và user
      if (result.isSuccess && result.hasToken) {
        await saveToken(result.token!);
        if (result.user != null) {
          await saveUser(result.user!);
        }
        await PushNotificationService.syncTokenWithBackend();
      }

      return result;
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Đăng xuất
  /// 
  /// POST /api/auth/logout
  Future<Auth> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$_authEndpoint/logout'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      // Xóa token và user data dù API có thành công hay không
      await PushNotificationService.unregisterToken();
      await removeToken();
      
      // Đăng xuất khỏi Google nếu có
      await signOutGoogle();

      return _parseAuthResponse(jsonDecode(response.body));
    } catch (e) {
      // Vẫn xóa token nếu có lỗi
      await PushNotificationService.unregisterToken();
      await removeToken();
      await signOutGoogle();
      return _handleException(e);
    }
  }

  /// Lấy thông tin user hiện tại từ server
  /// 
  /// GET /api/auth/me
  Future<Auth> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$_authEndpoint/me'),
        headers: await _getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      final result = _parseAuthResponse(jsonDecode(response.body));

      // Cập nhật user data trong local storage
      if (result.isSuccess && result.user != null) {
        await saveUser(result.user!);
      }

      return result;
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Cập nhật thông tin profile
  /// 
  /// PUT /api/auth/profile
  Future<Auth> updateProfile({
    String? fullName,
    String? bio,
    String? avatar,
    String? avatarUploadBase64,
  }) async {
    try {
      final request = Auth.updateProfile(
        fullName: fullName,
        bio: bio,
        avatar: avatar,
      );
      // Gửi avatarUpload nếu có (data URI)
      final Map<String, dynamic> body = request.toJson();
      if (avatarUploadBase64 != null && avatarUploadBase64.isNotEmpty) {
        body['avatarUpload'] = avatarUploadBase64;
      }

      final response = await http.put(
        Uri.parse('$_authEndpoint/profile'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      final result = _handleResponse(response);

      // Cập nhật user data trong local storage
      if (result.isSuccess && result.user != null) {
        await saveUser(result.user!);
      }

      return result;
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Đổi mật khẩu
  /// 
  /// PUT /api/auth/change-password
  Future<Auth> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final request = Auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      final response = await http.put(
        Uri.parse('$_authEndpoint/change-password'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      return _parseAuthResponse(jsonDecode(response.body));
    } catch (e) {
      return _handleException(e);
    }
  }

  // ========== USER APIs ==========

  /// Lấy thông tin user theo ID
  /// 
  /// GET /api/users/:id
  Future<Auth> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_usersEndpoint/$userId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return _parseAuthResponse(jsonDecode(response.body));
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Lấy hồ sơ chef (public profile gồm công thức & bộ sưu tập công khai)
  Future<ChefProfile?> getChefProfile(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_usersEndpoint/$userId'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          final data = decoded['data'];
          if (data is Map) {
            return ChefProfile.fromJson(
              Map<String, dynamic>.from(data),
            );
          }
        }
      } else {
        print('Failed to fetch chef profile (status: ${response.statusCode})');
      }
    } catch (e) {
      print('Get chef profile error: $e');
    }
    return null;
  }

  /// Lấy thống kê của user
  /// 
  /// GET /api/users/:id/stats
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_usersEndpoint/$userId/stats'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return UserStats.fromJson(jsonData['data']);
        }
      }
      return null;
    } catch (e) {
      print('Get stats error: $e');
      return null;
    }
  }

  /// Xóa tài khoản
  /// 
  /// DELETE /api/users/account
  Future<Auth> deleteAccount({String? password, String? confirm}) async {
    try {
      final Map<String, dynamic> body = {};
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }
      if (confirm != null && confirm.isNotEmpty) {
        body['confirm'] = confirm;
      }

      final response = await http.delete(
        Uri.parse('$_usersEndpoint/account'),
        headers: await _getAuthHeaders(),
        body: body.isNotEmpty ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      // Xóa token và user data sau khi xóa tài khoản
      if (response.statusCode == 200) {
        await removeToken();
      }

      return _parseAuthResponse(jsonDecode(response.body));
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Tiện ích: Xóa tài khoản Google (tự gửi confirm = 'delete')
  Future<Auth> deleteGoogleAccount() {
    return deleteAccount(confirm: 'delete');
  }

  // ========== GOOGLE AUTH ==========
  
  /// Đăng nhập với Google
  /// Sử dụng google_sign_in package để đăng nhập và gửi token về backend
  Future<Auth> signInWithGoogle() async {
    try {
      // Import google_sign_in package
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Dùng Web OAuth Client ID cùng project với google-services.json
        serverClientId: '308407775839-4eebp9qjtvqt06mshmdphs2gdduhd4ai.apps.googleusercontent.com',
      );
      
      // Đăng nhập Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return Auth(
          success: false,
          message: 'Đăng nhập Google đã bị hủy',
        );
      }

      // Lấy thông tin authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Gửi token đến backend để xác thực
      final response = await http.post(
        Uri.parse('$_authEndpoint/google/callback'),
        headers: _getHeaders(),
        body: jsonEncode({
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
          'email': googleUser.email,
          'fullName': googleUser.displayName,
          'avatar': googleUser.photoUrl,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(response);

      // Nếu đăng nhập thành công, lưu token và user
      if (result.isSuccess && result.hasToken) {
        await saveToken(result.token!);
        if (result.user != null) {
          await saveUser(result.user!);
        }
      }

      return result;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return Auth(
        success: false,
        message: 'Lỗi đăng nhập Google: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  /// Đăng xuất khỏi Google
  Future<void> signOutGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      print('Google Sign-Out Error: $e');
    }
  }

  /// Mở Google OAuth URL (dành cho web)
  /// 
  /// GET /api/auth/google
  String getGoogleAuthUrl() {
    return '$_authEndpoint/google';
  }

  /// Xử lý callback từ Google OAuth (sau khi redirect về app)
  /// 
  /// Token sẽ được truyền vào từ deep link
  Future<void> handleGoogleCallback(String token) async {
    await saveToken(token);
    
    // Lấy thông tin user sau khi đăng nhập Google
    await getMe();
  }
}
