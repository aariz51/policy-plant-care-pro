// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/custom_button.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pinput/pinput.dart';

// UI State Providers for this screen
final _isPhoneResetProvider = StateProvider<bool>((ref) => false);
final _isLoadingProvider = StateProvider<bool>((ref) => false);
final _showOtpInputProvider = StateProvider<bool>((ref) => false);

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Country _selectedCountry = Country.parse('IN');

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Logic for Email Reset ---
  Future<void> _sendEmailResetLink() async {
    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      messenger.showSnackBar(SnackBar(content: Text(S.enterValidEmailError)));
      return;
    }
    ref.read(_isLoadingProvider.notifier).state = true;
    final success = await ref.read(userProfileNotifierProvider.notifier).sendPasswordResetEmail(_emailController.text.trim());
    ref.read(_isLoadingProvider.notifier).state = false;

    if (success && mounted) {
      showDialog(context: context, builder: (_) => AlertDialog(title: Text(S.passwordResetLinkSentTitle), content: Text(S.passwordResetLinkSentMessage(_emailController.text.trim())), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.ok))]));
    } else if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(S.passwordResetFailedError), backgroundColor: AppTheme.avoidRed));
    }
  }

  // --- Logic for Phone Reset ---
  Future<void> _sendPhoneResetOtp() async {
    final S = AppLocalizations.of(context)!;
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.enterMobileNumberError)));
      return;
    }
    ref.read(_isLoadingProvider.notifier).state = true;
    final success = await ref.read(userProfileNotifierProvider.notifier).sendPasswordResetOtp(
      _phoneController.text.trim(),
      _selectedCountry.phoneCode,
    );
    ref.read(_isLoadingProvider.notifier).state = false;
    
    if (success) {
      ref.read(_showOtpInputProvider.notifier).state = true;
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.failedToSendOtp), backgroundColor: AppTheme.avoidRed));
    }
  }
  
  Future<void> _verifyOtpAndResetPassword() async {
    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (!_formKey.currentState!.validate()) {
        return;
    }

    ref.read(_isLoadingProvider.notifier).state = true;
    
    // Get the user profile provider to access the email lookup and login
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    
    final success = await userProfileNotifier.verifyAndResetPassword(
      _phoneController.text.trim(),
      _selectedCountry.phoneCode,
      _otpController.text,
      _passwordController.text,
    );
    
    if (success && mounted) {
      // Password reset successful - now auto-login
      messenger.showSnackBar(const SnackBar(
        content: Text("Password reset successful! Logging you in..."),
        backgroundColor: AppTheme.safeGreen,
      ));
      
      // Try to auto-login with the phone number to find the email and login
      final autoLoginSuccess = await userProfileNotifier.autoLoginAfterPasswordReset(
        _phoneController.text.trim(),
        _selectedCountry.phoneCode,
        _passwordController.text,
      );
      
      ref.read(_isLoadingProvider.notifier).state = false;
      
      if (autoLoginSuccess && mounted) {
        // Successfully logged in - go to home
        context.go('/home');
      } else if (mounted) {
        // Auto-login failed - fallback to login screen
        await showDialog(
          context: context, 
          builder: (_) => AlertDialog(
            title: const Text("Success!"), 
            content: const Text("Your password has been reset. Please log in with your new password."), 
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))
            ]
          )
        );
        if(mounted) context.go('/login');
      }
    } else {
      ref.read(_isLoadingProvider.notifier).state = false;
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text("Failed to reset password. The OTP may be incorrect or expired."), 
          backgroundColor: AppTheme.avoidRed
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final isPhoneReset = ref.watch(_isPhoneResetProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text(S.forgotPasswordTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(S.emailLabel), icon: const Icon(Icons.email_outlined)),
                  ButtonSegment(value: true, label: Text(S.mobileNumberLabel), icon: const Icon(Icons.phone_android_outlined)),
                ],
                selected: {isPhoneReset},
                onSelectionChanged: (s) {
                  ref.read(_isPhoneResetProvider.notifier).state = s.first;
                  ref.read(_showOtpInputProvider.notifier).state = false;
                },
              ),
              const SizedBox(height: 24),
              if (isPhoneReset)
                _buildPhoneResetForm(S)
              else
                _buildEmailResetForm(S),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailResetForm(AppLocalizations S) {
    final isLoading = ref.watch(_isLoadingProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(S.forgotPasswordInstructions, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(labelText: S.emailLabel),
          keyboardType: TextInputType.emailAddress,
          validator: (val) => (val == null || !val.contains('@')) ? S.enterValidEmailError : null,
        ),
        const SizedBox(height: 24),
        CustomElevatedButton(
          onPressed: isLoading ? null : _sendEmailResetLink,
          text: S.sendResetLinkButton,
          isLoading: isLoading,
        ),
      ],
    );
  }
  
  Widget _buildPhoneResetForm(AppLocalizations S) {
    final isLoading = ref.watch(_isLoadingProvider);
    final showOtp = ref.watch(_showOtpInputProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(showOtp ? "Enter the OTP and your new password." : S.forgotPasswordPhoneInstructions, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (!showOtp) ...[
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: S.mobileNumberLabel,
              prefixIcon: InkWell(
                onTap: () => showCountryPicker(context: context, onSelect: (c) => setState(() => _selectedCountry = c)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 12), Text(_selectedCountry.flagEmoji),
                  const SizedBox(width: 4), Text("+${_selectedCountry.phoneCode}"),
                  const Icon(Icons.arrow_drop_down), const SizedBox(width: 4),
                ]),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (val) => (val == null || val.isEmpty) ? S.enterMobileNumberError : null,
          ),
          const SizedBox(height: 24),
          CustomElevatedButton(
            text: S.sendOtpButtonLabel,
            onPressed: isLoading ? null : _sendPhoneResetOtp,
            isLoading: isLoading,
          ),
        ] else ...[
          Pinput(controller: _otpController, length: 6, autofocus: true, validator: (val) => (val == null || val.length < 6) ? "Enter the full OTP" : null),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController, 
            obscureText: true, 
            decoration: InputDecoration(labelText: S.newPasswordLabel),
            validator: (val) => (val == null || val.length < 8) ? "Password must be 8+ characters." : null
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Confirm New Password"),
            validator: (val) => (val != _passwordController.text) ? "Passwords do not match." : null
          ),
          const SizedBox(height: 24),
          CustomElevatedButton(
            text: S.resetPasswordButton,
            onPressed: isLoading ? null : _verifyOtpAndResetPassword,
            isLoading: isLoading,
          ),
        ],
      ],
    );
  }
}