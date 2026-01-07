// lib/features/auth/screens/professional_loading_screen.dart
import 'package:flutter/material.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/widgets/rich_animated_loading_widget.dart'; // Your new widget

class ProfessionalLoadingScreen extends StatelessWidget {
  const ProfessionalLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final List<String> launchTexts = [
      S.appLoadingMessage1 ?? "Hold on, we're checking what's best for you and your baby...",
      S.appLoadingMessage2 ?? "Analyzing vital information...",
      S.appLoadingMessage3 ?? "Preparing your personalized guidance...",
      S.appLoadingMessage4 ?? "Almost there, excitement is building!",
    ];

    // RichAnimatedLoadingWidget is now a full-screen widget itself
    return RichAnimatedLoadingWidget(
      loadingTexts: launchTexts,
      initialText: launchTexts.first,
      // Pass your SVG path if you have one for the heart EKG icon:
      // heartIconSvgPath: 'assets/icons/your_heart_ekg_icon.svg', 
    );
  }
}