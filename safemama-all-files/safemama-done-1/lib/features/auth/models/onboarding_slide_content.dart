// lib/features/auth/models/onboarding_slide_content.dart

// Add this import for BuildContext:
import 'package:flutter/material.dart';
// Add this import if you are using S directly here:
import 'package:safemama/l10n/app_localizations.dart';

class OnboardingSlideContent {
  final String imagePath;
  final String title;
  final String subtitle;

  OnboardingSlideContent({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}

// List of onboarding content
List<OnboardingSlideContent> onboardingSlidesContentList(BuildContext context) {
  // Now that BuildContext is defined, you can get S here
  final S = AppLocalizations.of(context)!;
  
  return [
    OnboardingSlideContent(
      imagePath: 'assets/images/welcome_anim_app_home.png',
      // Replace these with actual keys you've added to your .arb files
      title: S.onboarding_slide1_title, // e.g., "Welcome to SafeMama"
      subtitle: S.onboarding_slide1_subtitle, // e.g., "Your trusted companion..."
    ),
    OnboardingSlideContent(
      imagePath: 'assets/images/welcome_anim_guide_list.png',
      title: S.onboarding_slide2_title, // e.g., "Personalized For You"
      subtitle: S.onboarding_slide2_subtitle, // e.g., "Access tailored guidance..."
    ),
    OnboardingSlideContent(
      imagePath: 'assets/images/welcome_anim_scan_ui.png',
      title: S.onboarding_slide3_title, // e.g., "Instant Safety Checks"
      subtitle: S.onboarding_slide3_subtitle, // e.g., "Quickly scan food..."
    ),
    OnboardingSlideContent(
      imagePath: 'assets/images/welcome_anim_scan_result_safe.png',
      title: S.onboarding_slide4_title, // e.g., "Clear, Actionable Advice"
      subtitle: S.onboarding_slide4_subtitle, // e.g., "Understand safety with..."
    ),
  ];
}