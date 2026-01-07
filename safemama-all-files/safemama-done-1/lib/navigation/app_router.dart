// lib/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/models/guide_model.dart';
import 'package:safemama/core/models/scan_data.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/providers/locale_provider.dart';
import 'package:safemama/features/auth/screens/login_screen.dart';
import 'package:safemama/features/auth/screens/login_otp_screen.dart';
import 'package:safemama/features/auth/screens/otp_verification_screen.dart';
// import 'package:safemama/features/auth/screens/signup_screen.dart';
import 'package:safemama/features/auth/screens/verify_india_mobile_screen.dart';
import 'package:safemama/features/guide/screens/guide_detail_screen.dart';
import 'package:safemama/features/guide/screens/guide_screen.dart';
import 'package:safemama/features/history/screens/scan_history_screen.dart';
import 'package:safemama/features/home/screens/home_screen.dart';
import 'package:safemama/features/home/screens/home_screen_shell.dart';
// import 'package:safemama/features/auth/screens/personalize_screen.dart';
import 'package:safemama/features/auth/screens/splash_loading_screen.dart';
import 'package:safemama/features/auth/screens/professional_loading_screen.dart';
import 'package:safemama/features/premium/screens/upgrade_screen.dart';
import 'package:safemama/features/profile/screens/profile_settings_screen.dart';
import 'package:safemama/features/qna/screens/ask_expert_screen.dart';
import 'package:safemama/features/qna/scan/screens/scan_product_screen.dart';
import 'package:safemama/features/qna/scan/screens/scan_results_screen.dart';
import 'package:safemama/features/search/screens/manual_search_screen.dart';
import 'dart:async';



import 'package:safemama/features/auth/screens/interactive_welcome_screen.dart';
import 'package:safemama/features/auth/screens/personalize_trimester_screen.dart';
import 'package:safemama/features/auth/screens/personalize_diet_screen.dart';
import 'package:safemama/features/auth/screens/personalize_allergies_screen.dart';
import 'package:safemama/features/auth/screens/personalize_goal_screen.dart';
import 'package:safemama/features/auth/screens/account_creation_hub_screen.dart';
import 'package:safemama/features/auth/screens/forgot_password_screen.dart';
import 'package:safemama/features/guide/screens/ai_personalized_guide_screen.dart';
import 'package:safemama/features/qna/scan/screens/pre_scan_guide_screen.dart';
import 'package:safemama/features/qna/scan/screens/multi_mode_camera_screen.dart';
import 'package:safemama/features/qna/scan/screens/detailed_analysis_screen.dart';


// Import for the new FullScreenLoadingRouteWidget
import 'package:safemama/core/widgets/full_screen_loading_route_widget.dart';


// Import for PaymentStatusScreen (NEW)
import 'package:safemama/features/premium/screens/payment_status_screen.dart';


// Import for PaymentWebViewScreen (NEW for Bundle 8)
import 'package:safemama/features/premium/screens/PaymentWebViewScreen.dart';


// IMPORT ADDED
import 'package:safemama/features/auth/screens/create_new_password_screen.dart';


import 'package:safemama/screens/task_in_progress_loading_screen.dart';


// ==========================================
// NEW IMPORTS FOR ALL PREGNANCY TOOLS
// ==========================================


// Pregnancy Tools Hub
import 'package:safemama/features/pregnancy_tools/screens/pregnancy_tools_hub_screen.dart';


// Pregnancy Tools - Calculators
import 'package:safemama/features/pregnancy_tools/screens/lmp_calculator_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/due_date_calculator_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/baby_name_generator_screen.dart';


// Pregnancy Tools - Trackers
import 'package:safemama/features/pregnancy_tools/screens/kick_counter_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/contraction_timer_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/weight_gain_tracker_screen.dart';

// --- NEW IMPORT for WeightGainAIInfoScreen ---
import 'package:safemama/features/pregnancy_tools/screens/weight_gain_ai_info_screen.dart';


// Pregnancy Tools - Lists & Planning
import 'package:safemama/features/pregnancy_tools/screens/hospital_bag_checklist_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/baby_shopping_list_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/birth_plan_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/postpartum_tracker_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/vaccine_tracker_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/pregnancy_test_checker_screen.dart'; // NEW: Pregnancy Test Checker


