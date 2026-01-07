// lib/features/scan/screens/pre_scan_guide_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/qna/scan/models/pre_scan_guide_slide.dart';
import 'package:safemama/features/qna/scan/widgets/pre_scan_guide_slide_widget.dart';
import 'package:safemama/navigation/app_router.dart'; // For camera screen path later
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/constants/app_colors.dart';
import 'package:safemama/core/widgets/custom_button.dart'; // Your custom button

class PreScanGuideScreen extends ConsumerStatefulWidget {
  const PreScanGuideScreen({super.key});

  @override
  ConsumerState<PreScanGuideScreen> createState() => _PreScanGuideScreenState();
}

class _PreScanGuideScreenState extends ConsumerState<PreScanGuideScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<PreScanGuideSlide> _slides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Slides will be initialized in didChangeDependencies or build
    // Initialize _slides as an empty list to avoid late initialization errors before didChangeDependencies
    _slides = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize slides here as getPreScanGuideSlides requires context for S
    _slides = getPreScanGuideSlides(context);
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

  void _onButtonPressed() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page: Navigate to the new multi-mode camera screen
      context.pushReplacement(AppRouter.multiModeCameraPath); // <<< CHANGED THIS LINE
    }
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.textLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    // Ensure slides are initialized if not done in didChangeDependencies
    // This check might be redundant if initState initializes _slides to empty and didChangeDependencies always populates it
    if (_slides.isEmpty && mounted) {
       _slides = getPreScanGuideSlides(context);
    }
    // Handle case where slides might still be empty (e.g., context not fully available yet for S)
    if (_slides.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));


    return Scaffold(
      appBar: AppBar(
        title: Text(S.preScanGuideScreenTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppColors.textDark, 
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0), 
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return PreScanGuideSlideWidget(slide: _slides[index]);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_slides.length, (int index) {
                  return _buildPageIndicator(index == _currentPage);
                }),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomElevatedButton(
                  text: _currentPage == _slides.length - 1
                      ? S.preScanGuideStartScanningButton 
                      : S.nextButton, 
                  onPressed: _onButtonPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

