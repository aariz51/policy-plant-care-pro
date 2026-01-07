// lib/features/auth/widgets/animated_phone_showcase.dart
import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedPhoneShowcase extends StatefulWidget {
  const AnimatedPhoneShowcase({super.key});

  @override
  State<AnimatedPhoneShowcase> createState() => _AnimatedPhoneShowcaseState();
}

class _AnimatedPhoneShowcaseState extends State<AnimatedPhoneShowcase> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<String> _appScreenAssets = [
    'assets/images/welcome_anim_app_home.png',       // e.g., SafeMama smiley
    'assets/images/welcome_anim_guide_list.png',     // e.g., Hello, Sarah! SafeScan
    'assets/images/welcome_anim_scan_ui.png',        // e.g., Scanning... pineapple
    'assets/images/welcome_anim_scan_result_safe.png',// e.g., Scan Result pineapple
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAnimationTimer();
  }

  void _startAnimationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < _appScreenAssets.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double phoneScreenAspectRatio = 9.0 / 19.5; // Target Width / Height for the container

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableHeight = constraints.maxHeight;
        // final double availableWidth = constraints.maxWidth; // Less directly used now

        double showcaseHeight = availableHeight * 0.90; // Use 90% of available vertical space
        double showcaseWidth = showcaseHeight * phoneScreenAspectRatio;

        final double maxPermittedWidth = MediaQuery.of(context).size.width * 0.75;
        if (showcaseWidth > maxPermittedWidth) {
          showcaseWidth = maxPermittedWidth;
          showcaseHeight = showcaseWidth / phoneScreenAspectRatio;
        }
        
        if (showcaseHeight <= 0) showcaseHeight = 200;
        if (showcaseWidth <= 0) showcaseWidth = showcaseHeight * phoneScreenAspectRatio;

        return Center(
          child: SizedBox(
            width: showcaseWidth,
            height: showcaseHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              // Optional: Add a background to the ClipRRect if images with different
              // aspect ratios leave empty space and you want it filled with a color.
              // For now, it will be transparent to the Scaffold's background.
              // child: Container(
              //   color: Colors.grey[200], // Example subtle background
              child: PageView.builder(
                controller: _pageController,
                itemCount: _appScreenAssets.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding( // Add slight padding around each image if desired
                    padding: const EdgeInsets.all(0.0), // Start with 0, increase if needed for spacing from ClipRRect edge
                    child: Image.asset(
                      _appScreenAssets[index],
                      fit: BoxFit.contain, // <<< KEY CHANGE HERE
                    ),
                  );
                },
              ),
              // ),
            ),
          ),
        );
      },
    );
  }
}