// lib/core/constants/app_constants.dart

class AppConstants {
  // API and Backend Configuration
  // Ensure this is the correct and accessible URL for your backend server
static const String yourBackendBaseUrl = 'http://192.168.29.229:3001';


  // Application Specific Constants
  static const String appName = 'SafeMama';

  // --- NEW: Pricing Constants (in INR) ---
  static const double premiumMonthlyPrice = 399.00;
  static const double premiumYearlyPrice = 3999.00;
  
  // ===================================================================
  // ============ THIS IS THE FINAL, CORRECTED LIMITS BLOCK ============
  // ===================================================================

  // Free Tier Limits (One-time allowance)
  static const int freeScanLimit = 3;
  static const int freeAskExpertLimit = 3;

  // Premium Monthly Tier Limits
  static const int premiumMonthlyScanLimit = 50;
  static const int premiumMonthlyAskExpertLimit = 25;
  static const int premiumMonthlyGuideLimit = 5;
  static const int premiumMonthlyManualSearchLimit = 25;

  // Premium Yearly Tier Limits
  static const int premiumYearlyScanLimit = -1; // -1 represents UNLIMITED for the UI
  static const int premiumYearlyAskExpertLimit = 350;
  static const int premiumYearlyGuideLimit = 65;
  static const int premiumYearlyManualSearchLimit = 350;
  
  // ===================================================================
  // ====================== END OF CORRECTIONS =========================
  // ===================================================================

  // UI Constants (Examples - you can expand this)
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Duration Constants (Examples)
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);

  // Default values or Keys for SharedPreferences (Examples)
  static const String prefsKeySelectedLanguage = 'selected_language_code';
  static const String prefsKeyOnboardingComplete = 'onboarding_complete';
  static const String prefsKeyHasSeenWelcome = 'has_seen_welcome';

  // Feature Flags (Example - if you use feature flagging)
  // static const bool enableExperimentalFeatureX = false;

  // Other constants as your app grows
  // e.g., default image placeholders, specific numerical limits, etc.
  static const String defaultProfileImageUrl = 'assets/icons/icon_profile_avatar_placeholder.png'; // Example

}

// You can also define top-level constants if you prefer not to use a class:
// const String kYourBackendBaseUrl = 'http://192.168.29.229:3001';
// const int kFreeScanLimit = 4;