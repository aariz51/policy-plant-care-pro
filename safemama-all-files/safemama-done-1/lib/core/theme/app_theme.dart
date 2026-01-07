// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- New Color Palette ---
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryPurple = Color(0xFF7B1FA2);
  static const Color lightPurpleBackground = Color(0xFFF3E8FD);
  static const Color lightYellowBackground = Color(0xFFFFF8E1);

  // --- COLORS FOR NEW UI REDESIGN ---
  static const Color newHomeBackground = Color(0xFFFDF8F5);
  static const Color newDrawerHeader = Color(0xFF6F4C9D);
  static const Color newDrawerUserCard = Color(0xFF8A6AB8);
  static const Color newPremiumGold = Color(0xFFEAA944);
  static const Color newScanTeal = Color(0xFF4DB6AC);
  static const Color newCheckGreen = Color(0xFF4CAF50);
  // --- END COLORS FOR NEW UI REDESIGN ---

  static const Color whiteColor = Colors.white;
  static const Color blackColor = Colors.black;
  static const Color scaffoldBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = whiteColor;
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textLight = Color(0xFF808080);
  static const Color inputFillColor = Color(0xFFF1F3F4);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color iconColor = Color(0xFF5F6368);

  static const Color safeGreen = Color(0xFF34A853);
  static const Color warningOrange = Color(0xFFFBBC05);
  static const Color avoidRed = Color(0xFFEA4335);

  // Add these missing colors to your AppTheme
  static const Color dangerRed = Color(0xFFE53E3E);
  static const Color warmingOrange = Color(0xFFFF8C00);

  // <<< ADD THESE TWO LINES HERE >>>
  static const Color lightSafeGreen = Color(0xFF81C784); // Example: A lighter green than safeGreen
  static const Color deepWarningOrange = Color(0xFFFF8A65); // Example: A deeper orange than warningOrange

  static const Color dashboardGreenBg = Color(0xFFE6F4EA);
  // ... rest of your AppTheme class (no other changes needed in this file for this specific issue)
  static const Color dashboardBlueBg = Color(0xFFE8F0FE);
  static const Color dashboardPurpleBg = Color(0xFFF3E8FD);
  static const Color dashboardOrangeBg = Color(0xFFFFF3E0);
  static const Color dashboardTealBg = Color(0xFFE0F2F1);
  static const Color primaryTeal = Color(0xFF00796B);

  static const Color primaryColor = Color(0xFF4A4A4A);
  static const Color accentColor = Color(0xFF5C5C5C);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF808080);

  static const Color safeColor = safeGreen;
  static const Color warningColor = warningOrange;
  static const Color avoidColor = avoidRed;


  static final String? _fontFamily = GoogleFonts.poppins().fontFamily;

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    // MODIFIED: Use the new background color for the home screen
    scaffoldBackgroundColor: newHomeBackground,

    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      onPrimary: whiteColor,
      secondary: primaryPurple,
      onSecondary: whiteColor,
      error: avoidRed,
      onError: whiteColor,
      background: newHomeBackground, // Also update here
      onBackground: textPrimary,
      surface: cardBackground,
      onSurface: textPrimary,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // MODIFIED: Make AppBar transparent for the new Home Screen
      elevation: 0, // MODIFIED: Remove shadow
      iconTheme: const IconThemeData(color: textPrimary),
      actionsIconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      centerTitle: false, // MODIFIED: Align title to the left
    ),

    textTheme: TextTheme(
      headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
      headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
      headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      titleSmall: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
      bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
      bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
      bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.normal, color: textLight),
      labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: whiteColor),
      labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
      labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 10, fontWeight: FontWeight.w500, color: whiteColor),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: whiteColor,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: dividerColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      hintStyle: TextStyle(fontFamily: _fontFamily, color: textLight, fontSize: 14),
      labelStyle: TextStyle(fontFamily: _fontFamily, color: textSecondary, fontSize: 14),
      prefixIconColor: iconColor,
      suffixIconColor: iconColor,
    ),

    cardTheme: CardThemeData(
      elevation: 1.0,
      color: cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: dividerColor,
      labelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      selectedColor: primaryBlue,
      secondarySelectedColor: primaryBlue,
      secondaryLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: whiteColor),
    ),

    iconTheme: const IconThemeData(
      color: iconColor,
      size: 24.0,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: whiteColor,
      selectedItemColor: primaryBlue,
      unselectedItemColor: textSecondary.withOpacity(0.7),
      selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.normal),
      type: BottomNavigationBarType.fixed,
      elevation: 2.0,
    ),

    checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
                return primaryBlue;
            }
            return null;
        }),
        checkColor: MaterialStateProperty.all(whiteColor),
        side: MaterialStateBorderSide.resolveWith(
            (states) => BorderSide(width: 1.5, color: states.contains(MaterialState.selected) ? primaryBlue : textSecondary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
                return primaryBlue;
            }
            return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
                return primaryBlue.withOpacity(0.5);
            }
            return null;
        }),
    ),

    dividerTheme: const DividerThemeData(
      color: dividerColor,
      space: 1,
      thickness: 1,
    ),
  );

  // Dark theme remains unchanged
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF121212),

    colorScheme: ColorScheme.dark(
      primary: primaryBlue,
      onPrimary: whiteColor,
      secondary: primaryPurple,
      onSecondary: whiteColor,
      error: avoidRed,
      onError: whiteColor,
      background: const Color(0xFF121212),
      onBackground: const Color(0xFFEAEAEA),
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFEAEAEA),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0.5,
      iconTheme: const IconThemeData(color: Color(0xFFEAEAEA)),
      actionsIconTheme: const IconThemeData(color: Color(0xFFEAEAEA)),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: const Color(0xFFEAEAEA),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      centerTitle: true,
    ),

    textTheme: TextTheme(
      headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFEAEAEA)),
      headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFEAEAEA)),
      headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFFEAEAEA)),
      titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFEAEAEA)),
      titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFEAEAEA)),
      titleSmall: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFCFCFCF)),
      bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.normal, color: const Color(0xFFEAEAEA)),
      bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.normal, color: const Color(0xFFCFCFCF)),
      bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.normal, color: const Color(0xFFA0A0A0)),
      labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: whiteColor),
      labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFEAEAEA)),
      labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 10, fontWeight: FontWeight.w500, color: whiteColor),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: whiteColor,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.4),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEAEAEA),
        side: BorderSide(color: const Color(0xFF555555), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
      hintStyle: TextStyle(fontFamily: _fontFamily, color: const Color(0xFFA0A0A0), fontSize: 14),
      labelStyle: TextStyle(fontFamily: _fontFamily, color: const Color(0xFFCFCFCF), fontSize: 14),
      prefixIconColor: const Color(0xFFCFCFCF),
      suffixIconColor: const Color(0xFFCFCFCF),
    ),

    cardTheme: CardThemeData(
      elevation: 1.0,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF383838),
      labelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFFCFCFCF)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      selectedColor: primaryBlue,
      secondarySelectedColor: primaryBlue,
      secondaryLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: whiteColor),
    ),

    iconTheme: const IconThemeData(
      color: Color(0xFFCFCFCF),
      size: 24.0,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: primaryBlue,
      unselectedItemColor: const Color(0xFFA0A0A0),
      selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.normal),
      type: BottomNavigationBarType.fixed,
      elevation: 2.0,
    ),

     checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
                return primaryBlue;
            }
            return const Color(0xFF4A4A4A);
        }),
        checkColor: MaterialStateProperty.all(whiteColor),
        side: MaterialStateBorderSide.resolveWith(
            (states) => BorderSide(width: 1.5, color: states.contains(MaterialState.selected) ? primaryBlue : const Color(0xFFA0A0A0)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
                return primaryBlue;
            }
            return const Color(0xFFBDBDBD);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
                return primaryBlue.withOpacity(0.5);
            }
            return const Color(0xFF505050);
        }),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF484848),
      space: 1,
      thickness: 1,
    ),
  );
}
