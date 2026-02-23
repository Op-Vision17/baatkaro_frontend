import 'package:baatkaro/shared/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).resetOtpState();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .sendOtp(_emailController.text.trim());

    final state = ref.read(authControllerProvider);
    if (mounted) {
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
      } else if (state.otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to ${_emailController.text}')),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter OTP')));
      return;
    }

    final user = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(_emailController.text.trim(), _otpController.text.trim());

    if (!mounted) return;

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          print('🔔 Registering FCM token after login...');
          final registered = await ref.read(registerFcmTokenProvider.future);
          if (registered) {
            print('✅ FCM token registered successfully');
          } else {
            print('⚠️ FCM token registration returned false');
          }
        } catch (e) {
          print('⚠️ Failed to register FCM token: $e');
        }
      });

      if (user.needsOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Invalid OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Baatkaro Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60),

                // App Icon
                Image(image: AssetImage('assets/logo_header.png'), height: 100),
                SizedBox(height: 16),

                Text(
                  'Welcome to Baatkaro',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                SizedBox(height: 8),

                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  enabled: !authState.otpSent,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // OTP Field
                if (authState.otpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Check your email for the 6-digit code',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  SizedBox(height: 24),
                ],

                SizedBox(height: 8),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : (authState.otpSent ? _verifyOtp : _sendOtp),
                    child: authState.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryBlack,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(authState.otpSent ? 'Verify OTP' : 'Send OTP'),
                  ),
                ),

                // Back button if OTP sent
                if (authState.otpSent) ...[
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).resetOtpState();
                      _otpController.clear();
                    },
                    child: Text('Change Email'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
