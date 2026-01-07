// lib/features/auth/screens/otp_verification_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/l10n/app_localizations.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? fullName; // Changed to nullable
  final String? email;    // Changed to nullable
  final String? password; // Changed to nullable
  final String phoneNumber; // Full E.164 phone number
  final String countryCode; // Should be ISO 3166-1 alpha-2 code (e.g., "IN", "US")
  final String? vonageRequestId; // Changed to nullable
  final String? bhashSmsRef;     // Added new field

  const OtpVerificationScreen({
    super.key,
    this.fullName, // Made optional
    this.email,    // Made optional
    this.password, // Made optional
    required this.phoneNumber,
    required this.countryCode,
    this.vonageRequestId, // Made optional
    this.bhashSmsRef,     // Added new parameter
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  String? _currentVonageRequestId; // Changed to String?

  Timer? _timer;
  int _start = 300; // Initial timer value
  bool _canResend = false;

  // Ensure this matches your actual backend URL
  final String _yourBackendBaseUrl = 'http://192.168.29.229:3001';

  @override
  void initState() {
    super.initState();
    _currentVonageRequestId = widget.vonageRequestId; // Now assigns String? to String?
    _startTimer();
    for (int i = 0; i < _otpControllers.length - 1; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < _otpControllers.length - 1) {
          FocusScope.of(context).requestFocus(_otpFocusNodes[i + 1]);
        }
      });
    }
  }

  void _startTimer() {
    _canResend = false;
    _start = 120; // Reset timer to 2 minutes (120 seconds)
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (!mounted) { // Check if the widget is still in the tree
          timer.cancel();
          return;
        }
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _canResend = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    if (!mounted) return;

    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() { _isLoading = true; _canResend = false;});

    try {
      // Assuming resend still uses the main phone number and existing Vonage-based backend
      // If bhashSmsRef implies a different resend mechanism, this logic would need to change.
      final response = await http.post(
        Uri.parse('$_yourBackendBaseUrl/api/auth/send-otp'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{'phoneNumber': widget.phoneNumber}),
      );

      if (!mounted) return;

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == true) {
        _currentVonageRequestId = responseBody['requestId']; // Potentially updates with a new Vonage ID
        messenger.showSnackBar(SnackBar(content: Text(S.otpResentSuccessfully), backgroundColor: AppTheme.safeGreen));
        _startTimer();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(responseBody['error'] ?? S.failedToResendOtp), backgroundColor: AppTheme.avoidRed));
        setState(() { _canResend = true; });
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(S.unexpectedError(e.toString())), backgroundColor: AppTheme.avoidRed));
        setState(() { _canResend = true; });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  Future<void> _verifyOtpAndSignUp() async {
    if (!mounted) return;

    final S = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final supabase = Supabase.instance.client;

    if (_otpCode.length != _otpControllers.length) {
      messenger.showSnackBar(SnackBar(content: Text(S.enterCompleteOtpError), backgroundColor: AppTheme.warningOrange));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // Step 1: Verify OTP with your backend
      // This uses _currentVonageRequestId. If widget.vonageRequestId was null,
      // _currentVonageRequestId will be null. Your backend must handle a null requestId
      // if it's sent, or this part might need adjustment based on whether bhashSmsRef is present.
      final verifyResponse = await http.post(
        Uri.parse('$_yourBackendBaseUrl/api/auth/verify-otp'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        // Using Map<String, dynamic> to allow requestId to be null if _currentVonageRequestId is null
        body: jsonEncode(<String, dynamic>{
          'requestId': _currentVonageRequestId, // This can be null now
          'otpCode': _otpCode,
        }),
      );

      if (!mounted) return;

      final verifyResponseBody = jsonDecode(verifyResponse.body);

      if (verifyResponse.statusCode == 200 && verifyResponseBody['success'] == true) {
        messenger.showSnackBar(SnackBar(content: Text(S.otpVerifiedSuccessfully), backgroundColor: AppTheme.safeGreen));
        _timer?.cancel();

        // Step 2: Sign up user with Supabase
        // This part will fail if widget.email, widget.password, or widget.fullName are null.
        // This occurs if they are not passed to the screen (e.g., via app_router.dart as currently configured).
        if (widget.email == null || widget.password == null || widget.fullName == null) {
          // Not changing this logic flow extensively as per instructions,
          // but highlighting that without these details, signup can't proceed as written.
          // A more robust solution would handle this case, e.g. by not attempting signup,
          // or indicating that user details are missing.
          messenger.showSnackBar(SnackBar(content: Text(S.genericError("User details missing for signup.")), backgroundColor: AppTheme.avoidRed));
          setState(() { _isLoading = false; });
          return;
        }

        try {
          final authResponse = await supabase.auth.signUp(
            email: widget.email!, // Null assertion, will crash if email is null
            password: widget.password!, // Null assertion, will crash if password is null
            data: {
              'full_name': widget.fullName!, // Null assertion, will crash if fullName is null
              'mobile_number': widget.phoneNumber,
              'country_code': widget.countryCode,
            },
          );

          if (!mounted) return;

          if (authResponse.user != null) {
            print("Supabase user signed up. Profile should be auto-created by trigger.");

            if (authResponse.session == null && (authResponse.user?.emailConfirmedAt == null)) {
                messenger.showSnackBar(SnackBar(
                    content: Text(S.signupSuccessConfirmationNeeded),
                    duration: const Duration(seconds: 5),
                ));
                router.go(AppRouter.loginPath);
            } else {
                 messenger.showSnackBar(SnackBar(content: Text(S.signupSuccessLoggedIn)));
                 router.go(AppRouter.personalizePath, extra: {'initialSetup': true, 'email': widget.email});
            }

          } else {
            messenger.showSnackBar(SnackBar(content: Text(S.signupFailedNoUser), backgroundColor: AppTheme.avoidRed));
          }
        } on AuthException catch (authError) {
          if (mounted) {
            // MODIFIED LINE BELOW
            messenger.showSnackBar(SnackBar(content: Text(S.signupFailedError + ": " + authError.message), backgroundColor: AppTheme.avoidRed));
          }
        } catch (e) {
          if (mounted) {
            messenger.showSnackBar(SnackBar(content: Text(S.unexpectedError(e.toString())), backgroundColor: AppTheme.avoidRed));
          }
        }

      } else {
        messenger.showSnackBar(SnackBar(content: Text(verifyResponseBody['error'] ?? S.invalidOtpError), backgroundColor: AppTheme.avoidRed));
      }
    } catch (e) {
      if (mounted) {
        print("Error verifying OTP / signing up: $e");
        messenger.showSnackBar(SnackBar(content: Text(S.unexpectedError(e.toString())), backgroundColor: AppTheme.avoidRed));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.otpVerificationTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                      Text(S.enterOtpSentTo(widget.phoneNumber), textAlign: TextAlign.center, style: textTheme.titleMedium),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_otpControllers.length, (index) {
                          return SizedBox(
                            width: 42, // Reduced from 45 to prevent overflow
                            height: 52, // Slightly reduced for consistency
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
                                  _otpFocusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                }
                                if (_otpControllers.every((controller) => controller.text.isNotEmpty) && index == _otpControllers.length -1) {
                                    FocusScope.of(context).unfocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _verifyOtpAndSignUp,
                              style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                                backgroundColor: MaterialStateProperty.all(AppTheme.primaryPurple),
                              ),
                              child: Text(S.verifyOtpButtonLabel),
                            ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(S.didNotReceiveOtpPrompt, style: textTheme.bodyMedium),
                          TextButton(
                            onPressed: _isLoading ? null : (_canResend ? _resendOtp : null),
                            child: Text(
                              _canResend ? S.resendOtpLink : S.resendOtpTimer((_start ~/ 60).toString(), (_start % 60).toString().padLeft(2, '0')),
                              style: textTheme.bodyMedium?.copyWith(
                                color: _canResend ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                fontWeight: _canResend ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
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