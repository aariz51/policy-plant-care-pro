// lib/features/auth/screens/professional_loading_screen.dart
import 'package:flutter/material.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/widgets/rich_animated_loading_widget.dart'; // UPDATED IMPORT

class ProfessionalLoadingScreen extends StatelessWidget {
  const ProfessionalLoadingScreen({super.key});

  // Gradient colors previously defined here are no longer needed
  // as RichAnimatedLoadingWidget handles its own background.

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    // Use a fallback if S is null, though less likely if your app setup is correct
    final List<String> launchTexts = [
      S?.appLoadingMessage1 ?? "Hold on, we're checking what's best for you and your baby...",
      S?.appLoadingMessage2 ?? "Analyzing vital information...",
      S?.appLoadingMessage3 ?? "Preparing your personalized guidance...",
      S?.appLoadingMessage4 ?? "Almost there, excitement is building!",
    ];

    // Ensure there's at least one message for initialText if localization fails badly
    final String initialText = launchTexts.isNotEmpty
                               ? launchTexts.first
                               : "Loading...";

    // Directly return RichAnimatedLoadingWidget, which is now a full-screen Scaffold itself
    return RichAnimatedLoadingWidget(
      loadingTexts: launchTexts,
      initialText: initialText,
      // heartIconSvgPath parameter is removed from RichAnimatedLoadingWidget
    );
  }
}