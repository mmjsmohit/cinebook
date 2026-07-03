import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _requestOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.post(
        '/auth/request-otp',
        data: {'phone': _phoneController.text},
      );
      setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: CinemaColors.neonRed),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.post(
        '/auth/verify-otp',
        data: {'phone': _phoneController.text, 'code': _otpController.text},
      );
      if (mounted) {
        context.read<AuthBloc>().add(
          AuthLoggedIn(
            accessToken: res.data['accessToken'],
            refreshToken: res.data['refreshToken'],
            role: res.data['user']['role'],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: CinemaColors.neonRed),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CinemaColors.neonRed.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CinemaColors.warmAmber.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo & Tagline
                    const Icon(
                      Icons.movie_creation_rounded,
                      size: 72,
                      color: CinemaColors.neonRed,
                    ).animate().fadeIn(duration: 600.ms).scale(),
                    const SizedBox(height: 16),
                    Text(
                      'CineBook',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: CinemaColors.offWhite,
                          ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: 8),
                    Text(
                      'Your ultimate movie experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: CinemaColors.steelGray,
                          ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 48),

                    // Glassmorphism Form Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: CinemaColors.inkCharcoal.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: CinemaColors.structuralBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 400),
                            crossFadeState: _otpSent
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: _buildPhoneStep(),
                            secondChild: _buildOtpStep(),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your phone number to continue',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CinemaColors.steelGray,
              ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: CinemaColors.offWhite, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_android, color: CinemaColors.steelGray),
            filled: true,
            fillColor: CinemaColors.deepCharcoal.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: CinemaColors.neonRed, width: 1),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _requestOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: CinemaColors.neonRed,
            foregroundColor: CinemaColors.offWhite,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: CinemaColors.neonRed.withValues(alpha: 0.5),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: CinemaColors.offWhite,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: CinemaColors.steelGray),
              onPressed: () => setState(() => _otpSent = false),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            Text(
              'Verify Code',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the code sent to ${_phoneController.text}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CinemaColors.steelGray,
              ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: CinemaColors.offWhite, fontSize: 16, letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'OTP Code',
            filled: true,
            fillColor: CinemaColors.deepCharcoal.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: CinemaColors.neonRed, width: 1),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: CinemaColors.neonRed,
            foregroundColor: CinemaColors.offWhite,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: CinemaColors.neonRed.withValues(alpha: 0.5),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: CinemaColors.offWhite,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Verify & Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
      ),
    );
  }
}
