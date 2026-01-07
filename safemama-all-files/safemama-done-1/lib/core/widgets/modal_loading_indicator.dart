// lib/core/widgets/modal_loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:safemama/core/constants/app_colors.dart';
// No direct need for AppLocalizations here unless you make loadingText an S.key

class ModalLoadingIndicator extends StatelessWidget {
  final String loadingText;

  const ModalLoadingIndicator({
    super.key,
    required this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from dismissing during critical load
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.0,
                    spreadRadius: 1.0)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logos/logo_safescan_text.png', // Your app logo
                  width: MediaQuery.of(context).size.width * 0.25,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3.0,
                ),
                const SizedBox(height: 20),
                Text(
                  loadingText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper to show (ensure context is from where dialog should be shown)
void showAppLoadingIndicator(BuildContext context, String text) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return ModalLoadingIndicator(loadingText: text);
    },
  );
}

// Helper to hide
void hideAppLoadingIndicator(BuildContext context) {
  // Check if a dialog is open before trying to pop.
  // Navigator.of(context) refers to the closest Navigator.
  // If the dialog was shown on the root navigator, use rootNavigator: true.
  // For simplicity, this will pop the top-most dialog.
  if (Navigator.of(context, rootNavigator: true).canPop()) {
     Navigator.of(context, rootNavigator: true).pop();
  }
}