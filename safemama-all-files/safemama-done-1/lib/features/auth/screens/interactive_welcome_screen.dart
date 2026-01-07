// lib/features/onboarding/screens/interactive_welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/widgets/custom_button.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Data model for our welcome pages
class WelcomePageData {
  final String imagePath;
  final String title;
  final String description;
  WelcomePageData(
      {required this.imagePath,
      required this.title,
      required this.description});
}

class InteractiveWelcomeScreen extends ConsumerStatefulWidget {
  const InteractiveWelcomeScreen({super.key});

  @override
  ConsumerState<InteractiveWelcomeScreen> createState() =>
      _InteractiveWelcomeScreenState();
}

class _InteractiveWelcomeScreenState
    extends ConsumerState<InteractiveWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // State to track the current page index

  // Use your exact asset paths here
  late final List<WelcomePageData> welcomePages;

  @override
  void initState() {
    super.initState();
    // Add listener to update the page state
    _pageController.addListener(() {
      // Check if the controller has a client and the page has changed
      if (_pageController.hasClients &&
          _pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final S = AppLocalizations.of(context)!;
    // Initialize the list here to access localizations
    welcomePages = [
      WelcomePageData(
        imagePath: 'assets/images/welcome_anim_scan_ui.png',
        title: S.welcomeTitle1,
        description: S.welcomeDesc1,
      ),
      WelcomePageData(
        imagePath: 'assets/images/welcome_anim_scan_result_safe.png',
        title: S.welcomeTitle2,
        description: S.welcomeDesc2,
      ),
      WelcomePageData(
        imagePath: 'assets/images/welcome_anim_guide_list.png',
        title: S.welcomeTitle3,
        description: S.welcomeDesc3,
      ),
      WelcomePageData(
        imagePath: 'assets/images/welcome_anim_app_home.png',
        title: S.welcomeTitle4,
        description: S.welcomeDesc4,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLastPage = _currentPage == welcomePages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // This Expanded widget prevents the overflow error
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: welcomePages.length,
                itemBuilder: (_, index) {
                  final item = welcomePages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child:
                              Image.asset(item.imagePath, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item.title,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade600, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),

            // All bottom controls are now wrapped for conditional visibility
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: welcomePages.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Conditionally show the buttons
                  AnimatedOpacity(
                    opacity: isLastPage ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !isLastPage,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomElevatedButton(
                            text: S.getStarted,
                            onPressed: () =>
                                context.go(AppRouter.personalizeTrimesterPath),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(S.alreadyHaveAccountPrompt),
                              TextButton(
                                onPressed: () {
                                  // --- THIS IS THE FIX ---
                                  // Use push() so the welcome screen stays in the stack,
                                  // allowing the back button to work.
                                  context.push(AppRouter.accountCreationHubPath,
                                      extra: {'startInSignInMode': true});
                                },
                                child: Text(S.loginLink),
                              ),
                            ],
                          ),
                          if (!isLastPage) const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}