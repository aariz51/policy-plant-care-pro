// lib/features/auth/screens/login_otp_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/custom_button.dart';

class LoginOtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const LoginOtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends ConsumerState<LoginOtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    final S = AppLocalizations.of(context)!;
    if (_pinController.text.length < 6) { // Assuming 6-digit OTP
      return;
    }
    setState(() => _isLoading = true);

    final success = await ref.read(userProfileNotifierProvider.notifier)
      .verifyLoginOtpAndSignIn(widget.phoneNumber, _pinController.text);
    
    if (mounted) {
      if (!success) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.invalidOtpError), backgroundColor: AppTheme.avoidRed)
        );
      }
      // On success, the AppRouter's redirect logic will automatically navigate to home.
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: AppTheme.textPrimary),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(S.otpVerificationTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                S.enterOtpSentTo(widget.phoneNumber),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Pinput(
                length: 6,
                controller: _pinController,
                focusNode: _pinFocusNode,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.primaryBlue),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyWith(
                  decoration: BoxDecoration(
                    color: AppTheme.avoidRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.avoidRed),
                  )
                ),
                onCompleted: (pin) => _verifyOtp(),
              ),
              const SizedBox(height: 32),
              CustomElevatedButton(
                text: S.verifyOtpButtonLabel,
                isLoading: _isLoading,
                onPressed: _verifyOtp,
              ),
              // Optional: Add a resend OTP button here if needed
            ],
          ),
        ),
      ),
    );
  }
}