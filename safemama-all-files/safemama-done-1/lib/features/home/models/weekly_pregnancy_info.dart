// lib/features/home/models/weekly_pregnancy_info.dart
class WeeklyPregnancyInfo {
  final int weekNumber;
  final String babySizeComparison_en; // Example: "a poppy seed", "an avocado"
  final String babyDevelopmentHighlights_en;
  // Add other languages as needed if you plan to store them directly in this model:
  // final String babySizeComparison_hi;
  // final String babyDevelopmentHighlights_hi;
  // final String babySizeComparison_ar;
  // final String babyDevelopmentHighlights_ar;
  // You might also add an image asset path for the size comparison if desired.

  WeeklyPregnancyInfo({
    required this.weekNumber,
    required this.babySizeComparison_en, // Default to English
    required this.babyDevelopmentHighlights_en, // Default to English
    // Add other language parameters to constructor if you add them above
  });

  // Method to get localized size comparison (Example)
  String getLocalizedBabySize(String languageCode) {
    // This is a simple example. For a real app, you'd have proper localized fields
    // or use a localization system for these strings.
    // if (languageCode == 'hi' && babySizeComparison_hi != null) return babySizeComparison_hi!;
    // if (languageCode == 'ar' && babySizeComparison_ar != null) return babySizeComparison_ar!;
    return babySizeComparison_en; // Fallback to English
  }

  // Method to get localized development highlights (Example)
  String getLocalizedDevelopmentHighlights(String languageCode) {
    // if (languageCode == 'hi' && babyDevelopmentHighlights_hi != null) return babyDevelopmentHighlights_hi!;
    // if (languageCode == 'ar' && babyDevelopmentHighlights_ar != null) return babyDevelopmentHighlights_ar!;
    return babyDevelopmentHighlights_en; // Fallback to English
  }
}