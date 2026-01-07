// lib/features/scan/models/pre_scan_guide_slide.dart
import 'package:flutter/material.dart'; // For BuildContext if localizing here
import 'package:safemama/l10n/app_localizations.dart'; // For S

class PreScanGuideSlide {
  final String imagePath; // Illustrative image (not app screenshot)
  final String title;
  final String subtitle;
  // final IconData? icon; // Optional: if you want a small icon with the text

  PreScanGuideSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    // this.icon,
  });
}

// Define the content for the pre-scan guide slides
List<PreScanGuideSlide> getPreScanGuideSlides(BuildContext context) {
  final S = AppLocalizations.of(context)!;
  return [
    PreScanGuideSlide(
      imagePath: 'assets/images/prescan_guide_focus.png', // This path is correct
      title: S.preScanSlide1Title, // e.g., "Clear View is Key"
      subtitle: S.preScanSlide1Subtitle, // e.g., "Ensure the item is well-lit and in focus."
    ),
    PreScanGuideSlide(
      imagePath: 'assets/images/prescan_guide_label.png', // This path is correct
      title: S.preScanSlide2Title, // e.g., "Capture All Text"
      subtitle: S.preScanSlide2Subtitle, // e.g., "For labels, make sure all ingredients are visible."
    ),
    PreScanGuideSlide(
      imagePath: 'assets/images/prescan_guide_one_item.png', // This path is correct
      title: S.preScanSlide3Title, // e.g., "One Item for Best Results"
      subtitle: S.preScanSlide3Subtitle, // e.g., "Scan individual items for accurate analysis."
    ),
  ];
}


