// lib/features/auth/screens/account_creation_hub_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'package:safemama/core/constants/app_colors.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/widgets/custom_button.dart'; // Assuming CustomElevatedButton is here
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/features/auth/providers/registration_data_provider.dart';
import 'package:safemama/core/services/supabase_service.dart'; // <<--- VERIFIED PRESENT AND CORRECT
import 'package:safemama/navigation/providers/user_profile_provider.dart'; // <<--- VERIFIED PRESENT AND CORRECT (for UserProfileProvider class type)
import 'package:safemama/core/providers/app_providers.dart'; // <<< ADDED THIS IMPORT
import 'package:safemama/core/services/device_info_service.dart';
import 'package:safemama/core/theme/app_theme.dart'; // For your AppTheme colors if needed
import 'package:url_launcher/url_launcher.dart';
// MODIFIED Supabase import as per instruction
import 'package:supabase_flutter/supabase_flutter.dart';
// Add missing imports for Enums from personalization screens for _signInWithGoogleHub logic
import 'package:safemama/features/auth/screens/personalize_trimester_screen.dart'; // For TrimesterOption
import 'package:safemama/features/auth/screens/personalize_diet_screen.dart'; // For DietaryPreferenceOption
import 'package:safemama/features/auth/screens/personalize_goal_screen.dart'; // For UserGoalOption
import 'package:pinput/pinput.dart'; // ADDED for Pinput widget
import 'package:safemama/core/models/user_profile.dart'; // <<< ADD THIS IMPORT
import 'package:safemama/core/constants/app_constants.dart'; // <<< THIS IS THE FIX: Import added
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// ===== NEW STATE PROVIDER FOR THE SIGN IN TOGGLE =====
final isLoginWithPhoneProvider = StateProvider<bool>((ref) => false);
// =======================================================

// Provider for simple loading state on this screen
final accountCreationLoadingProvider = StateProvider<bool>((ref) => false);
// Provider to toggle between Sign Up and Sign In views
enum AuthMode { signUp, signIn }

final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.signUp);
// Provider for OTP UI visibility (specific to Sign Up mode)
final showOtpFieldsProvider = StateProvider<bool>((ref) => false);
// Provider for OTP verification step loading state
final otpVerificationLoadingProvider = StateProvider<bool>((ref) => false);

// --- CHANGE: WIDGET NOW ACCEPTS A PARAMETER ---
class AccountCreationHubScreen extends ConsumerStatefulWidget {
  final bool startInSignInMode;

  const AccountCreationHubScreen({super.key, this.startInSignInMode = false});

  @override
  ConsumerState<AccountCreationHubScreen> createState() =>
      _AccountCreationHubScreenState();
}

