// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/services/device_info_service.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/widgets/custom_button.dart';
import 'package:country_picker/country_picker.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loadingSocialProvider;
  
  bool _isLoginWithPhone = false; 
  Country _selectedCountry = Country(
      phoneCode: '91',
      countryCode: 'IN',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'India',
      example: '9123456789',
      displayName: 'India (IN) [+91]',
      displayNameNoCountryCode: 'India (IN)',
      e164Key: '91-IN-0');

  final String _googleIconPath = 'assets/icons/icon_google.png';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkAndUpdateDeviceId(BuildContext context, String userId, UserProfileProvider userProvider) async {
    if (userProvider.userProfile == null) return;
    if (userProvider.userProfile!.deviceId == null || userProvider.userProfile!.deviceId!.isEmpty) {
        final String? deviceId = await DeviceInfoService.getDeviceId();
        if (deviceId != null && deviceId.isNotEmpty) {
            await userProvider.updateSingleProfileField({'device_id': deviceId});
        }
    }
  }
  
  // --- FIX: Added the missing _signInWithEmail method ---
  Future<void> _signInWithEmail() async {
    final S = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; _loadingSocialProvider = null; });

    final userProfileProvider = ref.read(userProfileNotifierProvider);
    final success = await userProfileProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text, // No trim on password
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.loginFailedCheckCredentials), backgroundColor: AppTheme.avoidRed)
        );
      } else {
        final signedInUserId = userProfileProvider.userProfile?.id;
        if (signedInUserId != null) {
             await _checkAndUpdateDeviceId(context, signedInUserId, userProfileProvider);
        }
      }
    }
  }

  // --- FIX: Added the missing _signInWithSocial method ---
  Future<void> _signInWithSocial(OAuthProvider providerType) async {
    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isLoading = true;
      _loadingSocialProvider = (providerType == OAuthProvider.google) ? 'google' : 'facebook';
    });

    final userProfileProvider = ref.read(userProfileNotifierProvider);
    bool initiated = await userProfileProvider.signInWithGoogle(); 

    if (mounted) {
      if (!initiated) {
        messenger.showSnackBar(SnackBar(
          content: Text(S.signInFailedError("${providerType.name} Sign-In failed to initiate.")),
          backgroundColor: AppTheme.avoidRed,
        ));
        setState(() { _isLoading = false; _loadingSocialProvider = null; });
      }
    }
  }

  Future<void> _sendLoginOtp() async {
    final S = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });

    final fullPhoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
    
    final success = await ref.read(userProfileNotifierProvider.notifier).sendLoginOtp(fullPhoneNumber);

    if (mounted) {
      setState(() { _isLoading = false; });
      if (success) {
        // Navigate to the Login OTP Verification screen
        // IMPORTANT: Ensure you have a route for '/login-otp-verify' in your AppRouter
        context.push('/login-otp-verify', extra: fullPhoneNumber);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.failedToSendOtp), backgroundColor: AppTheme.avoidRed)
        );
      }
    }
  }

  // --- FIX: Passed BuildContext to access 'S' ---
  void _showCountryPicker(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
        inputDecoration: InputDecoration(
          labelText: S.searchCountryLabel, // Now works
          hintText: S.searchCountryHint,  // Now works
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.dividerColor.withOpacity(0.2))),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(S.welcomeBackTitle, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(S.loginSubtitle, style: textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 24),

                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment<bool>(value: false, label: Text(S.emailLabel), icon: const Icon(Icons.email_outlined)),
                          ButtonSegment<bool>(value: true, label: Text(S.mobileNumberLabel), icon: const Icon(Icons.phone_outlined)),
                        ],
                        selected: {_isLoginWithPhone},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isLoginWithPhone = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      if (!_isLoginWithPhone) ...[
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: S.emailLabel),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.contains('@')) { return S.enterValidEmailError; }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: S.passwordLabel,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.iconColor),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) { return S.enterPasswordError; }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: S.mobileNumberLabel,
                            prefixIcon: InkWell(
                              onTap: () => _showCountryPicker(context), // Pass context
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 12),
                                  Text(_selectedCountry.flagEmoji, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 4),
                                  Text("+${_selectedCountry.phoneCode}"),
                                  const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) { return S.enterMobileNumberError; }
                            return null;
                          },
                        )
                      ],

                      if (!_isLoginWithPhone) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isLoading ? null : () => GoRouter.of(context).push(AppRouter.forgotPasswordPath),
                              child: Text(S.forgotPasswordLink, style: textTheme.bodyMedium?.copyWith(color: AppTheme.primaryBlue))
                            )
                          ]
                        ),
                        const SizedBox(height: 24),
                        // --- FIX: Corrected method call ---
                        _isLoading && _loadingSocialProvider == null
                          ? const Center(child: CircularProgressIndicator())
                          : CustomElevatedButton(
                              onPressed: _isLoading ? null : _signInWithEmail,
                              text: S.loginButtonLabel,
                            ),
                      ] else ...[
                        const SizedBox(height: 24),
                        CustomElevatedButton(
                          onPressed: _isLoading ? null : _sendLoginOtp,
                          text: S.sendOtpButtonLabel,
                        )
                      ],

                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(S.dontHaveAccountPrompt, style: textTheme.bodyMedium),
                        TextButton(
                          onPressed: _isLoading ? null : () => GoRouter.of(context).pushReplacement(AppRouter.accountCreationHubPath),
                          child: Text(S.signUpLink, style: textTheme.bodyMedium?.copyWith(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold))
                        )
                      ]),
                      const SizedBox(height: 24),
                      Row(children: <Widget>[
                        const Expanded(child: Divider()),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(S.orContinueWithLabel, style: textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))),
                        const Expanded(child: Divider())]),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialLoginButton(
                            context,
                            provider: 'google',
                            iconPath: _googleIconPath,
                            onTap: () => _signInWithSocial(OAuthProvider.google),
                            tooltip: "Google"
                          ),
                        ],
                      )
                    ],
                  )
                )
              )
            )
          )
        )
      )
    );
  }

  Widget _buildSocialLoginButton(BuildContext context, {required String provider, required String iconPath, required VoidCallback onTap, String? tooltip}) {
    const double iconDisplaySize = 24.0;
    const double circleDiameter = 44.0;
    bool isThisButtonLoading = _isLoading && _loadingSocialProvider == provider;

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: circleDiameter,
          height: circleDiameter,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.dividerColor, width: 1), color: Colors.white),
          child: Center(
            child: isThisButtonLoading
                ? const SizedBox( width: iconDisplaySize -4, height: iconDisplaySize -4, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Image.asset(
                    iconPath,
                    width: iconDisplaySize,
                    height: iconDisplaySize,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}