// lib/core/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleProvider with ChangeNotifier {
  final Locale _currentLocale = const Locale('en');
  static const List<Locale> supportedLocalesList = [Locale('en')];
  Locale get currentLocale => _currentLocale;

  LocaleProvider() {
    print("[LocaleProvider] Instance created. Defaulting to English. Current locale: ${_currentLocale.languageCode}.");
  }

  // initialize() for loading from prefs is GONE.

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en') {
      print("[LocaleProvider] Attempted to set unsupported locale: ${locale.languageCode}. Staying with English.");
    }
    // No actual change or notification needed as it's always 'en'.
  }

  void initializeLocale(String? languageCode) { // This was for setting from profile
    print("[LocaleProvider] initializeLocale called. Current locale is fixed to: ${_currentLocale.languageCode}");
    // No change to _currentLocale as it's fixed to 'en'.
  }
  
  String getLanguageDisplayName(Locale displayLocale, BuildContext context) {
    if (displayLocale.languageCode == 'en') return "English";
    return displayLocale.languageCode.toUpperCase();
  }

  @override
  void dispose() {
    print("[LocaleProvider] Disposed");
    super.dispose();
  }
}

final localeNotifierProvider = ChangeNotifierProvider<LocaleProvider>((ref) {
  return LocaleProvider();
});
