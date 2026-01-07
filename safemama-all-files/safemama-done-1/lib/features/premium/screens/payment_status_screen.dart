// lib/features/premium/screens/payment_status_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/constants/app_colors.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/widgets/custom_button.dart';
// We are NOT using RichAnimatedLoadingWidget here anymore

enum PaymentProgressState { received, processing, successful, failed } // Remains the same

class PaymentStatusScreen extends ConsumerStatefulWidget {
  final String? paymentId;
  final String? status;
  final String? orderId;

  const PaymentStatusScreen({
    super.key,
    this.paymentId,
    this.status,
    this.orderId,
  });

  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen>
    with TickerProviderStateMixin {
  PaymentProgressState _currentProgress = PaymentProgressState.received;
  Timer? _uiStateTimer;
  int _redirectCountdown = 3; // As per "Processing: 3 seconds remaining"
  Timer? _redirectCountdownTimer;
  bool _premiumActivationAttempted = false;

  // ADD these properties:
  String? membershipType;
  DateTime? expiryDate;
  bool premiumUpdateSuccess = false;

  late AnimationController _progressCircleController; // For the circular progress
  late AnimationController _iconPopController; // For icon pop-in effect

  // Texts for each state
  Map<PaymentProgressState, Map<String, String>> _statusTexts = {};

  @override
  void initState() {
    super.initState();
    print(
        "[PaymentStatusScreen] Init. Payment ID: ${widget.paymentId}, Status from URL: ${widget.status}");

    // Initialize the properties:
    membershipType = 'premium_monthly'; // or get from widget/params
    expiryDate = DateTime.now().add(const Duration(days: 30));

    _progressCircleController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 2), // Duration for one full circle animation or timed progress
    )..addListener(() {
        setState(() {});
      }); // To rebuild on animation ticks