class _AccountCreationHubScreenState
    extends ConsumerState<AccountCreationHubScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _passwordController;

  // <<< NEW: Add a variable to hold the pre-fetched device ID
  String? _prefetchedDeviceId;

  // --- MODIFICATION: Made _selectedCountry nullable to prevent default selection ---
  // It will now start as null and not show "India" by default.
  Country? _selectedCountry;

  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  Timer? _otpResendTimer;
  int _otpResendCooldown = 120;
  final StateProvider<bool> _canResendOtpProvider =
      StateProvider<bool>((ref) => false);

  bool _obscurePassword = true;

  // <<< THIS IS THE FIX: The hardcoded URL variable is removed >>>
  // final String _yourBackendBaseUrl = 'http://192.168.29.229:3001'; // DELETED

  String? _loadingSocialProvider;

  bool _isOtpInvalid = false;
  bool _isAttemptingOtp = false;

  @override
  void initState() {
    super.initState();
    // We read the provider ONCE to get the initial data for the text fields.
    final initialData = ref.read(registrationDataProvider);
    _fullNameController = TextEditingController(text: initialData.fullName);
    _emailController = TextEditingController(text: initialData.email);
    _mobileController = TextEditingController(text: initialData.mobileNumber);
    _passwordController = TextEditingController(text: initialData.password);

    // --- MODIFICATION: Initialize local country state from the provider.
    // This respects previously selected values but defaults to null on first load.
    _selectedCountry = initialData.selectedCountry;

    // <<< NEW: Call the pre-fetching method
    _prefetchData();

    // --- NEW LOGIC: Force Sign In mode if the flag is passed ---
    if (widget.startInSignInMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(authModeProvider.notifier).state = AuthMode.signIn;
        }
      });
    }
  }

  // <<< NEW: Create this method to pre-fetch the device ID
  Future<void> _prefetchData() async {
    try {
      _prefetchedDeviceId = await DeviceInfoService.getDeviceId();
      print("[AccountCreationHub] Device ID prefetched: $_prefetchedDeviceId");
    } catch (e) {
      print("[AccountCreationHub] Could not pre-fetch device ID: $e");
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    _otpResendTimer?.cancel();
    super.dispose();
  }

  void _startOtpResendTimer() {
    if (!mounted) return;
    ref.read(_canResendOtpProvider.notifier).state = false;
    _otpResendCooldown = 120;
    _otpResendTimer?.cancel();
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpResendCooldown == 0) {
        timer.cancel();
        if (mounted) ref.read(_canResendOtpProvider.notifier).state = true;
      } else {
        if (mounted) {
          setState(() {
            _otpResendCooldown--;
          });
        }
      }
    });
  }

  void _showDeviceLimitReachedDialog(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(S.deviceScanLimitTitle),
          content: Text(S.deviceScanLimitMessage),
          actions: <Widget>[
            TextButton(
              child: Text(S.loginLink),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                ref.read(authModeProvider.notifier).state = AuthMode.signIn;
              },
            ),
            ElevatedButton(
              child: Text(S.buttonUpgradeToPremium),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                GoRouter.of(this.context).push(AppRouter.upgradePath);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkAndApplyDeviceScanLimit(
      String currentUserId, String? deviceId) async {
    final S = AppLocalizations.of(context)!;
    final localScaffoldMessenger = ScaffoldMessenger.of(context);

    if (deviceId == null || deviceId.isEmpty) {
      print(
          "[AntiAbuse Flutter] No deviceId provided, skipping device limit check.");
      return false;
    }
    if (currentUserId.isEmpty) {
      print(
          "[AntiAbuse Flutter] No currentUserId provided, skipping device limit check.");
      return false;
    }

    print(
        "[AntiAbuse Flutter] Calling backend to check/apply device scan limit for User: $currentUserId, Device: $deviceId");

    try {
      // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
      final response = await http.post(
        Uri.parse(
            '${AppConstants.yourBackendBaseUrl}/api/auth/apply-device-limits'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userId': currentUserId,
          'deviceId': deviceId,
        }),
      );

      if (!mounted) return false;

      final responseBody = jsonDecode(response.body);
      print(
          "[AntiAbuse Flutter] Backend response for device limit check: $responseBody");

      if (response.statusCode == 200 && responseBody['success'] == true) {
        if (responseBody['limitApplied'] == true) {
          print(
              "[AntiAbuse Flutter] Backend confirmed device limit was applied to user $currentUserId.");
          return true;
        } else {
          print(
              "[AntiAbuse Flutter] Backend confirmed no device limit was applied to user $currentUserId.");
          return false;
        }
      } else {
        print(
            "[AntiAbuse Flutter] Error from backend during device limit check: ${responseBody['error'] ?? 'Unknown error'}");
        String errorMessage = S.unexpectedError(
            "Device limit check failed: ${responseBody['error'] ?? response.statusCode}");
        localScaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(errorMessage), backgroundColor: AppTheme.avoidRed),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      print(
          "[AntiAbuse Flutter] Exception calling backend for device limit check: $e");
      String exceptionMessage =
          S.unexpectedError("Device limit check exception: ${e.toString()}");
      localScaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text(exceptionMessage),
            backgroundColor: AppTheme.avoidRed),
      );
      return false;
    }
  }

  String? _validateFullNameLocal(String? v, AppLocalizations S) {
    return (v == null || v.isEmpty)
        ? S.enterFullNameError
        : (v.length < 3 ? S.fullNameMinLengthError : null);
  }

  String? _validateEmailLocal(String? v, AppLocalizations S) {
    return (v == null || v.isEmpty || !v.contains('@') || !v.contains('.'))
        ? S.enterValidEmailError
        : null;
  }

  String? _validateMobileLocal(
      String? value, AppLocalizations S, RegistrationData rData) {
    // The field is now optional at the form level.
    // Requirement for WhatsApp is enforced in the _handleSignUpFlow method.
    if (value != null &&
        value.isNotEmpty &&
        !RegExp(r'^[0-9]{7,15}$').hasMatch(value))
      return S.enterValidMobileNumberError;
    return null;
  }

  String? _validatePasswordLocal(String? v, AppLocalizations S) {
    if (v == null || v.isEmpty) return S.enterPasswordError;
    if (v.length < 8) return S.passwordMinLengthError(8);
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) return S.passwordUppercaseError;
    if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return S.passwordNumberError;
    return null;
  }

  Future<void> _handlePrimarySignUp() async {
    // --- THIS IS THE NEW LOGIC ---
    // Update the provider with the current text from the controllers
    // RIGHT BEFORE we perform the action. This is the correct pattern.
    final notifier = ref.read(registrationDataProvider.notifier);
    notifier.updateFormField(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      mobileNumber: _mobileController.text,
      // We don't need to update the country here as it's handled by its own onTap
    );
    // --- END OF NEW LOGIC ---

    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Now we read the provider again to get the fresh data
    final registrationData = ref.read(registrationDataProvider);

    // We get the theme data directly from the context.
    final theme = Theme.of(context);

    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (registrationData.selectedCountry == null) {
      messenger.showSnackBar(SnackBar(
          content: Text("Please select your country."),
          backgroundColor: theme.colorScheme.error));
      return;
    }
    if (!registrationData.agreedToTerms) {
      messenger.showSnackBar(SnackBar(
          content: Text(S.mustAgreeToTermsError),
          backgroundColor: theme.colorScheme.error));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text("Choose Verification Method",
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              CustomElevatedButton(
                text: "Continue with WhatsApp",
                onPressed: () {
                  Navigator.pop(context);
                  _handleSignUpFlow();
                },
              ),
              const SizedBox(height: 12),
              CustomElevatedButton(
                text: "Continue with Email",
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme
                      .colorScheme.surfaceVariant, // A standard light grey color
                  foregroundColor: theme.colorScheme
                      .onSurfaceVariant, // The correct text color for that background
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleCreateAccountWithEmailViaBackend();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // --- MODIFIED METHOD: Validation block removed as it's now handled by _handlePrimarySignUp ---
  Future<void> _handleSignUpFlow() async {
    if (!mounted) return;

    // NOTE: All validation is now performed in `_handlePrimarySignUp` before this method is called.

    final S = AppLocalizations.of(context)!;
    final registrationData = ref.read(registrationDataProvider);

    setState(() => _isAttemptingOtp = true);
    ref.read(accountCreationLoadingProvider.notifier).state = true;

    try {
      // Now we can safely use the '!' because we've already checked for null.
      final String countryCode = registrationData.selectedCountry!.phoneCode;
      final String localPhoneNumber = registrationData.mobileNumber ?? '';

      // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
      final String targetUrl =
          '${AppConstants.yourBackendBaseUrl}/api/auth/send-whatsapp-otp';

      final Map<String, String> requestBodyMap = {
        'phoneNumber': localPhoneNumber,
        'countryCode': countryCode,
        'fullName': registrationData.fullName
      };

      print("[Flutter SendOTP] Calling backend: $targetUrl");
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBodyMap),
      );

      if (!mounted) {
        print("[Flutter SendOTP] Widget unmounted after http.post. Aborting.");
        return;
      }

      print(
          "[Flutter SendOTP] Backend response status: ${response.statusCode}");
      final responseBody = jsonDecode(response.body);
      print("[Flutter SendOTP] Backend response body: $responseBody");

      if (response.statusCode == 200 && responseBody['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.otpSentSuccessfully),
            backgroundColor: AppTheme.safeGreen));
        if (mounted) {
          ref.read(showOtpFieldsProvider.notifier).state = true;
        }
        _startOtpResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseBody['error'] ?? S.failedToSendOtp),
            backgroundColor: AppTheme.avoidRed));
        if (mounted)
          ref.read(accountCreationLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      print("[Flutter SendOTP] Error in _handleSignUpFlow (OTP path): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.unexpectedError("Send OTP: ${e.toString()}")),
            backgroundColor: AppTheme.avoidRed));
        ref.read(accountCreationLoadingProvider.notifier).state = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAttemptingOtp = false;
        });
        // This logic is tricky. If we successfully showed OTP fields, the general loading should stop.
        if (ref.read(showOtpFieldsProvider) &&
            ref.read(accountCreationLoadingProvider)) {
          ref.read(accountCreationLoadingProvider.notifier).state = false;
        }
      }
    }
  }

  Future<void> _handleCreateAccountWithEmailViaBackend() async {
    // --- THIS IS THE NEW LOGIC ---
    // Update the provider with the current text from the controllers
    // RIGHT BEFORE we perform the action. This is the correct pattern.
    final notifier = ref.read(registrationDataProvider.notifier);
    notifier.updateFormField(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      mobileNumber: _mobileController.text,
      // We don't need to update the country here as it's handled by its own onTap
    );
    // --- END OF NEW LOGIC ---

    // Validate all fields as this path needs them. Mobile number is optional via its own validator.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final registrationData = ref.read(registrationDataProvider);
    final sL10n = AppLocalizations.of(context)!;
    final localScaffoldMessenger = ScaffoldMessenger.of(context);
    final localRouter = GoRouter.of(context);

    if (!registrationData.agreedToTerms) {
      localScaffoldMessenger
          .showSnackBar(SnackBar(content: Text(sL10n.mustAgreeToTermsError)));
      return;
    }

    ref.read(accountCreationLoadingProvider.notifier).state = true;

    // <<< CHANGED: Use the pre-fetched device ID instead of calling the service again
    String? initialDeviceIdForMetaData = _prefetchedDeviceId;
    Map<String, dynamic> metaDataForBackend = ref
        .read(registrationDataProvider.notifier)
        .getFullSignupMetaDataForSupabaseTrigger();
    if (initialDeviceIdForMetaData != null &&
        initialDeviceIdForMetaData.isNotEmpty) {
      metaDataForBackend['device_id'] = initialDeviceIdForMetaData;
    }
    metaDataForBackend.remove('password');

    try {
      print(
          "[DirectEmailSignup] Calling backend: ${AppConstants.yourBackendBaseUrl}/api/auth/create-account-email for email: ${registrationData.email}");
      // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
      final response = await http.post(
        Uri.parse(
            '${AppConstants.yourBackendBaseUrl}/api/auth/create-account-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': registrationData.email,
          'password': registrationData.password,
          'metaData': metaDataForBackend,
        }),
      );

      if (!mounted) return;
      print(
          "[DirectEmailSignup] Backend response status: ${response.statusCode}");
      final responseBody = jsonDecode(response.body);
      print("[DirectEmailSignup] Backend response body: $responseBody");

      if (response.statusCode == 201 && responseBody['success'] == true) {
        localScaffoldMessenger.showSnackBar(SnackBar(
            content: Text(sL10n.signupSuccessAccountCreatedSignIn),
            backgroundColor: AppTheme.safeGreen));

        print(
            "[DirectEmailSignup] Attempting to sign in user: ${registrationData.email} after backend creation.");
        final userProfileService = ref.read(userProfileNotifierProvider);
        final signInSuccess = await userProfileService.signInWithEmail(
            registrationData.email, registrationData.password);
        if (!mounted) return;

        if (signInSuccess) {
          print(
              "[DirectEmailSignup] Sign in successful for ${registrationData.email}.");
          final supabaseUser =
              SupabaseService.instance.client.auth.currentUser;
          if (supabaseUser != null) {
            String? currentDeviceId = await DeviceInfoService.getDeviceId();
            if (!mounted) return;

            if (currentDeviceId != null &&
                currentDeviceId.isNotEmpty &&
                (userProfileService.userProfile?.deviceId == null ||
                    userProfileService.userProfile!.deviceId!.isEmpty)) {
              print(
                  "[DirectEmailSignup] Device ID in current profile model is '${userProfileService.userProfile?.deviceId}'. Current actual deviceId is '$currentDeviceId'. Updating profile in Supabase.");
              await SupabaseService.instance.client
                  .from('profiles')
                  .update({'device_id': currentDeviceId}).eq(
                      'id', supabaseUser.id);
              if (!mounted) return;
              await userProfileService.loadUserProfile();
              if (!mounted) return;
              print(
                  "[DirectEmailSignup] Profile reloaded after device_id update. Device ID in provider model: ${userProfileService.userProfile?.deviceId}");
            }

            bool limitAppliedByBackend = false;
            String? deviceIdForCheck =
                currentDeviceId ?? userProfileService.userProfile?.deviceId;

            if (deviceIdForCheck != null && deviceIdForCheck.isNotEmpty) {
              print(
                  "[DirectEmailSignup] Calling _checkAndApplyDeviceScanLimit with deviceId: $deviceIdForCheck");
              limitAppliedByBackend = await _checkAndApplyDeviceScanLimit(
                  supabaseUser.id, deviceIdForCheck);
              if (!mounted) return;

              if (limitAppliedByBackend) {
                print(
                    "[DirectEmailSignup] Backend applied device scan limit. Reloading profile.");
                await userProfileService.loadUserProfile();
                if (!mounted) return;
                print(
                    "[DirectEmailSignup] Profile reloaded. Scan count: ${userProfileService.userProfile?.scanCount}");
                _showDeviceLimitReachedDialog(context);
              }
            } else {
              print(
                  "[DirectEmailSignup] No valid deviceId found for scan limit check. Fetched: '$currentDeviceId', From profile: '${userProfileService.userProfile?.deviceId}'");
            }
          }
          if (mounted) localRouter.go(AppRouter.homePath);
        } else {
          localScaffoldMessenger.showSnackBar(SnackBar(
              content: Text(sL10n.loginFailedAfterSignupError),
              backgroundColor: AppTheme.avoidRed));
        }
      } else {
        localScaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                responseBody['error'] ?? sL10n.signupFailedErrorGeneral),
            backgroundColor: AppTheme.avoidRed));
      }
    } catch (e) {
      if (!mounted) return;
      print("[DirectEmailSignup] Exception: $e");
      localScaffoldMessenger.showSnackBar(SnackBar(
          content: Text(sL10n.unexpectedError(e.toString())),
          backgroundColor: AppTheme.avoidRed));
    } finally {
      if (mounted) {
        ref.read(accountCreationLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleVerifyOtpAndCreateAccountWithPersonalization(
      String otpCodeFromPinput) async {
    if (!mounted) return;
    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final registrationData = ref.read(registrationDataProvider);

    if (otpCodeFromPinput.length != 6) {
      messenger.showSnackBar(SnackBar(
          content: Text(S.enterCompleteOtpError),
          backgroundColor: AppTheme.warningOrange));
      return;
    }

    ref.read(otpVerificationLoadingProvider.notifier).state = true;

    final String mobileNumberForApi =
        registrationData.mobileNumber?.trim() ?? '';

    try {
      // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
      final verifyResponse = await http.post(
        Uri.parse(
            '${AppConstants.yourBackendBaseUrl}/api/auth/verify-whatsapp-otp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'phoneNumber': mobileNumberForApi,
          'countryCode': registrationData.selectedCountry!.phoneCode,
          'otpCode': otpCodeFromPinput.trim()
        }),
      );

      if (!mounted) {
        if (ref.read(otpVerificationLoadingProvider))
          ref.read(otpVerificationLoadingProvider.notifier).state = false;
        return;
      }

      final verifyResponseBody = jsonDecode(verifyResponse.body);

      if (verifyResponse.statusCode == 200 &&
          verifyResponseBody['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.otpVerifiedSuccessfully),
            backgroundColor: AppTheme.safeGreen));
        _otpResendTimer?.cancel();
        if (mounted) {
          setState(() {
            _isOtpInvalid = false;
          });
        }
        await _performSupabaseSignupWithPersonalization(isPhoneVerified: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(verifyResponseBody['error'] ?? S.invalidOtpError),
            backgroundColor: AppTheme.avoidRed));
        if (mounted) {
          setState(() {
            _isOtpInvalid = true;
          });
          ref.read(otpVerificationLoadingProvider.notifier).state = false;
        }
      }
    } catch (e) {
      if (mounted) {
        final s_err_context = AppLocalizations.of(this.context)!;
        final messenger_err_context = ScaffoldMessenger.of(this.context);
        if (e is FormatException &&
            e.message.toLowerCase().contains('<!doctype html>')) {
          messenger_err_context.showSnackBar(SnackBar(
              content: Text(s_err_context.unexpectedError(
                  "Received HTML instead of JSON. Check server endpoint.")),
              backgroundColor: AppTheme.avoidRed));
        } else {
          messenger_err_context.showSnackBar(SnackBar(
              content: Text(s_err_context.unexpectedError(e.toString())),
              backgroundColor: AppTheme.avoidRed));
        }
        setState(() {
          _isOtpInvalid = true;
        });
        ref.read(otpVerificationLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!ref.read(_canResendOtpProvider)) return;
    if (!mounted) return;
    final S = AppLocalizations.of(context)!;
    final registrationData = ref.read(registrationDataProvider);

    ref.read(_canResendOtpProvider.notifier).state = false;

    final String localPhoneNumber = registrationData.mobileNumber ?? '';
    // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
    final String targetUrl =
        '${AppConstants.yourBackendBaseUrl}/api/auth/send-whatsapp-otp';
    final Map<String, String> requestBodyMap = {
      'phoneNumber': localPhoneNumber,
      'countryCode': registrationData.selectedCountry!.phoneCode,
      'fullName': registrationData.fullName
    };
    try {
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBodyMap),
      );
      if (!mounted) return;
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.otpResentSuccessfully),
            backgroundColor: AppTheme.safeGreen));
        _startOtpResendTimer();
        _pinController.clear();
        if (mounted) {
          _pinFocusNode.requestFocus();
          setState(() => _isOtpInvalid = false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseBody['error'] ?? S.failedToResendOtp),
            backgroundColor: AppTheme.avoidRed));
        if (mounted) {
          ref.read(_canResendOtpProvider.notifier).state = true;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.unexpectedError(e.toString())),
            backgroundColor: AppTheme.avoidRed));
        ref.read(_canResendOtpProvider.notifier).state = true;
      }
    }
  }

  Future<void> _performSupabaseSignupWithPersonalization({
    required bool isPhoneVerified,
  }) async {
    final sL10n = AppLocalizations.of(context)!;
    final localScaffoldMessenger = ScaffoldMessenger.of(context);
    final supabase = SupabaseService.instance.client;
    final UserProfileProvider userProfileService =
        ref.read(userProfileNotifierProvider);
    final registrationData = ref.read(registrationDataProvider);

    if (mounted) {
      ref.read(accountCreationLoadingProvider.notifier).state = true;
      if (ref.read(otpVerificationLoadingProvider)) {
        ref.read(otpVerificationLoadingProvider.notifier).state = false;
      }
    } else {
      print(
          "[SignupOTP] Not mounted at start of _performSupabaseSignupWithPersonalization");
      return;
    }

    // <<< CHANGED: Use the pre-fetched device ID here as well
    String? deviceId = _prefetchedDeviceId;

    if (!mounted) {
      print("[SignupOTP] Unmounted after getting device ID.");
      if (ref.read(accountCreationLoadingProvider))
        ref.read(accountCreationLoadingProvider.notifier).state = false;
      return;
    }

    Map<String, dynamic> fullMetaData = ref
        .read(registrationDataProvider.notifier)
        .getFullSignupMetaDataForSupabaseTrigger();
    if (deviceId != null && deviceId.isNotEmpty)
      fullMetaData['device_id'] = deviceId;

    if (isPhoneVerified &&
        registrationData.selectedCountry != null &&
        registrationData.mobileNumber != null &&
        registrationData.mobileNumber!.isNotEmpty) {
      fullMetaData['is_phone_verified'] = true;
      fullMetaData['mobile_number'] = registrationData.mobileNumber;
      fullMetaData['country_code'] =
          registrationData.selectedCountry!.phoneCode;
    }

    try {
      print(
          "[SignupOTP] Attempting Supabase Auth SignUp. Email: ${registrationData.email}, Phone Verified Path: $isPhoneVerified, Metadata: $fullMetaData");
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: registrationData.email,
        password: registrationData.password,
        data: fullMetaData,
      );

      if (!mounted) {
        print("[SignupOTP] Unmounted after Supabase Auth SignUp call.");
        return;
      }
      print(
          "[SignupOTP] Supabase Auth SignUp completed. User ID: ${authResponse.user?.id}, Session: ${authResponse.session != null}");

      final User? supabaseUser = authResponse.user;
      if (supabaseUser != null) {
        print(
            "[SignupOTP] Device ID '$deviceId' was in metadata for signUp. Backend trigger should handle initial persistence.");
        if (!mounted) {
          print("[SignupOTP] Unmounted before email confirmation logic.");
          return;
        }

        if (isPhoneVerified) {
          print(
              "[SignupOTP] Attempting programmatic email confirmation for ${supabaseUser.id} (OTP Path)");

          // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
          http.post(
            Uri.parse(
                '${AppConstants.yourBackendBaseUrl}/api/auth/admin-confirm-email-after-otp'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'userId': supabaseUser.id}),
          ).then((confirmEmailResponse) {
            // This .then() block runs in the background when the response comes back.
            // It's good for logging but doesn't block the user.
            if (confirmEmailResponse.statusCode == 200) {
              print(
                  "[SignupOTP Background] Programmatic email confirmation successful.");
            } else {
              print(
                  "[SignupOTP Background] WARNING: Programmatic email confirmation FAILED. Status: ${confirmEmailResponse.statusCode}, Body: ${confirmEmailResponse.body}.");
            }
          }).catchError((e) {
            print(
                "[SignupOTP Background] Exception during programmatic email confirmation: $e");
          });
        }

        if (!mounted) {
          print(
              "[SignupOTP] Unmounted after programmatic email confirmation logic, before setUserIdAndLoadProfile.");
          return;
        }

        // Because we didn't wait, the app proceeds to this step immediately.
        await userProfileService.setUserIdAndLoadProfile(supabaseUser);
        localScaffoldMessenger.showSnackBar(
            SnackBar(content: Text(sL10n.signupSuccessLoggedIn)));
      } else {
        if (mounted) {
          localScaffoldMessenger.showSnackBar(SnackBar(
              content: Text(sL10n.signupFailedNoUser),
              backgroundColor: AppTheme.avoidRed));
        }
      }
    } on AuthException catch (authError) {
      if (mounted) {
        print("[SignupOTP] AuthException: ${authError.message}");
        String errorMessageToShow =
            sL10n.signupFailedError + ": " + authError.message;
        if (authError.message
            .toLowerCase()
            .contains('user already registered')) {
          errorMessageToShow = sL10n.emailAlreadyRegisteredError;
        } else if (authError.message
            .toLowerCase()
            .contains('rate limit exceeded')) {
          errorMessageToShow = sL10n.tooManyRequestsError;
        }
        localScaffoldMessenger.showSnackBar(SnackBar(
            content: Text(errorMessageToShow),
            backgroundColor: AppTheme.avoidRed));
      }
    } catch (e, s) {
      if (mounted) {
        print(
            "[SignupOTP] Unexpected error in _performSupabaseSignup: $e\n$s");
        localScaffoldMessenger.showSnackBar(SnackBar(
            content: Text(sL10n.unexpectedError(e.toString())),
            backgroundColor: AppTheme.avoidRed));
      }
    } finally {
      if (mounted) {
        if (ref.read(accountCreationLoadingProvider))
          ref.read(accountCreationLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final S = AppLocalizations.of(context)!;
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    final isPhoneLogin = ref.read(isLoginWithPhoneProvider);
    bool success;

    if (isPhoneLogin) {
      // --- MODIFICATION: Add check to ensure a country is selected for phone login ---
      if (_selectedCountry == null) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text("Please select your country."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      final fullPhoneNumber =
          '+${_selectedCountry!.phoneCode}${_mobileController.text.trim()}'; // Note the '!' is now safe
      success = await userProfileNotifier.signInWithPhoneAndPassword(
        fullPhoneNumber,
        _passwordController.text,
      );
    } else {
      success = await userProfileNotifier.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
    if (mounted && !success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(S.loginFailedInvalidCredentials),
          backgroundColor: AppTheme.avoidRed,
        ),
      );
    }
  }

  Future<void> _signInWithGoogleHub() async {
    if (!mounted) {
      print("[GoogleSignInHub] START: Not mounted. Aborting.");
      return;
    }
    setState(() => _loadingSocialProvider = 'google');
    print(
        "[GoogleSignInHub] START: State set to loadingSocialProvider = google.");

    final S = AppLocalizations.of(context)!;
    final userProfileService = ref.read(userProfileNotifierProvider);
    bool oAuthInitiated = false;

    UserProfileProvider.startGoogleOAuthProcess();
    print(
        "[GoogleSignInHub] Called UserProfileProvider.startGoogleOAuthProcess().");

    try {
      print(
          "[GoogleSignInHub] Calling userProfileService.signInWithGoogle() to initiate OAuth.");
      oAuthInitiated = await userProfileService.signInWithGoogle();
      print(
          "[GoogleSignInHub] userProfileService.signInWithGoogle() result: $oAuthInitiated");

      if (!mounted) {
        print(
            "[GoogleSignInHub] Widget unmounted after OAuth attempt. NO LONGER CALLING endGoogleOAuthProcess.");
        return;
      }

      if (!oAuthInitiated) {
        print(
            "[GoogleSignInHub] OAuth initiation FAILED (returned false from service). NO LONGER CALLING endGoogleOAuthProcess. UserProfileProvider should handle flag reset if necessary.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  S.googleSignInFailed + " (Could not initiate OAuth)"),
              backgroundColor: AppTheme.avoidRed));
        }
      } else {
        print(
            "[GoogleSignInHub] OAuth initiated successfully via userProfileService. UserProfileProvider's auth listener will now handle the rest (profile loading, personalization, device ID, navigation etc.). AppRouter will react to UserProfileProvider state changes for navigation.");
      }
    } catch (e, s) {
      print(
          "[GoogleSignInHub] Exception during Google Sign-In Hub logic: $e\n$s. NO LONGER CALLING endGoogleOAuthProcess. UserProfileProvider should handle flag reset if necessary.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "${S.googleSignInFailed} (Launch Error: ${e.toString()})"),
            backgroundColor: AppTheme.avoidRed));
      }
    } finally {
      if (mounted) {
        if (!oAuthInitiated) {
          setState(() => _loadingSocialProvider = null);
          print(
              "[GoogleSignInHub] FINALLY: _loadingSocialProvider set to null because oAuthInitiated=$oAuthInitiated (or exception occurred).");
        } else {
          print(
              "[GoogleSignInHub] FINALLY: oAuthInitiated=$oAuthInitiated. UserProfileProvider is handling. _loadingSocialProvider remains '$_loadingSocialProvider'.");
        }
      }
    }
  }