// Fertility & TTC
import 'package:safemama/features/fertility/screens/ttc_tracker_screen.dart';


// Document Analysis (Standalone Feature)
import 'package:safemama/features/qna/screens/document_analysis_screen.dart';


// ==========================================
// END NEW IMPORTS
// ==========================================


// --- THIS IS THE NEW, ISOLATED LISTENER ---
// It's a simple notifier that only changes when the auth state truly changes.
final authRedirectNotifier = ChangeNotifier();


class AppRouter {
  final Ref ref;


  AppRouter(this.ref) {
    // Listen to the UserProfileProvider, but ONLY to trigger our dedicated notifier.
    // This prevents the router itself from rebuilding.
    ref.listen<UserProfileProvider>(userProfileNotifierProvider, (_, __) {
      print("[AppRouter Listener] UserProfileProvider changed. Notifying authRedirectNotifier.");
      authRedirectNotifier.notifyListeners();
    });
  }


  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
  static final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');


  static const String splashLoadingPath = '/loading';
  static const String professionalLoadingPath = '/loading'; // THIS LINE IS NEW
  static const String welcomePath = '/welcome';
  static const String newWelcomePath = '/new-welcome';
  static const String personalizePath = '/personalize';
  static const String onboardingBasePath = '/new-onboarding';
  static const String personalizeTrimesterPath = '/new-onboarding/trimester';
  static const String personalizeDietPath = '/new-onboarding/diet';
  static const String personalizeAllergiesPath = '/new-onboarding/allergies';
  static const String personalizeGoalPath = '/new-onboarding/goal';
  static const String accountCreationHubPath = '/account-creation-hub';
  static const String forgotPasswordPath = '/forgot-password';
  static const String createNewPasswordPath = '/create-new-password';
  static const String loginPath = '/login';
  static const String signupPath = '/signup';
  static const String otpVerificationPath = '/otp-verify';
  static const String verifyIndiaMobilePath = '/verify-india-mobile';
  static const String homePath = '/home';
  static const String scanProductPath = '/scan';
  static const String scanResultsPath = '/scan-results';
  static const String scanResultsRouteName = 'scanResults';
  static const String detailedAnalysisPath = '/detailed-analysis';
  static const String settingsPath = '/settings';
  static const String historyPath = '/history';
  static const String askExpertPath = '/ask-expert';
  static const String guideListPath = '/guide';
  static const String guideDetailPath = 'detail';
  static const String guideDetailRouteName = 'guideDetail';
  static const String upgradePath = '/upgrade';
  static const String searchPath = '/search';
  static const String profilePath = '/profile';
  static const String aiPersonalizedGuidePath = '/ai-guide';
  static const String preScanGuidePath = '/pre-scan-guide';
  static const String multiModeCameraPath = '/camera-scan';
  static const String taskInProgressLoadingPath = '/task-loading';
  static const String paymentSuccessCallbackPath = '/payment-success';
  static const String paymentWebViewPath = '/payment-webview';


  // ==========================================
  // NEW PREGNANCY TOOLS ROUTE PATHS
  // ==========================================
  static const String pregnancyToolsHubPath = '/pregnancy-tools';
  static const String lmpCalculatorPath = '/pregnancy-tools/lmp-calculator';
  static const String dueDateCalculatorPath = '/pregnancy-tools/due-date-calculator';
  static const String babyNameGeneratorPath = '/pregnancy-tools/baby-name-generator';
  static const String kickCounterPath = '/pregnancy-tools/kick-counter';
  static const String contractionTimerPath = '/pregnancy-tools/contraction-timer';
  static const String weightGainTrackerPath = '/pregnancy-tools/weight-gain-tracker';
  static const String weightGainTrackerAIPath = '/pregnancy-tools/weight-gain-tracker-ai'; // NEW PATH ADDED
  static const String hospitalBagChecklistPath = '/pregnancy-tools/hospital-bag-checklist';
  static const String babyShoppingListPath = '/pregnancy-tools/baby-shopping-list';
  static const String birthPlanPath = '/pregnancy-tools/birth-plan';
  static const String postpartumTrackerPath = '/pregnancy-tools/postpartum-tracker';
  static const String vaccineTrackerPath = '/pregnancy-tools/vaccine-tracker';
  static const String pregnancyTestCheckerPath = '/pregnancy-tools/pregnancy-test-checker'; // NEW: Pregnancy Test Checker
  static const String ttcTrackerPath = '/fertility/ttc-tracker';
  
