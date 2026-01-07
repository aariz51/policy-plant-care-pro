// lib/core/widgets/premium_upsell_dialog.dart
import 'package:flutter/material.dart';
// Potentially import your AppTheme if you want to use consistent styling for buttons, etc.
// import 'package:safemama/core/theme/app_theme.dart'; 
// Potentially import AppLocalizations if you want to localize text here
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PremiumUpsellDialog extends StatelessWidget {
  final String title;
  final String message;
  // You can add more parameters, like a list of premium features to display

  const PremiumUpsellDialog({
    super.key, // Use super.key for modern Flutter
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // final S = AppLocalizations.of(context); // Uncomment if you want to use localized strings
    // final textTheme = Theme.of(context).textTheme; // For consistent text styling

    return AlertDialog(
      title: Text(title), // Use Text(S?.dialogTitlePremiumUpsell ?? title) for localization
      content: SingleChildScrollView( // In case message is long
        child: ListBody(
          children: <Widget>[
            Text(message), // Use Text(S?.dialogMessagePremiumUpsell ?? message) for localization
            const SizedBox(height: 16),
            Text(
              // S?.premiumFeaturesInclude ?? 'Premium Features Include:', // Example localization
              'Premium Features Include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // These can also be localized or dynamically generated
            const Text('- Unlimited Scans'),
            const Text('- Detailed AI Analysis & Recommendations'),
            const Text('- Advanced Scan History'),
            const Text('- Personalized Pregnancy Guide'),
            // Add more key premium features here
            const Text('- Exclusive Content & Tips'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Maybe Later'), // Use Text(S?.buttonMaybeLater ?? 'Maybe Later')
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton( // Make this more prominent
          child: Text('Upgrade to Premium'), // Use Text(S?.buttonUpgradeToPremium ?? 'Upgrade to Premium')
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            // TODO: Navigate to your subscription/payment screen (to be built)
            print('User clicked "Upgrade to Premium". Navigate to payment screen requested.');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment screen not yet implemented.')), // Use S?.paymentScreenNotImplemented ?? '...'
            );
            // Example navigation if you had a route:
            // context.push(AppRouter.subscriptionPath); 
          },
        ),
      ],
    );
  }
}