// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/services/supabase_service.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:safemama/core/theme/app_theme.dart';

// Import your NEW central providers file
import 'package:safemama/core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseService.initialize();
  
  runApp(
    ProviderScope( // SINGLE ProviderScope at the root
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("[MyApp build] Building MyApp widget. This should run infrequently after initial load.");
    
    // Watch the GoRouter instance. This is correct.
    final GoRouter router = ref.watch(goRouterProvider); 
    
    // Watch the locale state for MaterialApp updates.
    final Locale currentLocale = ref.watch(localeProvider.select((provider) => provider.currentLocale));

    print("[MyApp build] Returning MaterialApp.router. Locale: ${currentLocale.languageCode}");

    return MediaQuery(
      // This forces the text scaling to a factor of 1.0, ignoring system settings
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SafeMama',
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme, // Uncomment if you have a dark theme
        themeMode: ThemeMode.light,
        locale: currentLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates, // Use generated delegates
        supportedLocales: AppLocalizations.supportedLocales, // Use generated locales
        routerConfig: router,
      ),
    );
  }
}