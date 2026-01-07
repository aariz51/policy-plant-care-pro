// lib/features/home/widgets/membership_status_chip.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/models/subscription_plan.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:intl/intl.dart';

/// Widget to display the user's current membership plan
/// Shows prominently in the home screen header
class MembershipStatusChip extends ConsumerWidget {
  const MembershipStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final userProfile = userProfileState.userProfile;

    if (userProfile == null) {
      return const SizedBox.shrink();
    }

    final plan = SubscriptionPlan.fromTier(userProfile.membershipTier);
    final bool isFree = plan.id == 'free';

    // Format expiry date if available
    String? expiryText;
    if (!isFree && userProfile.membershipExpiry != null) {
      final expiry = userProfile.membershipExpiry!;
      final now = DateTime.now();
      
      if (expiry.isBefore(now)) {
        expiryText = 'Expired';
      } else {
        final daysUntilExpiry = expiry.difference(now).inDays;
        if (daysUntilExpiry == 0) {
          expiryText = 'Expires today';
        } else if (daysUntilExpiry == 1) {
          expiryText = 'Expires tomorrow';
        } else if (daysUntilExpiry < 7) {
          expiryText = 'Expires in $daysUntilExpiry days';
        } else {
          expiryText = 'Renews ${DateFormat('MMM d').format(expiry)}';
        }
      }
    }

    return GestureDetector(
      onTap: () {
        if (isFree) {
          context.push(AppRouter.upgradePath);
        } else {
          // Navigate to profile/subscription management
          context.push(AppRouter.profilePath);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isFree 
              ? LinearGradient(
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFFFD700), // Gold
                    Color(0xFFFFA500), // Orange-gold
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isFree ? Colors.grey : AppTheme.newPremiumGold).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFree ? Icons.account_circle : Icons.workspace_premium,
              size: 16,
              color: isFree ? Colors.grey.shade700 : Colors.white,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isFree ? Colors.grey.shade800 : Colors.white,
                  ),
                ),
                if (expiryText != null)
                  Text(
                    expiryText,
                    style: TextStyle(
                      fontSize: 9,
                      color: isFree ? Colors.grey.shade700 : Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
            if (isFree) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: Colors.grey.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

