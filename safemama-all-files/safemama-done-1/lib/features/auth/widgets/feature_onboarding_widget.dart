// lib/features/auth/widgets/feature_onboarding_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/auth/models/onboarding_slide_content.dart';
import 'package:safemama/features/auth/widgets/onboarding_slide_widget.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/widgets/custom_button.dart'; // Your custom button
import 'package:safemama/l10n/app_localizations.dart'; // For button text
import 'package:safemama/core/constants/app_colors.dart'; // For indicator colors

class FeatureOnboardingWidget extends ConsumerStatefulWidget {
  const FeatureOnboardingWidget({super.key});

  @override
  ConsumerState<FeatureOnboardingWidget> createState() =>
      _FeatureOnboardingWidgetState();
}

class _FeatureOnboardingWidgetState extends ConsumerState<FeatureOnboardingWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<OnboardingSlideContent> _slides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // _slides are initialized in didChangeDependencies or build to access context for localization
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize slides here if they depend on context (e.g., for localization)
    // For now, our list function doesn't strictly need context yet, but it's good practice
    _slides = onboardingSlidesContentList(context); 
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onNextPressed() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page, navigate to personalization
      context.go(AppRouter.personalizeTrimesterPath);
    }
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.textLight.withOpacity(0.5), // Use your app colors
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!; // For button text

    // Initialize slides here if not done in didChangeDependencies
    // or if onboardingSlidesContentList is now context-dependent for localization
    if (_slides.isEmpty && mounted) { // Check if _slides is empty and widget is mounted
       _slides = onboardingSlidesContentList(context);
    }
    if (_slides.isEmpty) return const SizedBox.shrink(); // Return empty if slides still not loaded

    return Column(
      children: <Widget>[
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return OnboardingSlideWidget(content: _slides[index]);
            },
          ),
        ),
        const SizedBox(height: 20),
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_slides.length, (int index) {
            return _buildPageIndicator(index == _currentPage);
          }),
        ),
        const SizedBox(height: 30),
        // Next / Get Started Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // Match InteractiveWelcomeScreen padding
          child: CustomElevatedButton(
            text: _currentPage == _slides.length - 1
                ? S.getStartedButton // "Get Started" on the last slide
                : S.nextButton, // You'll need to add "nextButton" to your l10n files
            onPressed: _onNextPressed,
          ),
        ),
      ],
    );
  }
}