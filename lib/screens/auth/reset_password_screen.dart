import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String pin;
  const ResetPasswordScreen({super.key, required this.email, required this.pin});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final res = await _authService.resetPasswordWithPin(
      email: widget.email,
      pin: widget.pin,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Đổi mật khẩu thành công'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Đổi mật khẩu thất bại'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _newController,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    final val = v ?? '';
                    if (val.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v != _newController.text) return 'Mật khẩu không khớp';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 62,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Đổi mật khẩu', style: TextStyle(fontSize: 16),),
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

