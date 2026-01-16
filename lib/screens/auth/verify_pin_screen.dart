import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'reset_password_screen.dart';

class VerifyPinScreen extends StatefulWidget {
  final String email;
  const VerifyPinScreen({super.key, required this.email});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final res = await _authService.verifyResetPin(
      email: widget.email,
      pin: _pinController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (res.isSuccess) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            pin: _pinController.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Mã PIN không hợp lệ hoặc đã hết hạn'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập mã PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nhập mã PIN đã gửi tới ${widget.email}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Mã PIN 6 chữ số',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.length != 6 || int.tryParse(val) == null) {
                      return 'Mã PIN không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 62,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Xác minh mã PIN', style: TextStyle(fontSize: 16),),
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

