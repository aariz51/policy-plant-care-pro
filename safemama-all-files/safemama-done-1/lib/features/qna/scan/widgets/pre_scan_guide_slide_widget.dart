// lib/features/scan/widgets/pre_scan_guide_slide_widget.dart
import 'package:flutter/material.dart';
import 'package:safemama/features/qna/scan/models/pre_scan_guide_slide.dart';
import 'package:safemama/core/constants/app_colors.dart'; // Or your theme colors

class PreScanGuideSlideWidget extends StatelessWidget {
  final PreScanGuideSlide slide;

  const PreScanGuideSlideWidget({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 5, // Give more space to the image
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Image.asset(
                slide.imagePath,
                fit: BoxFit.contain, // Show the whole illustration
                errorBuilder: (context, error, stackTrace) => 
                    const Center(child: Icon(Icons.broken_image, size: 100, color: Colors.grey)),
              ),
            ),
          ),
          Expanded(
            flex: 3, // Space for text
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark, // Adjust color as needed
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textLight, // Adjust color as needed
                    height: 1.4, // Improved line spacing for readability
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

