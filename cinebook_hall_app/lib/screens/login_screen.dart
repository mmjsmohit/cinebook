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
          role: res.data['user']['role'],
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
    final theme = Theme.of(context);
    final cinemaExt = theme.extension<CinemaThemeExtension>();
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Glowing cinema icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CinemaColors.inkCharcoal,
                    boxShadow: cinemaExt?.neonGlow,
                  ),
                  child: const Icon(Icons.movie_filter, size: 48, color: CinemaColors.neonRed),
                ),
                const SizedBox(height: 24),
                Text('CineBook', style: theme.textTheme.displayMedium),
                const SizedBox(height: 4),
                Text('Hall Manager', style: theme.textTheme.bodyMedium?.copyWith(color: CinemaColors.steelGray)),
                const SizedBox(height: 48),
                // Login card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                            prefixText: '+91 ',
                          ),
                          keyboardType: TextInputType.phone,
                          enabled: !_otpSent,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _otpSent
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: TextField(
                                    controller: _otpController,
                                    decoration: const InputDecoration(
                                      labelText: 'OTP Code',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    keyboardType: TextInputType.number,
                                    autofocus: true,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          ElevatedButton(
                            onPressed: _otpSent ? _verifyOtp : _requestOtp,
                            child: Text(_otpSent ? 'Verify OTP' : 'Request OTP'),
                          ),
                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _requestOtp,
                              child: const Text('Resend OTP'),
                            ),
                          ),
                        ],
                      ],
                    ),
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