    _iconPopController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animatePaymentStates();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final S = AppLocalizations.of(context)!;
    // These keys should mostly match what you've already defined for the PaymentStatusScreen
    _statusTexts = {
      PaymentProgressState.received: {
        "logo": 'assets/logos/logo_safescan_text.png', // Path to your main logo
        "title": S.paymentStatusTitleReceived, // "Payment Received"
        "subtitle": S.paymentStatusMsg1Received_alt, // "Your payment is being processed."
        "mainMessage": S.paymentStatusMsg2Received_alt_ps, // "We're activating your plan now!"
        "countdownTextFormat": S.paymentStatusProcessingShort, // "Processing..."
      },
      PaymentProgressState.processing: {
        "logo": 'assets/logos/logo_safescan_text.png',
        "title": S.paymentStatusTitleProcessing, // "Activating Your Plan"
        "subtitle": S.paymentStatusMsg1Processing_alt, // "Your payment is being processed."
        "mainMessage": S.paymentStatusMsg2Processing_alt_ps, // "Your premium membership will be activated soon..."
        "countdownTextFormat": S.paymentStatusProcessingLong("{seconds}"), // "Processing: {seconds} seconds remaining"
      },
      PaymentProgressState.successful: {
        "logo": 'assets/logos/logo_safescan_text.png',
        "title": S.paymentStatusTitleSuccessful, // "Payment Successful"
        "subtitle": S.paymentStatusMsg1Successful_alt, // "Your payment has been processed."
        "mainMessage": S.paymentStatusMsg2Successful_alt_ps, // "Your premium membership is now active!..."
        "countdownTextFormat": S.paymentStatusProcessingComplete, // "Complete!"
      },
      PaymentProgressState.failed: {
        "logo": 'assets/logos/logo_safescan_text.png',
        "title": S.paymentStatusTitleFailed,
        "subtitle": "", // Subtitle may not be needed for failure
        "mainMessage": S.paymentStatusMsg1Failed_alt_ps, // "Unfortunately, your payment could not be processed..."
        "countdownTextFormat": S.paymentStatusProcessingFailed,
      }
    };
  }

  void _animatePaymentStates() async {
    if (!mounted) return;

    // Start with "Received"
    setState(() => _currentProgress = PaymentProgressState.received);
    _iconPopController.forward(from: 0.0);
    _progressCircleController.forward(from: 0.0); // Start progress animation

    await Future.delayed(const Duration(seconds: 1, milliseconds: 500)); // Show "Received"
    if (!mounted) return;

    if (widget.status?.toLowerCase() == 'succeeded' ||
        widget.status?.toLowerCase() == 'success') {
      setState(() => _currentProgress = PaymentProgressState.processing);
      _iconPopController.reset();
      _iconPopController.forward(); // Re-pop icon
      _progressCircleController.reset();
      _progressCircleController.forward(); // Restart/continue progress
      _startRedirectCountdown(); // Start redirect countdown during processing

      if (!_premiumActivationAttempted) {
        _premiumActivationAttempted = true;
        final userProfileNotifier =
            ref.read(userProfileNotifierProvider.notifier);
        
        // Fix the updateUserToPremium call by removing orderId parameter:
        await userProfileNotifier.updateUserToPremium(membershipType!, expiryDate!.toIso8601String());
        premiumUpdateSuccess = true; // Set this after successful update

        if (!mounted) return;

        if (premiumUpdateSuccess) {
          await userProfileNotifier.loadUserProfile();
          if (!mounted) return;
          setState(() => _currentProgress = PaymentProgressState.successful);
          _iconPopController.reset();
          _iconPopController.forward();
          _progressCircleController
              .stop(); // Stop explicit progress, show full circle or checkmark
        } else {
          _redirectCountdownTimer?.cancel();
          setState(() => _currentProgress = PaymentProgressState.failed);
          _iconPopController.reset();
          _iconPopController.forward();
          _progressCircleController.stop();
        }
      }
    } else {
      setState(() => _currentProgress = PaymentProgressState.failed);
      _iconPopController.reset();
      _iconPopController.forward();
      _progressCircleController.stop();
    }
  }

  void _startRedirectCountdown() {
    _redirectCountdownTimer?.cancel();
    _redirectCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_redirectCountdown > 0) {
        setState(() => _redirectCountdown--);
      } else {
        timer.cancel();
        _proceedToDashboard();
      }
    });
  }

  void _proceedToDashboard() {
    if (mounted) {
      _uiStateTimer?.cancel(); // Ensure consistent timer name
      _redirectCountdownTimer?.cancel();
      context.go(AppRouter.homePath);
    }
  }

  @override
  void dispose() {
    _uiStateTimer?.cancel(); // Ensure consistent timer name
    _redirectCountdownTimer?.cancel();
    _progressCircleController.dispose();
    _iconPopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final Map<String, String> texts = _statusTexts.isNotEmpty
        ? (_statusTexts[_currentProgress] ??
            _statusTexts[PaymentProgressState.failed]!)
        : {
            "logo": 'assets/logos/logo_safescan_text.png',
            "title": "Status",
            "subtitle": "Loading...",
            "mainMessage": "",
            "countdownTextFormat": "..."
          };

    IconData centerIconData;
    Color centerIconColor;
    bool showProgressCircle = false;

    switch (_currentProgress) {
      case PaymentProgressState.received:
        centerIconData = Icons.payment_outlined; // Represents a card/payment
        centerIconColor = AppColors.textMedium;
        showProgressCircle = true;
        break;
      case PaymentProgressState.processing:
        centerIconData = Icons.credit_card; // Card icon
        centerIconColor = AppColors.primary;
        showProgressCircle = true;
        break;
      case PaymentProgressState.successful:
        centerIconData = Icons.check_circle; // Checkmark
        centerIconColor = AppColors.safeGreen;
        showProgressCircle = false; // Progress complete
        break;
      case PaymentProgressState.failed:
        centerIconData = Icons.error_rounded;
        centerIconColor = AppColors.avoidRed;
        showProgressCircle = false;
        break;
    }

    String countdownText = "";
    if (_currentProgress == PaymentProgressState.processing) {
      countdownText = S.paymentStatusProcessingLong(_redirectCountdown.toString());
    } else if (_currentProgress == PaymentProgressState.successful &&
        _redirectCountdown > 0 &&
        _redirectCountdownTimer?.isActive == true) {
      countdownText =
          S.paymentStatusRedirectingIn(_redirectCountdown.toString());
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt, // Light background for the page
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Pushes button to bottom
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                // Top content
                children: [
                  Image.asset(
                    texts["logo"]!, // Use the logo path from texts map
                    height: screenHeight * 0.05, // Adjust size
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    texts["title"]!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(
                          // Larger title
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                  ),
                  if (texts["subtitle"]!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      texts["subtitle"]!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textMedium),
                    ),
                  ],
                  const SizedBox(height: 40),
                  // Animated Icon and Progress Circle
                  SizedBox(
                    width: screenWidth * 0.4,
                    height: screenWidth * 0.4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (showProgressCircle)
                          SizedBox(
                            width: screenWidth * 0.4,
                            height: screenWidth * 0.4,
                            child: TweenAnimationBuilder<double>(
                                // Animate progress
                                tween: Tween<double>(
                                    begin: 0,
                                    end: (_currentProgress ==
                                            PaymentProgressState.processing
                                        ? (_progressCircleController.value)
                                        : 1.0)),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                    value: (_currentProgress == PaymentProgressState.processing) ? null : value, // Indeterminate for processing, determinate for received
                                    strokeWidth: 8.0,
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.6)),
                                  );
                                }),
                          ),
                        ScaleTransition(
                          scale: _iconPopController.drive(
                              CurveTween(curve: Curves.elasticOut)),
                          child: Icon(centerIconData,
                              size: screenWidth * 0.2, color: centerIconColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      texts["mainMessage"]!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textDark, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (countdownText.isNotEmpty)
                    Text(
                      countdownText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textLight),
                    ),
                ],
              ),

              // Button at the bottom
              if ((_currentProgress == PaymentProgressState.successful &&
                      (_redirectCountdownTimer == null ||
                          !_redirectCountdownTimer!.isActive ||
                          _redirectCountdown == 0)) ||
                  _currentProgress == PaymentProgressState.failed)
                SizedBox(
                  width: double.infinity,
                  child: CustomElevatedButton(
                    text: _currentProgress == PaymentProgressState.successful
                        ? S.paymentStatusProceedButton
                        : S.paymentStatusTryAgainButton,
                    onPressed: () {
                      if (_currentProgress == PaymentProgressState.failed) {
                        if (context.canPop()) context.pop();
                        // Instead of pushReplacement, just push so user can go back from upgrade screen if they want
                        context.push(AppRouter.upgradePath);
                      } else {
                        _proceedToDashboard();
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
