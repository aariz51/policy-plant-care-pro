// ================
// File: lib\features\home\screens\home_screen_shell.dart
// ================

// lib/features/home/screens/home_screen_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/core/widgets/app_drawer.dart';
import 'package:safemama/core/constants/app_constants.dart';

class HomeScreenShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeScreenShell({required this.child, super.key});

  @override
  ConsumerState<HomeScreenShell> createState() => _HomeScreenShellState();
}

class _HomeScreenShellState extends ConsumerState<HomeScreenShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double _bottomNavIconSize = 26.0;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRouter.homePath)) return 0;
    // Document Analysis is now index 1
    if (location.startsWith(AppRouter.documentAnalysisPath)) return 1;
    if (location.startsWith(AppRouter.askExpertPath)) return 2;
    // Pregnancy Test Checker is now index 3
    if (location.startsWith(AppRouter.pregnancyTestCheckerPath)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (!mounted) return;
    
    final String currentLocation = GoRouterState.of(context).uri.toString();
    final userProfile = ref.read(userProfileNotifierProvider).userProfile;

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loading user data...")));
      return;
    }
    
    final bool isPremium = userProfile.isPremiumUser;

    switch (index) {
      case 0: // Home
        if (!currentLocation.startsWith(AppRouter.homePath)) context.go(AppRouter.homePath);
        break;
      case 1: // Document Analysis (Premium)
        if (isPremium) {
          context.push(AppRouter.documentAnalysisPath);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => const CustomPaywallDialog(
              title: "Premium Feature",
              message: "Document Analysis is a premium feature. Upgrade to analyze your medical documents with AI!",
              icon: Icons.document_scanner,
              iconColor: AppTheme.accentColor,
              type: PaywallType.upgrade,
            ),
          );
        }
        break;
      case 2: // Ask Expert
        if (isPremium) {
          if (!currentLocation.startsWith(AppRouter.askExpertPath)) context.go(AppRouter.askExpertPath);
        } else {
          if (userProfile.askExpertCount < AppConstants.freeAskExpertLimit) {
            context.go(AppRouter.askExpertPath);
          } else {
            showDialog(
              context: context,
              builder: (ctx) => CustomPaywallDialog(
                title: "Free Trial Used",
                message: "You've used all ${AppConstants.freeAskExpertLimit} of your free questions. Upgrade to Premium to ask more!",
                icon: Icons.chat_bubble_outline,
                iconColor: AppTheme.accentColor,
                type: PaywallType.upgrade,
              ),
            );
          }
        }
        break;
      case 3: // Pregnancy Test Checker (Premium)
        if (isPremium) {
          context.push(AppRouter.pregnancyTestCheckerPath);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => const CustomPaywallDialog(
              title: "Premium Feature",
              message: "Pregnancy Test Checker is a premium feature. Get AI-powered pregnancy likelihood assessment!",
              icon: Icons.science_outlined,
              iconColor: Colors.pinkAccent,
              type: PaywallType.upgrade,
            ),
          );
        }
        break;
      default:
        return;
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;
    int currentIndex = _calculateSelectedIndex(context);
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final bool isPremium = userProfileState.userProfile?.isPremiumUser ?? false;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }

        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }

        final int currentTabIndex = _calculateSelectedIndex(context);
        if (currentTabIndex != 0) {
          _onItemTapped(0, context);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            // 0: Home
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: _bottomNavIconSize),
              activeIcon: const Icon(Icons.home, size: _bottomNavIconSize),
              label: l10n.bottomNavHome,
            ),
            // 1: Document Analysis (was History)
            BottomNavigationBarItem(
              icon: Icon(
                isPremium ? Icons.document_scanner_outlined : Icons.lock_outline,
                size: _bottomNavIconSize,
              ),
              activeIcon: const Icon(Icons.document_scanner, size: _bottomNavIconSize),
              label: 'Docs',
            ),
            // 2: Ask Expert
            BottomNavigationBarItem(
              icon: Icon(
                isPremium ? Icons.chat_bubble_outline : Icons.lock_outline,
                size: _bottomNavIconSize,
              ),
              activeIcon: const Icon(Icons.chat_bubble, size: _bottomNavIconSize),
              label: l10n.bottomNavAskExpert,
            ),
            // 3: Pregnancy Test Checker (was Guides)
            BottomNavigationBarItem(
              icon: Icon(
                isPremium ? Icons.science_outlined : Icons.lock_outline,
                size: _bottomNavIconSize,
                color: isPremium ? null : AppTheme.textSecondary,
              ),
              activeIcon: const Icon(Icons.science, size: _bottomNavIconSize, color: Colors.pinkAccent),
              label: 'Test',
            ),
          ],
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: bottomNavTheme.unselectedItemColor ?? AppTheme.textSecondary,
          backgroundColor: bottomNavTheme.backgroundColor,
          elevation: bottomNavTheme.elevation ?? 8.0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        ),
      ),
    );
  }
}