  // UPDATED: Document Analysis moved to standalone path (no longer under /qna)
  static const String documentAnalysisPath = '/document-analysis';
  // ==========================================
  // END NEW PREGNANCY TOOLS ROUTE PATHS
  // ==========================================


  static bool isAuthFlowPath(String path) {
    return path == AppRouter.newWelcomePath ||
    path.startsWith(AppRouter.onboardingBasePath) ||
    path == AppRouter.accountCreationHubPath ||
    path == AppRouter.loginPath ||
    path == AppRouter.otpVerificationPath ||
    path == AppRouter.verifyIndiaMobilePath ||
    path == AppRouter.forgotPasswordPath ||
    path == AppRouter.welcomePath ||
    // Also consider the create password screen part of the auth flow
    path == AppRouter.createNewPasswordPath;
  }


  // --- The GoRouter is a lazy final variable, created ONCE ---
  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splashLoadingPath,
    debugLogDiagnostics: true,
    refreshListenable: authRedirectNotifier,


    // lib/navigation/app_router.dart


redirect: (BuildContext context, GoRouterState state) {
  final userProfile = ref.read(userProfileNotifierProvider);
  final currentLocation = state.matchedLocation;
  final hasFinishedInitialCheck = userProfile.hasInitialAuthCheckCompleted;
  final isLoggedIn = userProfile.isLoggedIn;
  final isPersonalized = userProfile.isPersonalized;
  final isGoogleAuthInProgress = UserProfileProvider.isGoogleOAuthInProgressGlobal;
  final isProfileLoading = userProfile.isLoading && !userProfile.isProfileLoaded;


  debugPrint("[Redirect] Path: $currentLocation, CheckDone: $hasFinishedInitialCheck, ProfileLoading: $isProfileLoading, LoggedIn: $isLoggedIn, Personalized: $isPersonalized, GoogleAuth: $isGoogleAuthInProgress");


  // 1. Password Recovery Deep Link
  if (userProfile.lastAuthEvent == AuthChangeEvent.passwordRecovery) {
    debugPrint("[Redirect] Password recovery event detected. Redirecting to createNewPasswordPath.");
    ref.read(userProfileNotifierProvider.notifier).consumeAuthEvent();
    return createNewPasswordPath;
  }


  // 2. Ongoing Async Processes like Google Sign-In
  if (isGoogleAuthInProgress) {
    debugPrint("[Redirect] Google OAuth is in progress. Forcing loading screen.");
    if (currentLocation == splashLoadingPath) return null;
    return splashLoadingPath;
  }


  // 3. Initial App Startup & Profile Loading
  if (!hasFinishedInitialCheck) {
    return splashLoadingPath;
  }


  if (isProfileLoading && !isAuthFlowPath(currentLocation)) {
    return splashLoadingPath;
  }


  // 4. Logged-Out User Logic
  if (!isLoggedIn) {
    if (isAuthFlowPath(currentLocation)) {
      return null;  // Let them stay on auth screens
    }
    return newWelcomePath;  // Redirect to welcome
  }


  // 5. Logged-In User Logic
  if (!isPersonalized) {
    // User is logged in but hasn't completed onboarding
    if (currentLocation.startsWith(onboardingBasePath)) {
      // Let them continue through onboarding screens
      return null;
    }
    
    // FIXED: If they're already on home or other app screens, let them stay there
    // This prevents existing users from being forced into onboarding after login
    if (!isAuthFlowPath(currentLocation) && 
        !currentLocation.startsWith(onboardingBasePath) &&
        currentLocation != splashLoadingPath) {
      debugPrint("[Redirect] User logged in but not personalized, already on app screen: $currentLocation. Allowing access.");
      return null;
    }
    
    // Only redirect to onboarding if they're on auth/welcome screens
    // This ensures new signups go through onboarding
    if (currentLocation == newWelcomePath || 
        currentLocation == accountCreationHubPath || 
        currentLocation == loginPath) {
      // FIXED: Check if we have a loaded profile with any data
      // If the profile is loaded and has a name/email, they're an existing user
      if (userProfile.isProfileLoaded && userProfile.fullName.isNotEmpty) {
        debugPrint("[Redirect] Existing user logged in. Sending to home instead of onboarding.");
        return homePath;
      }
      // New user without profile data, send to onboarding
      debugPrint("[Redirect] New user signup. Sending to onboarding.");
      return personalizeTrimesterPath;
    }
    return null;
  }


  // 6. User is logged in AND personalized
  if (isPersonalized) {
    // If they're on an auth/onboarding page, redirect to home
    if (isAuthFlowPath(currentLocation) || 
        currentLocation == splashLoadingPath || 
        currentLocation.startsWith(onboardingBasePath)) {
      // But allow task-in-progress screen
      if (currentLocation == taskInProgressLoadingPath) {
        return null;
      }
      // Only redirect if not already on home
      if (currentLocation != homePath) {
        return homePath;
      }
    }
  }


  // 7. Default: no redirect
  return null;
},


