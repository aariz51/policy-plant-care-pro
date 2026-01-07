// lib/core/providers/app_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/services/guide_service.dart';
import 'package:safemama/core/services/iap_service.dart';
import 'package:safemama/core/services/scan_history_service.dart';
import 'package:safemama/core/services/supabase_service.dart';
import 'package:safemama/features/auth/providers/registration_data_provider.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/providers/locale_provider.dart';

// --- Core Services ---
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  print("[AppProviders] CREATING SupabaseService instance.");
  return SupabaseService.instance;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  print("[AppProviders] CREATING ApiService instance.");
  return ApiService();
});

final scanHistoryServiceProvider = Provider<ScanHistoryService>((ref) {
  print("[AppProviders] CREATING ScanHistoryService instance.");
  return ScanHistoryService();
});

final guideServiceProvider = Provider<GuideService>((ref) {
  print("[AppProviders] CREATING GuideService instance.");
  return GuideService();
});

final iapServiceProvider = ChangeNotifierProvider<IapService>((ref) {
  print("[AppProviders] CREATING IapService instance.");
  return IapService(ref);
});

// --- State Notifiers ---
// ✅ CORRECTED: Removed keepAlive (doesn't exist in Riverpod 2.x)
// The provider will stay alive as long as it's watched by a widget
final userProfileNotifierProvider = ChangeNotifierProvider<UserProfileProvider>(
  (ref) {
    print("[AppProviders] CREATING UserProfileProvider instance.");
    // This provider now depends on LocaleProvider and needs the 'ref'
    return UserProfileProvider(ref.watch(localeProvider), ref);
  },
);

final localeProvider = ChangeNotifierProvider<LocaleProvider>((ref) {
  print("[AppProviders] CREATING LocaleProvider instance.");
  return LocaleProvider();
});

// The RegistrationDataProvider is already defined in its own file and imported.

// --- Router ---
final goRouterProvider = Provider<GoRouter>((ref) {
  print("[AppProviders] CREATING GoRouter instance using AppRouter object.");

  // We ONLY need to pass the ref. The router can find other providers itself.
  final appRouter = AppRouter(ref);
  return appRouter.router;
});
