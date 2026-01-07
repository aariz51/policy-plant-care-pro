// lib/features/auth/screens/verify_india_mobile_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart'; // No longer needed for direct navigation from here
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/theme/app_theme.dart';
// import 'package:safemama/navigation/app_router.dart'; // No longer needed for direct navigation
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/constants/app_constants.dart'; // <<< THIS IS THE FIX: Import added

class VerifyIndiaMobileScreen extends StatefulWidget {
  const VerifyIndiaMobileScreen({super.key});

  @override
  State<VerifyIndiaMobileScreen> createState() => _VerifyIndiaMobileScreenState();
}

class _VerifyIndiaMobileScreenState extends State<VerifyIndiaMobileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();

  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController()); // NOW 6-digit OTP
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode()); // NOW 6-digit OTP
  
  String _vonageRequestId = ''; // This might be specific to the previous Vonage implementation for /api/auth/send-otp
  bool _showOtpInput = false;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  Timer? _otpResendTimer;
  int _otpResendCooldown = 120;
  bool _canResendOtp = false;

  // <<< THIS IS THE FIX: The hardcoded URL variable is removed >>>
  // final String _yourBackendBaseUrl = 'http://192.168.29.229:3001'; // DELETED

  @override
  void initState() {
    super.initState();
    // The onChanged in OTP TextFormField now handles focus changes.
    // This specific listener for OTP controllers might be redundant if onChanged covers all cases.
    // However, keeping it as it was unless specifically asked to remove.
    for (int i = 0; i < _otpControllers.length - 1; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < _otpControllers.length - 1) {
          // This might conflict or be redundant with onChanged's FocusScope.of(context).requestFocus
          // Consider if this is still needed or if onChanged is sufficient.
          // For now, keeping as per original user code.
          // FocusScope.of(context).requestFocus(_otpFocusNodes[i + 1]);
        }
      });
    }
  }

  @override
  void dispose() {
    _mobileNumberController.dispose();
    for (var controller in _otpControllers) { controller.dispose(); }
    for (var focusNode in _otpFocusNodes) { focusNode.dispose(); }
    _otpResendTimer?.cancel();
    super.dispose();
  }

  String get _currentOtpCode => _otpControllers.map((c) => c.text).join();

  void _startOtpResendTimer() {
    _canResendOtp = false;
    _otpResendCooldown = 120;
    _otpResendTimer?.cancel();
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpResendCooldown == 0) {
        setState(() { timer.cancel(); _canResendOtp = true; });
      } else {
        setState(() { _otpResendCooldown--; });
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSendingOtp = true; _isLoading = true; });
    
    final String localPhoneNumber = _mobileNumberController.text.trim();
    const String countryCode = "91"; // Hardcoded for India as this screen is specific

    // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
    final String targetUrl = '${AppConstants.yourBackendBaseUrl}/api/auth/send-otp';
    final Map<String, String> requestBodyMap = {
        'phoneNumber': localPhoneNumber,
        'countryCode': countryCode,
    };

    print("FLUTTER (VerifyIndiaMobileScreen): Attempting to POST to: $targetUrl"); 
    print("FLUTTER (VerifyIndiaMobileScreen): Request body: ${jsonEncode(requestBodyMap)}");

    try {
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBodyMap),
      );

      print("FLUTTER RAW RESPONSE STATUS: ${response.statusCode}");
      print("FLUTTER RAW RESPONSE BODY: ${response.body}");

      if (!mounted) return;
      
      try {
          final responseBody = jsonDecode(response.body);
          if (response.statusCode == 200 && responseBody['success'] == true) {
            if (responseBody['requestId'] != null) {
                 _vonageRequestId = responseBody['requestId']; 
            }
            messenger.showSnackBar(SnackBar(content: Text(S.otpSentSuccessfully), backgroundColor: AppTheme.safeGreen));
            setState(() { _showOtpInput = true; });
            _startOtpResendTimer();
          } else {
            messenger.showSnackBar(SnackBar(content: Text(responseBody['error'] ?? S.failedToSendOtp), backgroundColor: AppTheme.avoidRed));
          }
      } catch (e) {
          print("FLUTTER (VerifyIndiaMobileScreen): Error decoding JSON response: $e");
          print("FLUTTER (VerifyIndiaMobileScreen): Received non-JSON response body: ${response.body}");
          messenger.showSnackBar(SnackBar(content: Text(S.unexpectedError("Server error: Invalid response format.")), backgroundColor: AppTheme.avoidRed));
      }
    } catch (e) {
      print("FLUTTER (VerifyIndiaMobileScreen): Error during HTTP POST: $e");
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(S.unexpectedError(e.toString())), backgroundColor: AppTheme.avoidRed));
    } finally {
      if (mounted) setState(() { _isSendingOtp = false; if (!_showOtpInput) _isLoading = false; });
    }
  }

  Future<void> _handleVerifyOtpAndUpdateProfile() async {
    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final profileProvider = context.read<UserProfileProvider>();

    if (_currentOtpCode.length != _otpControllers.length) {
      messenger.showSnackBar(SnackBar(content: Text(S.enterCompleteOtpError), backgroundColor: AppTheme.warningOrange));
      return;
    }
    setState(() { _isVerifyingOtp = true; _isLoading = true; });
    
    Map<String, String> verifyOtpBody;
    if (_vonageRequestId.isNotEmpty) {
        verifyOtpBody = {'requestId': _vonageRequestId, 'otpCode': _currentOtpCode};
    } else {
        verifyOtpBody = {
            'phoneNumber': "+91${_mobileNumberController.text.trim()}",
            'otpCode': _currentOtpCode
        };
    }
    print("FLUTTER (VerifyIndiaMobileScreen): verify-otp request body: ${jsonEncode(verifyOtpBody)}");

    try {
      // <<< THIS IS THE FIX: Use the constant from AppConstants >>>
      final verifyResponse = await http.post(
        Uri.parse('${AppConstants.yourBackendBaseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(verifyOtpBody), 
      );

      print("FLUTTER RAW RESPONSE STATUS (verify-otp): ${verifyResponse.statusCode}");
      print("FLUTTER RAW RESPONSE BODY (verify-otp): ${verifyResponse.body}");
      
      final verifyResponseBody = jsonDecode(verifyResponse.body);

      if (!mounted) return;

      if (verifyResponse.statusCode == 200 && verifyResponseBody['success'] == true) {
        _otpResendTimer?.cancel(); 

        final String fullMobileNumber = "+91${_mobileNumberController.text.trim()}";
        bool profileUpdated = await profileProvider.updateUserPhoneAndVerificationStatus(
            mobileNumber: fullMobileNumber,
            countryCode: 'IN',
            isPhoneVerified: true
        );

        if (!mounted) return;
        if (profileUpdated) {
          messenger.showSnackBar(SnackBar(content: Text(S.phoneNumberVerifiedSuccess), backgroundColor: AppTheme.safeGreen));
          // Potentially navigate or update UI further
        } else {
          messenger.showSnackBar(SnackBar(content: Text(S.profileUpdateFailedError), backgroundColor: AppTheme.avoidRed));
        }
      } else {
        messenger.showSnackBar(SnackBar(content: Text(verifyResponseBody['error'] ?? S.invalidOtpError), backgroundColor: AppTheme.avoidRed));
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(S.unexpectedError(e.toString())), backgroundColor: AppTheme.avoidRed));
    } finally {
      if (mounted) setState(() { _isVerifyingOtp = false; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    Widget mobileInputSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _mobileNumberController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: InputDecoration(
            labelText: S.mobileNumberLabel,
            prefixText: "+91 ",
            hintText: S.enterMobileNumberHint,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return S.enterMobileNumberError;
            if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) return S.enterValidIndianMobileError;
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSendOtp,
          style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all(AppTheme.primaryPurple),
            minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
          ),
          child: _isSendingOtp 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                : Text(S.sendOtpButtonLabelShort),
        ),
      ],
    );

    Widget otpInputSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_otpControllers.length, (index) { // Should be 6
            return SizedBox(
              width: 45,
              height: 55,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                style: textTheme.headlineSmall,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
                ),
                onChanged: (value) {
                  if (value.length == 1 && index < _otpControllers.length - 1) {
                    FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        ElevatedButton( // <<< THE SUBMIT/VERIFY OTP BUTTON
          onPressed: _isLoading ? null : _handleVerifyOtpAndUpdateProfile,
           style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.all(AppTheme.primaryPurple),
            minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
          ),
          child: _isVerifyingOtp
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(S.verifyOtpAndContinueButton), 
        ),
        const SizedBox(height: 24),
        Row( // Resend OTP link
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S.didNotReceiveOtpPrompt, style: textTheme.bodyMedium),
            TextButton(
              onPressed: _isLoading || !_canResendOtp ? null : _handleSendOtp,
              child: Text(
                _canResendOtp ? S.resendOtpLink : S.resendOtpTimer((_otpResendCooldown ~/ 60).toString(), (_otpResendCooldown % 60).toString().padLeft(2, '0')),
                style: textTheme.bodyMedium?.copyWith(color: _canResendOtp ? AppTheme.primaryBlue : AppTheme.textSecondary, fontWeight: _canResendOtp ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.verifyMobileNumberTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        _showOtpInput 
                            ? S.enterOtpSentTo("+91${_mobileNumberController.text.trim()}") 
                            : S.verifyMobileIndiaPrompt,
                        textAlign: TextAlign.center, 
                        style: textTheme.titleMedium
                      ),
                      const SizedBox(height: 24),

                      // Conditionally show mobile input or OTP input
                      _showOtpInput ? otpInputSection : mobileInputSection,
                      
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}