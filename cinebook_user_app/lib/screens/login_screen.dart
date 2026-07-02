import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _requestOtp() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.post('/auth/request-otp', data: {'phone': _phoneController.text});
      setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.post('/auth/verify-otp', data: {
        'phone': _phoneController.text,
        'code': _otpController.text,
      });
      if (mounted) {
        context.read<AuthBloc>().add(AuthLoggedIn(
          accessToken: res.data['accessToken'],
          refreshToken: res.data['refreshToken'],
          role: res.data['role'],
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to CineBook')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              enabled: !_otpSent,
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'OTP Code'),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading) const CircularProgressIndicator()
            else ElevatedButton(
              onPressed: _otpSent ? _verifyOtp : _requestOtp,
              child: Text(_otpSent ? 'Verify OTP' : 'Request OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
