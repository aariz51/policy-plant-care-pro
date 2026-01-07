// lib/features/auth/screens/interactive_welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/constants/app_colors.dart';
import 'package:safemama/core/widgets/custom_button.dart'; // Your custom button

class InteractiveWelcomeScreen extends ConsumerWidget {
  const InteractiveWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: screenHeight * 0.05),

              Text(
                // You might want a new, more concise title for this screen
                // For now, we can reuse or you can add a new key to your l10n files
                S.welcomeTitleNew, // Example: "Welcome to SafeMama" or just "SafeMama"
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                // Similarly, a concise tagline for the animation screen
                S.welcomeSubtitleNew, // Example: "Guidance at your fingertips."
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                ),
              ),

              const Spacer(), // Pushes animation to the vertical center

              // Placeholder for the animated phone showcase
              Container(
                height: screenHeight * 0.55, // Adjusted for a bit more prominence
                width: screenWidth * 0.8,  // Max width for the phone mock-up area
                alignment: Alignment.center,
                // You can add a temporary border to visualize
                // decoration: BoxDecoration(
                //   border: Border.all(color: Colors.grey.shade400),
                //   borderRadius: BorderRadius.circular(20),
                // ),
                child: const Text(
                  "[Animated Phone Showcase Area]",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const Spacer(), // Pushes button towards the bottom

              CustomElevatedButton(
                text: S.getStartedButton,
                onPressed: () {
                  // This navigates to your existing personalization flow
                  context.go(AppRouter.personalizeTrimesterPath);
                },
              ),
              SizedBox(height: screenHeight * 0.03), // Reduced bottom padding a bit
            ],
          ),
        ),
      ),
    );
  }
}