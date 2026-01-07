import 'package:flutter/material.dart';

class PremiumFeatureWrapper extends StatelessWidget {
  final Widget child;
  final bool isPremiumUser;
  final VoidCallback onTapWhenFree;
  final bool showLockIcon;
  final String? featureName;
  final int? currentCount;
  final int? limit;
  final VoidCallback? onUsageIncrement;

  const PremiumFeatureWrapper({
    Key? key,
    required this.child,
    required this.isPremiumUser,
    required this.onTapWhenFree,
    this.showLockIcon = false,
    this.featureName,
    this.currentCount,
    this.limit,
    this.onUsageIncrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isPremiumUser) {
      return child;
    }

    return GestureDetector(
      onTap: onTapWhenFree,
      child: Stack(
        children: [
          Opacity(
            opacity: 0.5,
            child: child,
          ),
          if (showLockIcon)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.lock,
                color: Colors.amber,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
