// lib/features/auth/widgets/onboarding_slide_widget.dart
import 'package:flutter/material.dart';
import 'package:safemama/features/auth/models/onboarding_slide_content.dart';
import 'package:safemama/core/constants/app_colors.dart'; // Assuming you have text colors here

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlideContent content;

  const OnboardingSlideWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    // Define an aspect ratio for the image display area
    const double imageAspectRatio = 9.0 / 19.5; // Width / Height of the mock-up image area
    
    // Define max height for the image based on screen height to leave space for text
    final double maxImageHeight = screenHeight * 0.55; // e.g., image takes up to 55% of screen height
    final double imageDisplayWidth = (maxImageHeight * imageAspectRatio).clamp(0, screenWidth * 0.8); // Calculate width, clamp to 80% of screen width
    final double imageDisplayHeight = imageDisplayWidth / imageAspectRatio;


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Overall padding for the slide
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Image (App Screenshot)
          SizedBox(
            width: imageDisplayWidth,
            height: imageDisplayHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0), // Match previous styling
              child: Image.asset(
                content.imagePath,
                fit: BoxFit.contain, // Ensure whole image is visible
              ),
            ),
          ),
          const SizedBox(height: 32.0), // Space between image and text

          // Title
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark, // Use your app's text color
            ),
          ),
          const SizedBox(height: 12.0),

          // Subtitle
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textLight, // Use your app's secondary text color
            ),
          ),
        ],
      ),
    );
  }
}