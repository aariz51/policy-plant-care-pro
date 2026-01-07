// lib/core/models/subscription_plan.dart

/// Centralized source of truth for subscription plans and their limits
/// This matches the backend limits configuration and ensures consistency
class SubscriptionPlan {
  final String id;
  final String displayName;
  final String periodName; // "Free", "Weekly", "Monthly", "Yearly"
  final Duration period;
  final PlanLimits limits;

  const SubscriptionPlan({
    required this.id,
    required this.displayName,
    required this.periodName,
    required this.period,
    required this.limits,
  });

  /// Get plan by tier name (from database)
  static SubscriptionPlan fromTier(String? tier) {
    final tierLower = tier?.toLowerCase() ?? '';
    
    if (tierLower == 'premium_weekly' || tierLower == 'premiumweekly') {
      return SubscriptionPlan.premiumWeekly;
    } else if (tierLower == 'premium_monthly' || tierLower == 'premiummonthly' || tierLower == 'premium') {
      return SubscriptionPlan.premiumMonthly;
    } else if (tierLower == 'premium_yearly' || tierLower == 'premiumyearly') {
      return SubscriptionPlan.premiumYearly;
    }
    
    return SubscriptionPlan.free;
  }

  /// Free Plan (forever, but limits reset monthly)
  static const SubscriptionPlan free = SubscriptionPlan(
    id: 'free',
    displayName: 'Free',
    periodName: 'Forever',
    period: Duration(days: 30), // Limits reset monthly
    limits: PlanLimits(
      scans: 3,
      askExpert: 3,
      manualSearches: 0,
      aiGuides: 0,
      documentAnalyses: 0,
      pregnancyTestAI: 0,
      hasPremiumTools: false,
    ),
  );

  /// Premium Weekly Plan (₹149/week ~ $2.49)
  static const SubscriptionPlan premiumWeekly = SubscriptionPlan(
    id: 'premium_weekly',
    displayName: 'Premium Weekly',
    periodName: 'Week',
    period: Duration(days: 7),
    limits: PlanLimits(
      scans: 20,
      askExpert: 10,
      manualSearches: 10,
      aiGuides: 3,
      documentAnalyses: 5,
      pregnancyTestAI: 3,
      hasPremiumTools: true,
    ),
  );

  /// Premium Monthly Plan (₹499/month ~ $4.99)
  static const SubscriptionPlan premiumMonthly = SubscriptionPlan(
    id: 'premium_monthly',
    displayName: 'Premium Monthly',
    periodName: 'Month',
    period: Duration(days: 30),
    limits: PlanLimits(
      scans: 100,
      askExpert: 40,
      manualSearches: 40,
      aiGuides: 10,
      documentAnalyses: 15,
      pregnancyTestAI: 8,
      hasPremiumTools: true,
    ),
  );

  /// Premium Yearly Plan (₹3,999/year ~ $39.99)
  static const SubscriptionPlan premiumYearly = SubscriptionPlan(
    id: 'premium_yearly',
    displayName: 'Premium Yearly',
    periodName: 'Year',
    period: Duration(days: 365),
    limits: PlanLimits(
      scans: 1000, // Enforced but displayed as "Unlimited"
      askExpert: 400,
      manualSearches: 400,
      aiGuides: 80,
      documentAnalyses: 200,
      pregnancyTestAI: 40,
      hasPremiumTools: true,
    ),
  );

  /// Check if user is premium
  bool get isPremium => id != 'free';

  /// Get display string for limit (handles "Unlimited" display for yearly)
  String getLimitDisplay(String featureName) {
    if (id == 'premium_yearly' && featureName == 'scans') {
      return 'Unlimited scans';
    }
    
    int limit = _getLimit(featureName);
    if (limit == -1) return 'Unlimited';
    return '$limit per $periodName';
  }

  int _getLimit(String featureName) {
    switch (featureName) {
      case 'scans': return limits.scans;
      case 'askExpert': return limits.askExpert;
      case 'manualSearches': return limits.manualSearches;
      case 'aiGuides': return limits.aiGuides;
      case 'documentAnalyses': return limits.documentAnalyses;
      case 'pregnancyTestAI': return limits.pregnancyTestAI;
      default: return 0;
    }
  }
}

/// Quota limits for each plan
class PlanLimits {
  final int scans;
  final int askExpert;
  final int manualSearches;
  final int aiGuides;
  final int documentAnalyses;
  final int pregnancyTestAI;
  final bool hasPremiumTools; // Access to all premium pregnancy tools

  const PlanLimits({
    required this.scans,
    required this.askExpert,
    required this.manualSearches,
    required this.aiGuides,
    required this.documentAnalyses,
    required this.pregnancyTestAI,
    required this.hasPremiumTools,
  });
}

/// Product ID mappings for stores
class StoreProductIds {
  // Google Play Product IDs
  static const String googleWeekly = 'safemama_premium_weekly';
  static const String googleMonthly = 'safemama_premium_monthly';
  static const String googleYearly = 'safemama_premium_yearly';

  // Apple Product IDs (case-insensitive matching on backend)
  static const String appleWeekly = 'safemama_premium_weekly'; // Or your actual Apple product ID
  static const String appleMonthly = 'safemama_premium_monthly';
  static const String appleYearly = 'safemama_premium_yearly';

  /// Map product ID to tier name
  static String productIdToTier(String productId) {
    final idLower = productId.toLowerCase();
    
    if (idLower.contains('weekly')) {
      return 'premium_weekly';
    } else if (idLower.contains('yearly')) {
      return 'premium_yearly';
    } else if (idLower.contains('monthly')) {
      return 'premium_monthly';
    }
    
    return 'premium_monthly'; // Default fallback
  }

  /// Map tier name to Google Play product ID
  static String tierToGoogleProductId(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium_weekly':
      case 'premiumweekly':
        return googleWeekly;
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium':
        return googleMonthly;
      case 'premium_yearly':
      case 'premiumyearly':
        return googleYearly;
      default:
        return googleMonthly;
    }
  }

  /// Map tier name to Apple product ID
  static String tierToAppleProductId(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium_weekly':
      case 'premiumweekly':
        return appleWeekly;
      case 'premium_monthly':
      case 'premiummonthly':
      case 'premium':
        return appleMonthly;
      case 'premium_yearly':
      case 'premiumyearly':
        return appleYearly;
      default:
        return appleMonthly;
    }
  }
}