    routes: <RouteBase>[
      // ALL YOUR EXISTING ROUTES (UNCHANGED)
      GoRoute(
        path: AppRouter.splashLoadingPath,
        name: 'professionalLoading',
        builder: (context, state) => const ProfessionalLoadingScreen(),
      ),
      GoRoute(
        path: AppRouter.newWelcomePath,
        name: 'newWelcome',
        builder: (context, state) => const InteractiveWelcomeScreen(),
      ),
      GoRoute(
        path: AppRouter.personalizeTrimesterPath,
        name: 'personalizeTrimester',
        builder: (context, state) => const PersonalizeTrimesterScreen(),
      ),
      GoRoute(
        path: AppRouter.personalizeDietPath,
        name: 'personalizeDiet',
        builder: (context, state) => const PersonalizeDietScreen(),
      ),
      GoRoute(
        path: AppRouter.personalizeAllergiesPath,
        name: 'personalizeAllergies',
        builder: (context, state) => const PersonalizeAllergiesScreen(),
      ),
      GoRoute(
        path: AppRouter.personalizeGoalPath,
        name: 'personalizeGoal',
        builder: (context, state) => const PersonalizeGoalScreen(),
      ),
      // --- THIS IS THE MODIFIED ROUTE ---
      GoRoute(
        path: AppRouter.accountCreationHubPath,
        name: 'accountCreationHub',
        builder: (context, state) {
          // Read the optional 'extra' parameter
          bool startInSignIn = false;
          if (state.extra is Map<String, dynamic>) {
            startInSignIn = (state.extra as Map<String, dynamic>)['startInSignInMode'] ?? false;
          }
          return AccountCreationHubScreen(startInSignInMode: startInSignIn);
        },
      ),
      GoRoute(
        path: AppRouter.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
          path: AppRouter.otpVerificationPath,
          name: 'otp-verify',
          builder: (context, state) {
            final Map<String, String> args = state.extra as Map<String, String>;
            return OtpVerificationScreen(
              phoneNumber: args['phoneNumber']!,
              countryCode: args['countryCode']!,
              bhashSmsRef: args['bhashSmsRef'],
            );
          }),
      GoRoute(
          path: AppRouter.verifyIndiaMobilePath,
          name: 'verify-india-mobile',
          builder: (context, state) {
            return const VerifyIndiaMobileScreen();
          }),
      GoRoute(
          path: '/login-otp-verify',
          name: 'login-otp-verify',
          builder: (context, state) {
            final String phoneNumber = state.extra as String;
            return LoginOtpScreen(phoneNumber: phoneNumber);
          },
      ),
      GoRoute(
        path: AppRouter.forgotPasswordPath,
        name: 'forgot-password',
        builder: (context, state) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRouter.createNewPasswordPath,
        name: 'createNewPassword',
        builder: (context, state) => const CreateNewPasswordScreen(),
      ),
      GoRoute(
        path: AppRouter.preScanGuidePath,
        name: 'preScanGuide',
        builder: (context, state) => const PreScanGuideScreen(),
      ),
      GoRoute(
        path: AppRouter.multiModeCameraPath,
        name: 'multiModeCamera',
        builder: (context, state) => const MultiModeCameraScreen(),
      ),
      GoRoute(
        path: AppRouter.scanProductPath,
        builder: (context, state) => const ScanProductScreen(),
      ),
      GoRoute(
        path: AppRouter.scanResultsPath,
        name: AppRouter.scanResultsRouteName,
        builder: (context, state) {
          final dynamic extraData = state.extra;
          if (extraData is String && extraData.isNotEmpty) {
            return ScanResultsScreen(scanId: extraData);
          } else if (extraData is ScanData) {
            return ScanResultsScreen(scanData: extraData);
          } else {
            final String? scanIdFromQuery = state.uri.queryParameters['scanId'];
            if (scanIdFromQuery != null && scanIdFromQuery.isNotEmpty) {
              return ScanResultsScreen(scanId: scanIdFromQuery);
            } else {
              return Scaffold(
                appBar: AppBar(title: const Text("Navigation Error")),
                body: const Center(child: Text("Could not load scan results. Scan ID missing or invalid.")),
              );
            }
          }
        },
      ),
      GoRoute( 
        path: AppRouter.detailedAnalysisPath,
        name: 'detailedAnalysis',
        builder: (context, state) {
          final ScanData? scanData = state.extra as ScanData?;
          if (scanData != null) {
            return DetailedAnalysisScreen(scanData: scanData);
          }
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: const Center(child: Text("Error: Scan data missing for detailed analysis."))
          );
        }
      ),
      GoRoute(
        path: AppRouter.profilePath,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: AppRouter.searchPath,
        builder: (context, state) => const ManualSearchScreen(),
      ),
      GoRoute(
          path: AppRouter.upgradePath,
          name: 'upgrade',
          builder: (context, state) => const UpgradeScreen(),
      ),
      GoRoute(
        path: AppRouter.paymentWebViewPath,
        name: 'paymentWebView',
        builder: (context, state) {
          final String? checkoutUrl = state.extra as String?;
          if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
            return PaymentWebViewScreen(checkoutUrl: checkoutUrl);
          }
          return Scaffold(appBar: AppBar(), body: const Center(child: Text("Error: Payment link missing.")));
        },
      ),
      GoRoute(
        path: AppRouter.aiPersonalizedGuidePath,
        name: 'aiPersonalizedGuide',
        builder: (context, state) => const AiPersonalizedGuideScreen(),
      ),
      GoRoute(
        path: AppRouter.guideListPath,
        name: 'guideList',
        builder: (context, state) => const GuideScreen(),
        routes: [
          GoRoute(
            path: AppRouter.guideDetailPath,
            name: AppRouter.guideDetailRouteName,
            builder: (context, state) {
              final Guide guide = state.extra as Guide;
              return GuideDetailScreen(guide: guide);
            },
          ),
        ]
      ),
      GoRoute(
        path: AppRouter.taskInProgressLoadingPath,
        name: 'taskInProgressLoading',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TaskInProgressLoadingScreen(),
        ),
      ),
      GoRoute(
        path: AppRouter.paymentSuccessCallbackPath,
        name: 'paymentSuccessCallback',
        builder: (context, state) {
          final String? paymentId = state.uri.queryParameters['payment_id'];
          final String? status = state.uri.queryParameters['status'];
          final String? orderId = state.uri.queryParameters['order_id'];
          return PaymentStatusScreen(
            paymentId: paymentId,
            status: status,
            orderId: orderId,
          );
        },
      ),


      // ==========================================
      // NEW COMPLETE PREGNANCY TOOLS ROUTES
      // ==========================================


      // Pregnancy Tools Hub (Main entry point)
      GoRoute(
        path: AppRouter.pregnancyToolsHubPath,
        name: 'pregnancyToolsHub',
        builder: (context, state) => const PregnancyToolsHubScreen(),
      ),


      // Pregnancy Calculators
      GoRoute(
        path: AppRouter.lmpCalculatorPath,
        name: 'lmpCalculator',
        builder: (context, state) => const LmpCalculatorScreen(),
      ),
      GoRoute(
        path: AppRouter.dueDateCalculatorPath,
        name: 'dueDateCalculator',
        builder: (context, state) => const DueDateCalculatorScreen(),
      ),
      GoRoute(
        path: AppRouter.babyNameGeneratorPath,
        name: 'babyNameGenerator',
        builder: (context, state) => const BabyNameGeneratorScreen(),
      ),


      // Pregnancy Trackers
      GoRoute(
        path: AppRouter.kickCounterPath,
        name: 'kickCounter',
        builder: (context, state) => const KickCounterScreen(),
      ),
      GoRoute(
        path: AppRouter.contractionTimerPath,
        name: 'contractionTimer',
        builder: (context, state) => const ContractionTimerScreen(),
      ),
      GoRoute(
        path: AppRouter.weightGainTrackerPath,
        name: 'weightGainTracker',
        builder: (context, state) => const WeightGainTrackerScreen(),
      ),

      // --- Add new route for WeightGainAIInfoScreen streaming AI screen below Pregnancy Trackers ---
      GoRoute(
        path: AppRouter.weightGainTrackerAIPath,
        name: 'weightGainTrackerAI',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WeightGainAIInfoScreen(
            currentWeight: extra['currentWeight'],
            prePregnancyWeight: extra['prePregnancyWeight'],
            currentWeek: extra['currentWeek'],
            height: extra['height'],
            bmiCategory: extra['bmiCategory'],
          );
        },
      ),


      // Pregnancy Lists & Planning
      GoRoute(
        path: AppRouter.hospitalBagChecklistPath,
        name: 'hospitalBagChecklist',
        builder: (context, state) => const HospitalBagChecklistScreen(),
      ),
      GoRoute(
        path: AppRouter.babyShoppingListPath,
        name: 'babyShoppingList',
        builder: (context, state) => const BabyShoppingListScreen(),
      ),
      GoRoute(
        path: AppRouter.birthPlanPath,
        name: 'birthPlan',
        builder: (context, state) => const BirthPlanScreen(),
      ),
      GoRoute(
        path: AppRouter.postpartumTrackerPath,
        name: 'postpartumTracker',
        builder: (context, state) => const PostpartumTrackerScreen(),
      ),
      GoRoute(
        path: AppRouter.vaccineTrackerPath,
        name: 'vaccineTracker',
        builder: (context, state) => const VaccineTrackerScreen(),
      ),
      
      // NEW: Pregnancy Test Checker (Premium Feature)
      GoRoute(
        path: AppRouter.pregnancyTestCheckerPath,
        name: 'pregnancyTestChecker',
        builder: (context, state) => const PregnancyTestCheckerScreen(),
      ),


      // Fertility & TTC
      GoRoute(
        path: AppRouter.ttcTrackerPath,
        name: 'ttcTracker',
        builder: (context, state) => const TtcTrackerScreen(),
      ),


      // UPDATED: Document Analysis as Standalone Feature (No longer under /qna)
      GoRoute(
        path: AppRouter.documentAnalysisPath,
        name: 'documentAnalysis',
        builder: (context, state) => const DocumentAnalysisScreen(),
      ),


      // ==========================================
      // END NEW PREGNANCY TOOLS ROUTES
      // ==========================================


      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return HomeScreenShell(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRouter.homePath,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRouter.historyPath,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScanHistoryScreen(),
            ),
          ),
          GoRoute(
            path: AppRouter.askExpertPath,
            name: 'ask-expert-tab',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AskExpertScreen(),
            ),
          ),
          GoRoute(
            path: AppRouter.settingsPath,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileSettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
          child:
              Text('Error: ${state.error?.message ?? "Route not found"}')),
    ),
  );
}


// THIS CLASS IS UNCHANGED. IT IS CORRECT.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((dynamic _) {
      debugPrint("GoRouterRefreshStream: Notifying listeners due to stream event.");
      notifyListeners();
    });
  }
  late final StreamSubscription<dynamic> _subscription;


  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}