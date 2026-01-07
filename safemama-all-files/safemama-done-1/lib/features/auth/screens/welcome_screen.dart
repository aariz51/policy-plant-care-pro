// lib/features/auth/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/l10n/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int? _selectedTrimester; // 1, 2, or 3

  // Asset paths for trimester icons (ensure these match your actual asset paths)
  final String _firstTrimesterIconPath = 'assets/icons/icon_trimester_first.png';
  final String _secondTrimesterIconPath = 'assets/icons/icon_trimester_second.png';
  final String _thirdTrimesterIconPath = 'assets/icons/icon_trimester_third.png';
  // ***** NEW: Path for the main illustration *****
  final String _onboardingIllustrationPath = 'assets/illustrations/illustration_onboarding_welcome_mommy.png';


  @override
  Widget build(BuildContext context) {
    // Try this explicit way to get AppLocalizations
    final AppLocalizations? S = Localizations.of<AppLocalizations>(context, AppLocalizations);
    
    print("[WelcomeScreen] Build method CALLED. S is ${S == null ? 'null' : 'NOT null'}");

    if (S == null) {
      print("[WelcomeScreen] AppLocalizations (via Localizations.of) is NULL. Showing loading indicator.");
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Loading translations..."), // Different loading message for clarity
            ],
          ),
        ),
      );
    }

    // If S is not null, proceed to build your actual WelcomeScreen UI
    // Using S.welcomeScreenTitle (which could be null if not in .arb) for the print.
    // The Text widget below will use '?? "Welcome"' as a fallback for display.
    print("[WelcomeScreen] AppLocalizations FOUND. Title: ${S.welcomeScreenTitle}");
    
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryPurple.withOpacity(0.05),
              AppTheme.primaryBlue.withOpacity(0.03),
              Colors.white.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight * 0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      _onboardingIllustrationPath, // Use the defined path
                      height: screenHeight * 0.25,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: screenHeight * 0.25,
                        color: AppTheme.dividerColor.withOpacity(0.5),
                        // Consistent with new UI, show placeholder icon for image error
                        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: AppTheme.textSecondary)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      S.welcomeScreenTitle ?? "Welcome", // Uses "Welcome, Mama!" from your arb, with fallback
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        // This key was added/updated in the arb files based on the new UI.
                        // It should resolve to "Let's keep your pregnancy safe — one scan at a time."
                        S.welcomeScreenNewSubtitle,
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Text(
                      // This key was updated in the arb files.
                      // It should resolve to "Select Your Trimester:"
                      S.welcomeScreenSelectTrimesterPrompt,
                      style: textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    _buildTrimesterButton(
                      context: context,
                      trimesterValue: 1,
                      iconPath: _firstTrimesterIconPath,
                      title: S.trimester1st, // Uses "1st Trimester" from your arb
                      subtitle: S.trimester1stWeeks, // Uses "Weeks 1-12" from your arb
                    ),
                    const SizedBox(height: 12),
                    _buildTrimesterButton(
                      context: context,
                      trimesterValue: 2,
                      iconPath: _secondTrimesterIconPath,
                      title: S.trimester2nd, // Uses "2nd Trimester" from your arb
                      subtitle: S.trimester2ndWeeks, // Uses "Weeks 13-26" from your arb
                    ),
                    const SizedBox(height: 12),
                    _buildTrimesterButton(
                      context: context,
                      trimesterValue: 3,
                      iconPath: _thirdTrimesterIconPath,
                      title: S.trimester3rd, // Uses "3rd Trimester" from your arb
                      subtitle: S.trimester3rdWeeks, // Uses "Weeks 27-40" from your arb
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton(
                      style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              return AppTheme.primaryPurple.withOpacity(0.5);
                            }
                            return AppTheme.primaryPurple;
                          },
                        ),
                        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      ),
                      onPressed: _selectedTrimester == null
                          ? null
                          : () {
                              // ***** CORRECTED NAVIGATION for New User Flow *****
                              print("WelcomeScreen: Get Started tapped with trimester: $_selectedTrimester. Navigating to Signup.");
                              // For a new user, "Get Started" should go to the Signup screen.
                              // The selected trimester is not typically passed directly to signup,
                              // but rather captured during the personalization step AFTER login.
                              // So, we just navigate to signupPath.
                              context.go(AppRouter.signupPath);
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            S.getStartedButton ?? "Get Started", // Uses "Get Started" from your arb, with fallback
                            style: textTheme.labelLarge
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            // MODIFIED: Increased icon size
                            size: 24, // Was 20
                            color: textTheme.labelLarge?.color,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // This helper widget's structure and logic remain unchanged,
  // it just uses the L10N keys passed to it.
  Widget _buildTrimesterButton({
    required BuildContext context,
    required int trimesterValue,
    required String iconPath,
    required String title, // Comes from S.trimester1st etc.
    required String subtitle, // Comes from S.trimester1stWeeks etc.
  }) {
    final bool isSelected = _selectedTrimester == trimesterValue;
    final textTheme = Theme.of(context).textTheme;

    // Define a new, larger size for the icons
    const double iconSize = 40.0; // Was implicitly 32x32 from width/height

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTrimester = trimesterValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.1) : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppTheme.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              // MODIFIED: Increased width and height
              width: iconSize,  // Was 32
              height: iconSize, // Was 32
              // STEP 1: Comment out the 'color' property (already done by you)
              // color: isSelected ? AppTheme.primaryPurple : AppTheme.iconColor,
              
              // STEP 2 (If STEP 1 doesn't fully help): Experiment with 'fit' property
              fit: BoxFit.contain, // Added fit to ensure proper scaling

              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                // Using context, error, stackTrace parameters for better debugging
                print("Error loading trimester icon: $iconPath. Error: $error"); // Add a print statement here
                return Icon(
                  Icons.image_not_supported_outlined, // Use a different error icon to distinguish
                  color: AppTheme.textPrimary, // Use a clearly visible color
                  // MODIFIED: Increased error icon size to match main icon
                  size: iconSize // Was 32
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: isSelected ? AppTheme.primaryPurple.withOpacity(0.8) : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryPurple, size: 24), // Kept this check_circle size as is, or it can be increased if desired.
          ],
        ),
      ),
    );
  }
}