// In _AccountCreationHubScreenState
  Future<void> _signInWithAppleHub() async {
    // If a login process is already running, do nothing.
    if (_loadingSocialProvider != null) return;

    if (!mounted) return;
    setState(() => _loadingSocialProvider = 'apple');

    final S = AppLocalizations.of(context)!;
    final userProfileService = ref.read(userProfileNotifierProvider.notifier);

    try {
      // We call the signInWithApple method from the provider
      final bool success = await userProfileService.signInWithApple();

      if (!mounted) return;

      // If it fails to even start, show an error.
      // On success, the auth listener will handle navigation.
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(S.signInFailedError("Apple Sign-In was cancelled or failed.")),
          backgroundColor: AppTheme.avoidRed,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("${S.signInFailedError("Apple Sign-In Error")} ${e.toString()}"),
          backgroundColor: AppTheme.avoidRed,
        ));
      }
    } finally {
      // IMPORTANT: Reset the loading state regardless of success or failure.
      if (mounted) {
        setState(() => _loadingSocialProvider = null);
      }
    }
  }

  // Add this method anywhere inside the _AccountCreationHubScreenState class
  static void _dummyOnPressed() {
    // This function does nothing. It's only here to satisfy the
    // SignInWithAppleButton's required onPressed parameter.
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        final messenger_err = ScaffoldMessenger.of(context);
        messenger_err.showSnackBar(
            SnackBar(content: Text("Could not launch $urlString")));
      }
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
        context: context,
        onSelect: (c) {
          setState(() => _selectedCountry = c);
          // Update the central state provider so validation and other logic works.
          ref
              .read(registrationDataProvider.notifier)
              .updateFormField(selectedCountry: c);
        });
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final mode = ref.watch(authModeProvider);
    final generalIsLoading = ref.watch(accountCreationLoadingProvider);
    final otpVerifyIsLoading = ref.watch(otpVerificationLoadingProvider);
    final showOtp = ref.watch(showOtpFieldsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
            mode == AuthMode.signUp ? S.createAccountTitle : S.signInTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        // --- THIS IS THE FIX FOR THE BACK BUTTON ---
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: generalIsLoading ||
                    otpVerifyIsLoading ||
                    (_loadingSocialProvider != null)
                ? null
                : () {
                    if (showOtp) {
                      ref.read(showOtpFieldsProvider.notifier).state = false;
                      _otpResendTimer?.cancel();
                      ref.read(_canResendOtpProvider.notifier).state = false;
                      _pinController.clear();
                      if (mounted) setState(() => _isOtpInvalid = false);
                      if (_pinFocusNode.hasFocus) {
                        FocusScope.of(context).unfocus();
                      }
                    } else {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRouter.newWelcomePath);
                      }
                    }
                  }),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!widget.startInSignInMode)
                Row(
                  children: [
                    Expanded(
                      child: CustomElevatedButton(
                        text: S.signUpButton,
                        onPressed: generalIsLoading ||
                                otpVerifyIsLoading ||
                                (_loadingSocialProvider != null)
                            ? null
                            : () => ref.read(authModeProvider.notifier).state =
                                AuthMode.signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mode == AuthMode.signUp
                              ? AppColors.primary
                              : AppColors.greyLight,
                          foregroundColor: mode == AuthMode.signUp
                              ? AppColors.textOnPrimary
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomElevatedButton(
                        text: S.signInButton,
                        onPressed: generalIsLoading ||
                                otpVerifyIsLoading ||
                                (_loadingSocialProvider != null)
                            ? null
                            : () => ref.read(authModeProvider.notifier).state =
                                AuthMode.signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mode == AuthMode.signIn
                              ? AppColors.primary
                              : AppColors.greyLight,
                          foregroundColor: mode == AuthMode.signIn
                              ? AppColors.textOnPrimary
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              if (mode == AuthMode.signUp)
                showOtp
                    ? _buildOtpVerificationForm(context)
                    : _buildSignUpForm(context)
              else
                _buildSignInForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final registrationData = ref.watch(registrationDataProvider);
    final generalIsLoading = ref.watch(accountCreationLoadingProvider);
    final showOtp = ref.watch(showOtpFieldsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: S.fullNameLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => _validateFullNameLocal(v, S),
          enabled: !generalIsLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: S.emailLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) => _validateEmailLocal(v, S),
          enabled: !generalIsLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mobileController,
          decoration: InputDecoration(
            labelText: S.mobileNumberLabel, // Use the normal label
            prefixIcon: InkWell(
              onTap: !generalIsLoading ? _showCountryPicker : null,
              // --- MODIFICATION: Conditionally render the prefix icon content ---
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedCountry != null) ...[
                      Text(_selectedCountry!.flagEmoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text("+${_selectedCountry!.phoneCode}",
                          style: textTheme.bodyLarge),
                    ] else ...[
                      // Placeholder when no country is selected
                      Text("Select Country",
                          style: textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textMedium)),
                      const SizedBox(width: 4),
                    ],
                    Icon(Icons.arrow_drop_down, color: AppColors.textMedium),
                  ],
                ),
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => _validateMobileLocal(v, S, registrationData),
          enabled: !generalIsLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('passwordFieldSignUp'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: S.createPasswordLabel,
            helperText: S.passwordMinStrengthHint,
            helperMaxLines: 2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => _validatePasswordLocal(v, S),
          enabled: !generalIsLoading,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: registrationData.agreedToTerms,
              onChanged: generalIsLoading
                  ? null
                  : (val) {
                      if (val != null) {
                        ref
                            .read(registrationDataProvider.notifier)
                            .updateFormField(agreedToTerms: val);
                      }
                    },
              activeColor: AppColors.primary,
              checkColor: AppColors.textOnPrimary,
            ),
            Expanded(
              child: RichText(
                  text: TextSpan(
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMedium),
                      children: [
                    TextSpan(text: "${S.agreeToTermsCheckbox} "),
                    WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: InkWell(
                            onTap: generalIsLoading
                                ? null
                                : () =>
                                    _launchURL('https://safemama.co/terms'),
                            child: Text(S.termsAndConditionsLink,
                                style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline)))),
                    const TextSpan(text: " & "),
                    WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: InkWell(
                            onTap: generalIsLoading
                                ? null
                                : () =>
                                    _launchURL('https://safemama.co/privacy'),
                            child: Text(S.privacyPolicyLink,
                                style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline)))),
                    const TextSpan(text: "."),
                  ])),
            ),
          ],
        ),
        const SizedBox(height: 24),
        CustomElevatedButton(
          text: "Create Account",
          isLoading: generalIsLoading &&
              !showOtp, // Show loading only when this button is active
          onPressed: (generalIsLoading || _loadingSocialProvider != null)
              ? null
              : _handlePrimarySignUp,
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(S.orDividerText)),
          const Expanded(child: Divider())
        ]),
        const SizedBox(height: 12),
        CustomElevatedButton(
          text: S.signInWithGoogle,
          isLoading: _loadingSocialProvider == 'google',
          icon: Image.asset('assets/icons/icon_google.png',
              width: 24, height: 24),
          onPressed:
              (_loadingSocialProvider != null) ? null : () => _signInWithGoogleHub(),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.grey)),
        ),
        const SizedBox(height: 12),
        // --- THIS IS THE CORRECTED CODE FOR THE APPLE BUTTON ---
        SignInWithAppleButton(
          // The onPressed requires an anonymous function to handle the async call.
          // We also check the loading provider to disable it.
          onPressed: (_loadingSocialProvider != null)
              ? () {} // Do nothing if disabled
              : () => _signInWithAppleHub(),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationForm(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final generalIsLoading = ref.watch(accountCreationLoadingProvider);
    final otpVerifyIsLoading = ref.watch(otpVerificationLoadingProvider);
    final registrationData = ref.watch(registrationDataProvider);
    final canResend = ref.watch(_canResendOtpProvider);

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 55,
      textStyle: textTheme.headlineSmall?.copyWith(color: AppColors.textDark),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final focusedPinTheme = PinTheme(
      width: 48,
      height: 58,
      textStyle: textTheme.headlineSmall?.copyWith(color: AppColors.primary),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final submittedPinTheme = PinTheme(
      width: 45,
      height: 55,
      textStyle: textTheme.headlineSmall?.copyWith(color: AppColors.success),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        border: Border.all(color: AppColors.success, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final errorPinTheme = PinTheme(
      width: 45,
      height: 55,
      textStyle: textTheme.headlineSmall?.copyWith(color: AppTheme.avoidRed),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.5),
        border: Border.all(color: AppTheme.avoidRed, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            S.enterOtpSentTo(registrationData.selectedCountry != null &&
                    registrationData.mobileNumber != null
                ? "+${registrationData.selectedCountry!.phoneCode}${registrationData.mobileNumber}"
                : S.yourMobileNumberDefaultText),
            textAlign: TextAlign.center,
            style: textTheme.titleMedium),
        const SizedBox(height: 24),
        Pinput(
          controller: _pinController,
          focusNode: _pinFocusNode,
          length: 6,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(signed: false, decimal: false),
          forceErrorState: _isOtpInvalid,
          errorPinTheme: errorPinTheme,
          onChanged: (pin) {
            if (_isOtpInvalid && pin.isNotEmpty) {
              if (mounted) setState(() => _isOtpInvalid = false);
            }
          },
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
          onCompleted: (pin) {
            _handleVerifyOtpAndCreateAccountWithPersonalization(pin);
          },
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          submittedPinTheme: submittedPinTheme,
        ),
        const SizedBox(height: 24),
        CustomElevatedButton(
          key: const ValueKey('verifyOtpButton'),
          text: S.verifyAndCreateAccountButton,
          onPressed: (otpVerifyIsLoading ||
                  generalIsLoading ||
                  _pinController.text.length != 6 ||
                  (_loadingSocialProvider != null))
              ? null
              : () => _handleVerifyOtpAndCreateAccountWithPersonalization(
                  _pinController.text),
          isLoading: otpVerifyIsLoading,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S.didNotReceiveOtpPrompt,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMedium)),
            TextButton(
              onPressed: otpVerifyIsLoading ||
                      generalIsLoading ||
                      !canResend ||
                      (_loadingSocialProvider != null)
                  ? null
                  : _resendOtp,
              child: Text(
                canResend
                    ? S.resendOtpLink
                    : S.resendOtpTimer(
                        (_otpResendCooldown ~/ 60).toString().padLeft(1, '0'),
                        (_otpResendCooldown % 60).toString().padLeft(2, '0')),
                style: textTheme.bodyMedium?.copyWith(
                    color: canResend ? AppColors.primary : AppColors.textLight,
                    fontWeight:
                        canResend ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: otpVerifyIsLoading ||
                    generalIsLoading ||
                    (_loadingSocialProvider != null)
                ? null
                : () {
                    ref.read(showOtpFieldsProvider.notifier).state = false;
                    _otpResendTimer?.cancel();
                    ref.read(_canResendOtpProvider.notifier).state = false;
                    _pinController.clear();
                    if (mounted) setState(() => _isOtpInvalid = false);
                    if (_pinFocusNode.hasFocus)
                      FocusScope.of(context).unfocus();
                  },
            child: Text(S.backToEditDetailsLink),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isSignInLoading =
        ref.watch(userProfileNotifierProvider.select((p) => p.isLoading));
    final isLoginWithPhone = ref.watch(isLoginWithPhoneProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(
                value: false,
                label: Text(S.emailLabel),
                icon: const Icon(Icons.email_outlined)),
            ButtonSegment<bool>(
                value: true,
                label: Text(S.mobileNumberLabel),
                icon: const Icon(Icons.phone_android_outlined)),
          ],
          selected: {isLoginWithPhone},
          onSelectionChanged: (newSelection) {
            if (!isSignInLoading) {
              ref.read(isLoginWithPhoneProvider.notifier).state =
                  newSelection.first;
            }
          },
        ),
        const SizedBox(height: 24),
        if (isLoginWithPhone)
          TextFormField(
            controller: _mobileController,
            enabled: !isSignInLoading,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: S.mobileNumberLabel,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: InkWell(
                onTap: !isSignInLoading ? _showCountryPicker : null,
                // --- MODIFICATION: Conditionally render the prefix icon content ---
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 12),
                  if (_selectedCountry != null) ...[
                    Text(_selectedCountry!.flagEmoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text("+${_selectedCountry!.phoneCode}"),
                  ] else ...[
                    // Placeholder when no country is selected
                    Text("Select Country",
                        style: textTheme.bodyLarge
                            ?.copyWith(color: AppColors.textMedium)),
                    const SizedBox(width: 4),
                  ],
                  const Icon(Icons.arrow_drop_down),
                  const SizedBox(width: 4),
                ]),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? S.enterMobileNumberError
                : null,
          )
        else
          TextFormField(
            controller: _emailController,
            enabled: !isSignInLoading,
            decoration: InputDecoration(
                labelText: S.emailLabel,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty || !v.contains('@'))
                ? S.enterValidEmailError
                : null,
          ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('passwordFieldSignIn'),
          controller: _passwordController,
          enabled: !isSignInLoading,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: S.passwordLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? S.enterPasswordError : null,
          onFieldSubmitted: (_) {
            if (!isSignInLoading) _handleSignIn();
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isSignInLoading
                ? null
                : () => context.push(AppRouter.forgotPasswordPath),
            child: Text(S.forgotPasswordLink,
                style: TextStyle(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 24),
        CustomElevatedButton(
          key: const ValueKey('signInButton'),
          text: S.signInButton,
          onPressed: isSignInLoading ? null : _handleSignIn,
          isLoading: isSignInLoading,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}