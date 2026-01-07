import 'package:flutter/material.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:go_router/go_router.dart';

// Enum to control the dialog's appearance and actions
enum PaywallType { upgrade, cooldown }

// Renamed to CustomPaywallDialog to avoid conflicts and be more descriptive
class CustomPaywallDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final PaywallType type;

  // The onUpgrade callback is removed. The button now handles navigation internally.
  // This was the source of the `No named parameter with the name 'onUpgrade'` error.

  const CustomPaywallDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.type = PaywallType.upgrade,
  });

  /// --- START: NEW DIALOG LOGIC ---
  /// Shows an intelligent dialog when a user hits their scan limit.
  /// It displays a different message based on whether the user is on a free plan.
  static void showScanLimitDialog(BuildContext context, {required bool isFreeUser}) {
    // Get the localizations instance
    final S = AppLocalizations.of(context)!;

    // Determine the title and content based on the user's plan
    String title = S.scanLimitReached; // "Scan Limit Reached"
    Widget content;

    if (isFreeUser) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.freeLimitReachedMessage), // "You've used all your free scans."
          const SizedBox(height: 12),
          // This is the new, helpful text
          Text(
            S.limitsResetMonthly, // "Your free limits will reset on the 1st of next month."
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Text(S.upgradeForMore), // "Upgrade to Premium for more features!"
        ],
      );
    } else {
      // This is the message for a premium user who has somehow hit their limit
      content = Text(S.premiumLimitReachedMessage); // "You have used all your scans for this period. Your limits will reset at the start of your next billing cycle."
    }

    // Now, build the dialog with the dynamic title and content
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.camera_alt_rounded, size: 40),
          title: Text(title, textAlign: TextAlign.center),
          content: content,
          actions: <Widget>[
            TextButton(
              child: Text(S.buttonCancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(S.buttonUpgradeNow),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog first
                // Navigate to your upgrade screen
                context.push(AppRouter.upgradePath);
              },
            ),
          ],
        );
      },
    );
  }
  /// --- END: NEW DIALOG LOGIC ---

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 48),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: Text(message, textAlign: TextAlign.center, style: textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, height: 1.5)),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        if (type == PaywallType.upgrade)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.star, size: 20),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.newPremiumGold,
                foregroundColor: Colors.black,
              ),
              label: Text(S.premiumFeatureDialogUpgradeButton),
              onPressed: () {
                // This button now handles its own navigation, making it self-contained.
                Navigator.of(context).pop();
                GoRouter.of(AppRouter.rootNavigatorKey.currentContext!).push(AppRouter.upgradePath);
              },
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            child: Text(type == PaywallType.upgrade ? S.commonDialogCancelButton : S.commonDialogOkButton),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}