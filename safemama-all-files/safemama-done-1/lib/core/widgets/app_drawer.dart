// lib/core/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safemama/core/models/subscription_plan.dart';
import 'package:intl/intl.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  // Helper methods remain unchanged
  void _navigateTo(BuildContext context, String path, {Object? extra}) {
    Navigator.of(context).pop();
    final routerContext = AppRouter.rootNavigatorKey.currentContext;
    if (routerContext == null) return;
    if (extra != null) {
      GoRouter.of(routerContext).push(path, extra: extra);
    } else {
      GoRouter.of(routerContext).push(path);
    }
  }

  void _handlePremiumFeatureNavigation(BuildContext drawerContext, WidgetRef ref,
      String targetPath, String featureNameForDialog) {
    Navigator.of(drawerContext).pop();
    final rootContext = AppRouter.rootNavigatorKey.currentContext!;
    final userProvider = ref.read(userProfileNotifierProvider);
    final S = AppLocalizations.of(rootContext)!;
    final userProfile = userProvider.userProfile;
    if (userProfile == null) {
      ScaffoldMessenger.of(rootContext)
          .showSnackBar(SnackBar(content: Text(S.loginToScan)));
      return;
    }
    // Use isPremiumUser getter which checks both membership_tier and isPremium/is_pro_member flags
    if (userProfile.isPremiumUser) {
      GoRouter.of(rootContext).push(targetPath);
      return;
    }
    if (targetPath == AppRouter.askExpertPath) {
      if (userProfile.askExpertCount < AppConstants.freeAskExpertLimit) {
        GoRouter.of(rootContext).push(targetPath);
      } else {
        showDialog(
            context: rootContext,
            builder: (_) => const CustomPaywallDialog(
                  title: "Free Trial Used",
                  message:
                      "You've used all 3 of your free questions. Upgrade to Premium to ask more!",
                  icon: Icons.chat_bubble_outline,
                  iconColor: AppTheme.accentColor,
                  type: PaywallType.upgrade,
                ));
      }
      return;
    }
    showDialog(
        context: rootContext,
        builder: (_) => CustomPaywallDialog(
              title: S.premiumFeatureDialogTitle(featureNameForDialog),
              message: S.premiumFeatureDialogMessage(featureNameForDialog),
              icon: Icons.workspace_premium_outlined,
              iconColor: AppTheme.newPremiumGold,
              type: PaywallType.upgrade,
            ));
  }

  void _handleScanProductNavigation(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    final rootContext = AppRouter.rootNavigatorKey.currentContext!;
    GoRouter.of(rootContext).push(AppRouter.preScanGuidePath);
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // ignore: avoid_print
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final userProfile = userProfileState.userProfile;
    // Use isPremiumUser getter which checks both membership_tier and isPremium/is_pro_member flags
    final bool isPremium = userProfile?.isPremiumUser ?? false;
    final userName = userProfile?.fullName?.isNotEmpty == true
        ? userProfile!.fullName!
        : S.mamaFallbackName;
    final userEmail = userProfile?.email ?? "user@example.com";
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: Container(
        color: AppTheme.newDrawerHeader,
        child: Column(
          children: [
            // Header Section remains the same
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const _BLogoIcon(),
                            const SizedBox(width: 8),
                            Text(
                              'SafeMama',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.newDrawerUserCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            backgroundImage:
                                userProfileState.profileImageUrl.isNotEmpty
                                    ? NetworkImage(
                                        userProfileState.profileImageUrl)
                                    : null,
                            child: userProfileState.profileImageUrl.isEmpty
                                ? Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : "S",
                                    style: textTheme.headlineSmall?.copyWith(
                                        color: AppTheme.newDrawerHeader),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  userEmail,
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.whiteColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // --- Main Features List ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                        child: Column(
                          children: [
                            _DrawerItem(
                                icon: const Icon(Icons.qr_code_scanner,
                                    color: AppTheme.primaryPurple),
                                title: S.scanProduct,
                                onTap: () =>
                                    _handleScanProductNavigation(context, ref)),
                            _DrawerItem(
                                icon: const Icon(Icons.search,
                                    color: Colors.blueAccent),
                                title: S.manualSearchButtonLabel,
                                onTap: () =>
                                    _navigateTo(context, AppRouter.searchPath)),
                            _DrawerItem(
                                icon: const Icon(Icons.history,
                                    color: Colors.orange),
                                title: S.scanHistoryButtonLabel,
                                onTap: () =>
                                    _navigateTo(context, AppRouter.historyPath)),
                            _DrawerItem(
                                icon: const Icon(Icons.menu_book,
                                    color: Colors.green),
                                title: S.bottomNavGuide,
                                onTap: () => _navigateTo(
                                    context, AppRouter.guideListPath)),
                            _DrawerItem(
                                icon: const Icon(Icons.pregnant_woman,
                                    color: AppTheme.primaryPurple),
                                title: 'Free Tools',
                                onTap: () => _navigateTo(
                                    context, AppRouter.pregnancyToolsHubPath)),
                            _DrawerItem(
                                icon: const Icon(Icons.auto_awesome_outlined,
                                    color: AppTheme.newPremiumGold),
                                title: S.drawerAiPersonalizedGuide,
                                isPremium: isPremium,
                                isPremiumFeature: true,
                                onTap: () => _handlePremiumFeatureNavigation(
                                    context,
                                    ref,
                                    AppRouter.aiPersonalizedGuidePath,
                                    S.drawerAiPersonalizedGuide)),
                            _DrawerItem(
                                icon: const Icon(Icons.chat_bubble_outline,
                                    color: AppTheme.accentColor),
                                title: S.homeDashboardAskExpert,
                                isPremium: isPremium,
                                isPremiumFeature: true,
                                onTap: () => _handlePremiumFeatureNavigation(
                                    context,
                                    ref,
                                    AppRouter.askExpertPath,
                                    S.homeDashboardAskExpert)),
                          ],
                        ),
                      ),
                      
                      // --- Bottom-anchored section ---
                      if (!isPremium)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _navigateTo(context, AppRouter.upgradePath),
                            icon: const Icon(Icons.star,
                                color: Colors.black, size: 20),
                            label: Text(S.buttonUpgradeToPremium,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.newPremiumGold,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(double.infinity, 48)),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: _PremiumStatusIndicator(),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          children: [
                            Text("Follow Us",
                                style: textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SocialIconButton(
                                    icon: FontAwesomeIcons.instagram,
                                    color: const Color(0xffE4405F),
                                    onPressed: () => _launchURL(
                                        'https://www.instagram.com/safemama_app?igsh=MnFlaXRuM2RrcXlt&utm_source=qr')),
                                const SizedBox(width: 16),
                                _SocialIconButton(
                                    icon: FontAwesomeIcons.xTwitter,
                                    color: const Color(0xff000000),
                                    onPressed: () => _launchURL(
                                        'https://x.com/rasheedaariz?s=21')),
                              ],
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              "Contact Us",
                              style: textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ContactItem(
                              icon: FontAwesomeIcons.whatsapp,
                              iconColor: const Color(0xff25D366),
                              text: "+91 7300838110",
                              onTap: () => _launchURL('https://wa.me/917300838110'),
                            ),
                            _ContactItem(
                              icon: FontAwesomeIcons.solidEnvelope,
                              iconColor: AppTheme.textSecondary,
                              text: "contact@safemama.co",
                              onTap: () {
                                final Uri emailLaunchUri = Uri(
                                  scheme: 'mailto',
                                  path: 'support@safemama.co',
                                  query: 'subject=Support Request - SafeMama App',
                                );
                                _launchURL(emailLaunchUri.toString());
                              },
                            ),
                          ],
                        ),
                      ),
                      _DrawerItem(
                        icon: const Icon(Icons.logout,
                            color: AppTheme.textSecondary),
                        title: S.signOutButton,
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(userProfileNotifierProvider.notifier)
                              .signOut();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// All helper widgets remain the same

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            FaIcon(icon, color: iconColor, size: 20),
            const SizedBox(width: 16),
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _SocialIconButton(
      {required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FaIcon(icon, size: 24, color: color),
      onPressed: onPressed,
      padding: const EdgeInsets.all(10),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PremiumStatusIndicator extends ConsumerWidget {
  const _PremiumStatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final userProfile = userProfileState.userProfile;

    if (userProfile == null) {
      return const SizedBox.shrink();
    }

    final plan = SubscriptionPlan.fromTier(userProfile.membershipTier);
    
    // Format expiry/renewal date
    String expiryText = '';
    if (userProfile.membershipExpiry != null) {
      final expiry = userProfile.membershipExpiry!;
      final now = DateTime.now();
      
      if (expiry.isBefore(now)) {
        expiryText = 'Expired ${DateFormat('MMM d, y').format(expiry)}';
      } else {
        expiryText = 'Renews ${DateFormat('MMM d, y').format(expiry)}';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer
          context.push('/upgrade'); // Navigate to upgrade screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700), // Gold
                Color(0xFFFFA500), // Orange-gold
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.newPremiumGold.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    plan.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ],
              ),
              if (expiryText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  expiryText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Tap to manage subscription',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool isPremium;
  final bool isPremiumFeature;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isPremium = false,
    this.isPremiumFeature = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isLocked = isPremiumFeature && !isPremium;

    return ListTile(
      visualDensity: VisualDensity.compact,
      onTap: onTap,
      leading: icon,
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: isLocked ? AppTheme.textLight : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isPremiumFeature
          ? (isPremium
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.newPremiumGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppTheme.newPremiumGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                )
              : const Icon(Icons.lock_outline,
                  color: AppTheme.textLight, size: 20))
          : const Icon(Icons.chevron_right, color: AppTheme.iconColor, size: 20),
    );
  }
}

class _BLogoIcon extends StatelessWidget {
  const _BLogoIcon();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(24, 24), painter: _BLogoPainter());
}

class _BLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    Path path = Path();
    path.moveTo(size.width * 0.4, 0);
    path.cubicTo(size.width * 0.8, 0, size.width, size.height * 0.2,
        size.width, size.height * 0.4);
    path.cubicTo(
        size.width, size.height * 0.7, size.width * 0.5, size.height, 0, size.height);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
