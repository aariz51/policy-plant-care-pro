// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:safemama/l10n/app_localizations.dart';

class SafeMamaApp extends ConsumerWidget {
  const SafeMamaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- THIS IS THE CORRECT WAY ---
    // 1. Watch the router provider to get the GoRouter instance.
    final goRouter = ref.watch(goRouterProvider);
    
    // 2. Watch the locale provider to get the current locale for the app.
    final localeState = ref.watch(localeProvider);
    // --- END OF CORRECTION ---

    print("[MyApp build] Returning MaterialApp.router. Locale: ${localeState.currentLocale.languageCode}");

    return MaterialApp.router(
      title: 'SafeMama',
      theme: AppTheme.lightTheme,
      // Use the router instance directly from the provider
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // For English-only
      ],
      // Set the locale from our provider
      locale: localeState.currentLocale,
    );
  }
}