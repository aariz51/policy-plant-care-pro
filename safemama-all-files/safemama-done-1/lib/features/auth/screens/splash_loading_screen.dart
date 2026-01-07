// lib/features/auth/screens/splash_loading_screen.dart
// import 'dart:async'; // REMOVED: No longer needed for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Still needed for ConsumerStatefulWidget
// import 'package:supabase_flutter/supabase_flutter.dart'; // REMOVED: No longer listening to auth state here
// import 'package:go_router/go_router.dart'; // Already removed
// import 'package:safemama/navigation/app_router.dart'; // Already removed
// import 'package:safemama/navigation/providers/user_profile_provider.dart'; // Already removed
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/l10n/app_localizations.dart';

class SplashLoadingScreen extends ConsumerStatefulWidget {
  const SplashLoadingScreen({super.key});

  @override
  ConsumerState<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends ConsumerState<SplashLoadingScreen> {
  // StreamSubscription<AuthState>? _authStateSubscription; // REMOVED

  @override
  void initState() {
    super.initState();
    print("[SplashLoadingScreen] initState");

    // The UserProfileProvider should be listening to Supabase's onAuthStateChange
    // globally and updating its own state, which triggers AppRouter.redirect.
    // This screen doesn't need to handle auth state changes directly.

    // _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) { // REMOVED
    //   print("[SplashLoadingScreen onAuthStateChange] Event: ${data.event}");
    // });

    WidgetsBinding.instance.addPostFrameCallback((_) {
        // No explicit navigation here. Let AppRouter handle it.
        print("[SplashLoadingScreen] PostFrameCallback: State should be evaluated by AppRouter.");
    });
  }

  @override
  void dispose() {
    print("[SplashLoadingScreen] dispose");
    // _authStateSubscription?.cancel(); // REMOVED
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("[SplashLoadingScreen] build");

    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final String logoPath = 'assets/logos/logo_safescan_text.png';

    // Just show a loading indicator. The AppRouter.redirect will handle navigation.
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              logoPath,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  S.appTitle,
                  style: textTheme.headlineMedium?.copyWith(color: AppTheme.primaryBlue),
                );
              },
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
                S.loadingLabel,
                style: textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            ),
          ],
        ),
      ),
    );
  }
}