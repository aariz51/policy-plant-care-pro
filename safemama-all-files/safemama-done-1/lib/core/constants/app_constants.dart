// lib/core/constants/app_constants.dart

class AppConstants {
  // API and Backend Configuration
  // Ensure this is the correct and accessible URL for your backend server
static const String yourBackendBaseUrl = 'http://192.168.29.229:3001';

  // Application Specific Constants
  static const String appName = 'SafeMama';

  // ===================================================================
  // =============== APP STORE & PLAY STORE LINKS =====================
  // ===================================================================
  // TODO: Replace with actual store URLs before production release
  static const String appStoreUrl = 'https://apps.apple.com/app/safemama/id123456789'; // TODO: Update with real App Store ID
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.safemama.app'; // TODO: Update with real package name
  static const String appDeepLinkBase = 'https://safemama.page.link'; // Firebase Dynamic Links or custom deep link
  
  // ===================================================================
  // ============ PRICING CONSTANTS (INR) - TIER STRUCTURE ============
  // ===================================================================
  static const double premiumWeeklyPrice = 149.00;
  static const double premiumMonthlyPrice = 499.00;
  static const double premiumYearlyPrice = 3999.00;
  
  // ===================================================================
  // ============ USAGE LIMITS PER TIER - UPDATED STRUCTURE ===========
  // ===================================================================

  // Free Tier Limits
  static const int freeScanLimit = 3;
  static const int freeAskExpertLimit = 3;
  static const int freeGuideLimit = 0;
  static const int freeManualSearchLimit = 0;
  static const int freeDocumentAnalysisLimit = 0;
  static const int freePregnancyTestAILimit = 0;

  // Premium Weekly Tier Limits (per week)
  static const int premiumWeeklyScanLimit = 20;
  static const int premiumWeeklyAskExpertLimit = 10;
  static const int premiumWeeklyGuideLimit = 3;
  static const int premiumWeeklyManualSearchLimit = 10;
  static const int premiumWeeklyDocumentAnalysisLimit = 5;
  static const int premiumWeeklyPregnancyTestAILimit = 3;

  // Premium Monthly Tier Limits (per month)
  static const int premiumMonthlyScanLimit = 100;
  static const int premiumMonthlyAskExpertLimit = 40;
  static const int premiumMonthlyGuideLimit = 10;
  static const int premiumMonthlyManualSearchLimit = 40;
  static const int premiumMonthlyDocumentAnalysisLimit = 15;
  static const int premiumMonthlyPregnancyTestAILimit = 8;

  // Premium Yearly Tier Limits (per year)
  static const int premiumYearlyScanLimit = 1000; // Practically unlimited
  static const int premiumYearlyAskExpertLimit = 400;
  static const int premiumYearlyGuideLimit = 80;
  static const int premiumYearlyManualSearchLimit = 400;
  static const int premiumYearlyDocumentAnalysisLimit = 200;
  static const int premiumYearlyPregnancyTestAILimit = 40;
  
  // ===================================================================
  // ==================== REVENEUECAT PRODUCT IDS ======================
  // ===================================================================
  // These are your PRODUCTION product IDs from Google Play Console
  // When using RevenueCat Test Store, you use the SAME product IDs for testing!
  // No need to create separate test product IDs.
  
  static const String productIdPremiumWeekly = 'safemama_premium_weekly';
  static const String productIdPremiumMonthly = 'safemama_premium_monthly';
  static const String productIdPremiumYearly = 'safemama_premium_yearly';
  
  // ===================================================================
  // ====================== END OF LIMITS BLOCK ========================
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