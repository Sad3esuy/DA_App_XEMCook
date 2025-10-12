import 'user.dart';
/// Model chung xử lý tất cả request và response liên quan đến authentication
class Auth {
  // ========== PROPERTIES ==========
  
  // Request data
  final String? fullName;
  final String? email;
  final String? password;
  final String? confirmPassword;
  final String? currentPassword;
  final String? newPassword;
  final String? bio;
  final String? avatar;

  // Response data
  final bool? success;
  final String? message;
  final User? user;
  final String? token;
  final String? error;

  Auth({
    // Request fields
    this.fullName,
    this.email,
    this.password,
    this.confirmPassword,
    this.currentPassword,
    this.newPassword,
    this.bio,
    this.avatar,
    
    // Response fields
    this.success,
    this.message,
    this.user,
    this.token,
    this.error,
  });

  // ========== NAMED CONSTRUCTORS CHO REQUEST ==========

  /// Tạo request đăng ký
  Auth.register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) : this(
          fullName: fullName,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        );

  /// Tạo request đăng nhập
  Auth.login({
    required String email,
    required String password,
  }) : this(
          email: email,
          password: password,
        );

  /// Tạo request đổi mật khẩu
  Auth.changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) : this(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );

  /// Tạo request cập nhật profile
  Auth.updateProfile({
    String? fullName,
    String? bio,
    String? avatar,
  }) : this(
          fullName: fullName,
          bio: bio,
          avatar: avatar,
        );

  // ========== NAMED CONSTRUCTOR CHO RESPONSE ==========

  /// Parse response từ API (đăng ký/đăng nhập)
  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      success: json['success'],
      message: json['message'],
      user: json['data'] != null && json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
      token: json['data']?['token'],
      error: json['error'],
    );
  }

  /// Parse response từ API - dạng đơn giản (chỉ có user, không có token)
  factory Auth.fromUserJson(Map<String, dynamic> json) {
    return Auth(
      success: json['success'],
      message: json['message'],
      user: json['data'] != null ? User.fromJson(json['data']) : null,
      error: json['error'],
    );
  }

  /// Parse response từ API - dạng message only
  factory Auth.fromMessageJson(Map<String, dynamic> json) {
    return Auth(
      success: json['success'],
      message: json['message'],
      error: json['error'],
    );
  }

  // ========== TO JSON CHO REQUEST ==========

  /// Chuyển đổi sang JSON để gửi request
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Chỉ thêm các trường không null vào JSON
    if (fullName != null) data['fullName'] = fullName;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (confirmPassword != null) data['confirmPassword'] = confirmPassword;
    if (currentPassword != null) data['currentPassword'] = currentPassword;
    if (newPassword != null) data['newPassword'] = newPassword;
    if (bio != null) data['bio'] = bio;
    if (avatar != null) data['avatar'] = avatar;

    return data;
  }

  // ========== HELPER METHODS ==========

  /// Kiểm tra response có thành công không
  bool get isSuccess => success == true;

  /// Kiểm tra có lỗi không
  bool get hasError => success == false;

  /// Kiểm tra có token không (đã đăng nhập thành công)
  bool get hasToken => token != null && token!.isNotEmpty;

  /// Copy với một số field được cập nhật
  Auth copyWith({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    String? currentPassword,
    String? newPassword,
    String? bio,
    String? avatar,
    bool? success,
    String? message,
    User? user,
    String? token,
    String? error,
  }) {
    return Auth(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      success: success ?? this.success,
      message: message ?? this.message,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error ?? this.error,
    );
  }
}