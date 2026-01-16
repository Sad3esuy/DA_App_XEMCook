import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../../theme/app_theme.dart';
import '../../model/auth.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'verify_pin_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Auth result = await _authService.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _emailSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Đã gửi mã PIN về email'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      // Điều hướng nhập PIN
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyPinScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      final message = (result.message ?? '').trim();
      final isGoogleAccount = message.toLowerCase().contains('google');

      if (isGoogleAccount) {
        // Trường hợp email thuộc tài khoản đăng nhập Google: hiển thị hướng dẫn thay vì gửi PIN
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tài khoản Google'),
            content: const Text(
              'Email này được đăng ký bằng Google nên không thể đặt lại mật khẩu bằng mã PIN. '
              'Vui lòng đổi mật khẩu trực tiếp trong tài khoản Google của bạn.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Gửi email thất bại'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                      size: 40,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _emailSent ? 'Kiểm tra Email' : 'Quên mật khẩu',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _emailSent
                      ? 'Chúng tôi đã gửi link đặt lại mật khẩu đến email của bạn'
                      : 'Nhập email để nhận link đặt lại mật khẩu',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                if (!_emailSent) ...[
                  // Email form
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'example@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetEmail,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Gửi email đặt lại mật khẩu',style: TextStyle(
                            fontSize: 16,
                          ),),
                    ),
                  ),
                ] else ...[
                  // Email sent notice
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Email đã được gửi!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng kiểm tra hộp thư của bạn (bao gồm cả thư mục spam) và làm theo hướng dẫn để đặt lại mật khẩu.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Resend email
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _emailSent = false);
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Gửi lại email'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryOrange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Back to login
                  SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Quay lại đăng nhập', style: TextStyle(fontSize: 16),),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Back to login (when email not sent yet)
                if (!_emailSent)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Quay lại đăng nhập'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
