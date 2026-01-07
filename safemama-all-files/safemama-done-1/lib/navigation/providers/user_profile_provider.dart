// lib/navigation/providers/user_profile_provider.dart
import 'dart:async';
import 'dart:io'; // For File type
import 'package:flutter/material.dart'; // Includes ChangeNotifier from foundation
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod is used for provider definition
import 'package:image_picker/image_picker.dart'; // For XFile
import 'package:safemama/core/providers/locale_provider.dart'; // For LocaleProvider CLASS (used in constructor)
import 'package:safemama/core/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Ensure User is available

// Added imports for TrimesterOption and DietaryPreferenceOption for isPersonalized getter & new logic
import 'package:safemama/features/auth/screens/personalize_trimester_screen.dart'; // For TrimesterOption
import 'package:safemama/features/auth/screens/personalize_diet_screen.dart';       // For DietaryPreferenceOption

// Import for global providers (like registrationDataProvider)
import 'package:safemama/core/providers/app_providers.dart'; // ADDED

// <<< ADD THIS IMPORT as per instruction for Error 2
import 'package:safemama/features/auth/providers/registration_data_provider.dart';

// CORRECTED Import for UserGoalOption
import 'package:safemama/features/auth/screens/personalize_goal_screen.dart';      // For UserGoalOption
// Import for DeviceInfoService (assuming path, adjust if different)
import 'package:safemama/core/services/device_info_service.dart';
// Import for SupabaseService
import 'package:safemama/core/services/supabase_service.dart'; // For SupabaseService

// Ensure these imports are present at the top of the file:
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // ADDED for date formatting in updateUserDueDate

// ---- ADDED IMPORTS FOR PREGNANCY DETAILS ----
import 'package:safemama/core/models/user_pregnancy_details.dart';
import 'package:safemama/core/services/pregnancy_details_service.dart';
// ---- END ADDED IMPORTS ----

// --- IMPORT ADDED AS PER INSTRUCTION ---
import 'package:safemama/core/constants/app_constants.dart'; // Make sure this is imported

// Added as per new instructions
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:math' as math;

// ---- ADDED FOR REVENUECAT INTEGRATION ----
import 'package:safemama/core/services/revenuecat_service.dart';
// ---- END REVENUECAT IMPORT ----

// In user_profile_provider.dart (at the top level)
enum AuthNavigationAction { none, createNewPassword }
final authNavigationActionProvider = StateProvider<AuthNavigationAction>((ref) => AuthNavigationAction.none);

enum DietaryPreference { vegetarian, nonVeg, vegan }

extension DietaryPreferenceExtensions on DietaryPreference {
String toSupabaseString() {
switch (this) {
case DietaryPreference.vegetarian:
return 'vegetarian';
case DietaryPreference.nonVeg:
return 'non_veg';
case DietaryPreference.vegan:
return 'vegan';
}
}
}

class UserProfileProvider with ChangeNotifier {
// CORRECTED: Fields as per Step 1
final SupabaseClient _supabaseClient;
final LocaleProvider _localeProvider; // Instance passed via constructor
final Ref _ref; // Ref passed via constructor, used to read other providers

StreamSubscription<AuthState>? _authStateSubscription;
AuthChangeEvent? lastAuthEvent; // ADDED THIS PROPERTY

bool _isDisposed = false;
static bool _isGoogleOAuthInProgressStatic = false; // Keep this private

// Public static getter - ADDED AS PER INSTRUCTION
static bool get isGoogleOAuthInProgressGlobal => _isGoogleOAuthInProgressStatic;

// Define your backend base URL, ideally from a config or constant
final String _yourBackendBaseUrl = 'http://192.168.29.229:3001'; // Or get from config
static const int FREE_SCAN_LIMIT = 4; // Define your free scan limit constant

// ---- ADDED FOR PREGNANCY DETAILS ----
final PregnancyDetailsService _pregnancyDetailsService = PregnancyDetailsService();
UserPregnancyDetails? _userPregnancyDetails;
// ---- END ADDED FOR PREGNANCY DETAILS ----

static void startGoogleOAuthProcess() {
print("[UserProfileProvider Static] startGoogleOAuthProcess called. Setting _isGoogleOAuthInProgressStatic = true.");
_isGoogleOAuthInProgressStatic = true;
}

static void endGoogleOAuthProcess() {
print("[UserProfileProvider Static] endGoogleOAuthProcess called. Setting _isGoogleOAuthInProgressStatic = false.");
_isGoogleOAuthInProgressStatic = false;
}

// State fields
String? _userId;
String _fullName = 'Mama';
String? _email;
List<String> _knownAllergies = [];
String _customAllergiesText = '';
String _profileImageUrl = '';
String? _languagePreference;
int? _memberSinceYear;
String? _mobileNumber;
String? _countryCode;
bool _isPhoneVerified = false;
bool _emailNotificationsEnabled = false;
bool _dataSharingEnabled = false;

// Flags
bool _isLoading = true;
bool _isSaving = false;
bool __isUserProfileLoaded = false;
bool _hasInitialAuthCheckCompleted = false;

UserProfile? _userProfileModel;

// CONSTRUCTOR
UserProfileProvider(this._localeProvider, this._ref)
: _supabaseClient = SupabaseService.instance.client
{
print("[UserProfileProvider] Instance created. Initializing auth state listener. Will use ref for registrationData and passed localeProvider.");

_authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) async {
  lastAuthEvent = data.event; // STORE THE LAST EVENT
  final AuthChangeEvent event = data.event;
  final Session? session = data.session;
  User? authUser = session?.user;

  // This old block is removed because the new GoRouter redirect logic will handle this event.
  // if (event == AuthChangeEvent.passwordRecovery) {
  //   print("[UserProfileProvider] Password recovery deep link detected.");
  //   _ref.read(authNavigationActionProvider.notifier).state = AuthNavigationAction.createNewPassword;
  // }

  // General log for any event
  print("[UserProfileProvider onAuthStateChange] Received Event: $event, User: ${authUser?.id}, StaticGoogleOAuthInProgress: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");

  if (event == AuthChangeEvent.signedIn && authUser != null) {
    bool wasGoogleOAuth = _isGoogleOAuthInProgressStatic;
    // Enhanced log for signedIn, including wasGoogleOAuth
    print("[UserProfileProvider onAuthStateChange - signedIn] User ${authUser.id} signed in. WasGoogleOAuth: $wasGoogleOAuth. Processing auth event. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");

    if (wasGoogleOAuth) {
        // This log is good as is for the entry point if it was Google OAuth.
        print("[UPP GOAuth FlashLog] AuthChangeEvent.signedIn: User ${authUser.id} signed in. wasGoogleOAuth=true. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    }

    print("[UPP GOAuth FlashLog] Before setUserIdAndLoadProfile for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
    setUserIdAndLoadProfile(authUser).then((_) async {
      if (_isDisposed) return;
      print("[UPP GOAuth FlashLog] Inside .then of setUserIdAndLoadProfile for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");

      // --- ADD THIS NEW BLOCK OF CODE ---
      // After loading the profile, check if the device ID is missing.
      if (_userProfileModel != null && (_userProfileModel!.deviceId == null || _userProfileModel!.deviceId!.isEmpty)) {
        print("[UserProfileProvider] Profile is missing a device ID. Fetching and saving it now.");
        try {
          final deviceId = await DeviceInfoService.getDeviceId();
          if (deviceId != null && deviceId.isNotEmpty) {
            // If we got a device ID, update the profile in Supabase.
            await _supabaseClient
                .from('profiles')
                .update({'device_id': deviceId})
                .eq('id', authUser.id);
            
            print("[UserProfileProvider] Successfully saved device ID ($deviceId) to Supabase.");
    
            // Reload the profile locally to have the most up-to-date data.
            await loadUserProfile();
          }
        } catch (e) {
          print("[UserProfileProvider] ERROR saving device ID: $e");
        }
      }
      // --- END OF NEW BLOCK ---

      // DISABLED: This block causes infinite loops for existing users
      // The registration data provider only has "none" values for existing users
      // which causes them to overwrite their profile repeatedly
      // Check if this is a new user who just signed up via a social provider
      // Only apply personalization if registration data has actual non-none values
      final registrationData = _ref.read(registrationDataProvider.notifier).getFullSignupMetaDataForSupabaseTrigger();
      final bool hasValidPersonalizationData = registrationData['selected_trimester'] != null && 
        registrationData['selected_trimester'] != TrimesterOption.none.name &&
        registrationData['dietary_preference'] != null &&
        registrationData['dietary_preference'] != DietaryPreferenceOption.none.name;
      
      final bool isNewSocialUser = _userProfileModel != null && !this.isPersonalized && hasValidPersonalizationData;
      
if (isNewSocialUser) {
  print("[UserProfileProvider] New social user detected with valid personalization data. Applying personalization data.");
  
  // Create the data map to update in Supabase
  final Map<String, dynamic> updateData = {
    'selected_trimx': registrationData['selected_trimester'],
    'dietary_preference': registrationData['dietary_preference'],
    'known_allergies': registrationData['known_allergies'],
    'custom_allergies': registrationData['custom_allergies'],
    'primary_goal': registrationData['primary_goal'],
  };

  // Only add the name from the form IF the profile's name is still empty.
  if (_userProfileModel!.fullName == null || _userProfileModel!.fullName!.isEmpty) {
    updateData['full_name'] = registrationData['full_name'];
    print("[UserProfileProvider] Profile name is empty, applying name from registration form.");
  } else {
    print("[UserProfileProvider] Profile name already exists ('${_userProfileModel!.fullName}'), NOT overwriting with form data.");
  }

  try {
    // Update the user's profile in the database
    await _supabaseClient.from('profiles').update(updateData).eq('id', authUser.id);
    print("[UserProfileProvider] Successfully updated new social user with personalization data.");

    // Reload the profile to get the final, correct data
    await loadUserProfile(); 
  } catch (e) {
    print("[UserProfileProvider] ERROR updating new social user: $e");
  }
} else {
  print("[UserProfileProvider] Skipping personalization update. isPersonalized=$isPersonalized, hasValidData=$hasValidPersonalizationData");
}

      try {
        if (wasGoogleOAuth) {
          print("[UPP GOAuth FlashLog] Google OAuth specific block entered for ${authUser.id}. State before processing: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");

          final registrationData = _ref.read(registrationDataProvider);
          final currentProfileBeforeGoogleSpecificUpdates = _userProfileModel;

          print("[UPP GOAuth FlashLog] About to check needsPersonalizationUpdate for ${authUser.id}. currentProfileSelectedTrimester=${currentProfileBeforeGoogleSpecificUpdates?.selectedTrimester}, regDataTrimester=${registrationData.trimester.name}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
          final bool needsPersonalizationUpdate = currentProfileBeforeGoogleSpecificUpdates == null ||
                                                currentProfileBeforeGoogleSpecificUpdates.selectedTrimester == null ||
                                                currentProfileBeforeGoogleSpecificUpdates.selectedTrimester == TrimesterOption.none.toSupabaseString() ||
                                                currentProfileBeforeGoogleSpecificUpdates.selectedTrimester!.isEmpty;
          print("[UserProfileProvider onAuthStateChange - signedIn] Google OAuth: needsPersonalizationUpdate=$needsPersonalizationUpdate, regDataTrimester=${registrationData.trimester.name}"); // Keep specific log

          if (needsPersonalizationUpdate && registrationData.trimester != TrimesterOption.none) {
            print("[UserProfileProvider onAuthStateChange - signedIn] Google OAuth: Applying onboarding data for ${authUser.id}.");
            Map<String, dynamic> regProviderMeta = _ref.read(registrationDataProvider.notifier).getFullSignupMetaDataForSupabaseTrigger();
            print("[UserProfileProvider onAuthStateChange - signedIn] Google OAuth: Data from getFullSignupMetaDataForSupabaseTrigger: $regProviderMeta");

            Map<String, dynamic> finalUpdateData = {
              'selected_trimx': regProviderMeta['selected_trimester'],
              'dietary_preference': regProviderMeta['dietary_preference'],
              'known_allergies': regProviderMeta['known_allergies'],
              'custom_allergies': regProviderMeta['custom_allergies'],
              'primary_goal': regProviderMeta['primary_goal'],
            };
            final String? googleFullName = authUser.userMetadata?['full_name'] as String? ?? authUser.userMetadata?['name'] as String?;
            if (googleFullName != null && googleFullName.isNotEmpty) {
                finalUpdateData['full_name'] = googleFullName;
            } else if (regProviderMeta['full_name'] != null && (regProviderMeta['full_name'] as String).isNotEmpty) {
                finalUpdateData['full_name'] = regProviderMeta['full_name'];
            }
            if (regProviderMeta.containsKey('country_code') && regProviderMeta['country_code'] != null) {
                finalUpdateData['country_code'] = regProviderMeta['country_code'];
            }
            finalUpdateData.removeWhere((key, value) => value == null);

            print("[UPP GOAuth FlashLog] Before Supabase profile UPDATE with personalization for ${authUser.id}. Data: $finalUpdateData. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");

            if (finalUpdateData.isNotEmpty) {
              try {
                await _supabaseClient.from('profiles').update(finalUpdateData).eq('id', authUser.id);
                print("[UPP GOAuth FlashLog] After Supabase profile UPDATE with personalization SUCCEEDED for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
              } catch (e,s) {
                 print("[UserProfileProvider onAuthStateChange - signedIn] Google OAuth: CRITICAL ERROR updating profile with personalization: $e\n$s");
                 print("[UPP GOAuth FlashLog] CRITICAL ERROR Supabase profile UPDATE with personalization for ${authUser.id}. Error: $e. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
              }
            }
            print("[UPP GOAuth FlashLog] Before loadUserProfile (post-personalization) for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
            await loadUserProfile();
            if(_isDisposed) return;
            // This log is already good and includes key states.
            print("[UPP GOAuth FlashLog] After loadUserProfile (post-personalization) for ${authUser.id}. isPersonalized: $isPersonalized, scan_count: ${_userProfileModel?.scanCount}, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, StaticFlag: $_isGoogleOAuthInProgressStatic");
          }

          print("[UPP GOAuth FlashLog] Before getDeviceId for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
          String? deviceId;
          try {
            deviceId = await DeviceInfoService.getDeviceId();
             print("[UPP GOAuth FlashLog] After getDeviceId for ${authUser.id}. DeviceId: $deviceId. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
          } catch(e){
            print("[UserProfileProvider Google OAuth] Error getting deviceId: $e");
            print("[UPP GOAuth FlashLog] Error getting deviceId for ${authUser.id}. Error: $e. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
          }

          if (deviceId != null && deviceId.isNotEmpty) {
            if (_userProfileModel?.deviceId == null || _userProfileModel!.deviceId!.isEmpty || _userProfileModel!.deviceId != deviceId) {
              print("[UPP GOAuth FlashLog] Before Supabase profile UPDATE with device_id for ${authUser.id}. DeviceId: $deviceId. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
              try {
                await _supabaseClient.from('profiles').update({'device_id': deviceId}).eq('id', authUser.id);
                 print("[UPP GOAuth FlashLog] After Supabase profile UPDATE with device_id SUCCEEDED for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
                print("[UPP GOAuth FlashLog] Before loadUserProfile (post-device_id update) for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
                await loadUserProfile();
                if(_isDisposed) return;
                // This log is already good.
                print("[UPP GOAuth FlashLog] After loadUserProfile (post-device_id update) for ${authUser.id}. Model deviceId: ${_userProfileModel?.deviceId}, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, StaticFlag: $_isGoogleOAuthInProgressStatic");
              } catch (e) {
                print("[UserProfileProvider Google OAuth] Error updating device_id in Supabase: $e");
                print("[UPP GOAuth FlashLog] Error Supabase profile UPDATE with device_id for ${authUser.id}. Error: $e. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
              }
            }

            String? finalDeviceIdForCheck = _userProfileModel?.deviceId ?? deviceId;

            if (finalDeviceIdForCheck != null && finalDeviceIdForCheck.isNotEmpty && authUser != null) {
              // --- START OF CHANGE: Updated method call and log ---
              print("[UPP GOAuth FlashLog] Before _backendApplyDeviceLimits for ${authUser.id}, device: $finalDeviceIdForCheck. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
              bool limitWasActuallyAppliedByBackend = await _backendApplyDeviceLimits(authUser.id, finalDeviceIdForCheck);
              if (_isDisposed) return;
              print("[UPP GOAuth FlashLog] After _backendApplyDeviceLimits for ${authUser.id}. LimitAppliedByBackend: $limitWasActuallyAppliedByBackend. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
              // --- END OF CHANGE ---

              if (limitWasActuallyAppliedByBackend) {
                  print("[UPP GOAuth FlashLog] Before loadUserProfile (post-backend limit apply) for ${authUser.id}. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
                  await loadUserProfile();
                  if (_isDisposed) return;
                  // This log is already good.
                   print("[UPP GOAuth FlashLog] After loadUserProfile (post-backend limit apply) for ${authUser.id}. scan_count: ${_userProfileModel?.scanCount}, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, StaticFlag: $_isGoogleOAuthInProgressStatic");
              }
              print("[UserProfileProvider Google OAuth] Backend device limit check complete. Result: $limitWasActuallyAppliedByBackend. Final profile scan_count: ${_userProfileModel?.scanCount}, ask_expert_count: ${_userProfileModel?.askExpertCount}");
            } else {
               print("[UserProfileProvider Google OAuth] finalDeviceIdForCheck is null or empty. Skipping backend limit check.");
               print("[UPP GOAuth FlashLog] Skipping backend limit check for ${authUser.id} (finalDeviceIdForCheck null/empty). State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
            }
          } else {
            print("[UserProfileProvider Google OAuth] Fetched deviceId is null or empty. Skipping device ID update and backend limit check.");
            print("[UPP GOAuth FlashLog] Skipping device ID update and backend limit check for ${authUser.id} (fetched deviceId null/empty). State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
          }
        }
      } catch (e,s) {
         print("[UPP GOAuth FlashLog] Exception within Google OAuth specific processing block for user ${authUser.id}: $e\n$s. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag=$_isGoogleOAuthInProgressStatic");
         print("[UserProfileProvider onAuthStateChange - signedIn - GoogleSpecificTry] Exception within Google OAuth processing block: $e\n$s"); // Keep specific
      }
      finally {
        if (wasGoogleOAuth) {
          print("[UPP GOAuth FlashLog] Inside 'finally' for Google OAuth for ${authUser.id}. About to call endGoogleOAuthProcess. isPersonalized: $isPersonalized, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, New StaticFlag: $_isGoogleOAuthInProgressStatic (before reset)");
          UserProfileProvider.endGoogleOAuthProcess();
          print("[UserProfileProvider onAuthStateChange - signedIn - GoogleSpecificFinally] Static Google OAuth flag reset after all Google-specific processing in .then's try-finally block. New StaticFlag: $_isGoogleOAuthInProgressStatic");
          print("[UPP GOAuth FlashLog] After endGoogleOAuthProcess in 'finally' for ${authUser.id}. isPersonalized: $isPersonalized, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, New StaticFlag: $_isGoogleOAuthInProgressStatic");
        }
      }

      if (!_isDisposed) {
        // This log is already good.
        print("[UPP GOAuth FlashLog] Before final notifyListeners() in .then for ${authUser.id}. isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded");
        print("[UserProfileProvider onAuthStateChange - signedIn] Final notifyListeners for user ${authUser.id}. isPersonalized: $isPersonalized, scan_count: ${_userProfileModel?.scanCount}, isGoogleOAuthInProgressGlobal: ${UserProfileProvider.isGoogleOAuthInProgressGlobal}");
        notifyListeners();
      }
    }).catchError((e,s){
       print("[UPP GOAuth FlashLog] ERROR in .then chain for ${authUser.id}. Error: $e. State: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag before reset (if applicable): $_isGoogleOAuthInProgressStatic");
       print("[UserProfileProvider onAuthStateChange - signedIn - OuterCatchError] Error in setUserIdAndLoadProfile's .then chain: $e\n$s"); // Keep specific
       if (wasGoogleOAuth) {
         print("[UPP GOAuth FlashLog] Error path: Resetting staticGoogleFlag for ${authUser.id}. State before reset: isLoading=$_isLoading, isProfileLoaded=$__isUserProfileLoaded, isPersonalized=$isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");
         UserProfileProvider.endGoogleOAuthProcess();
         print("[UserProfileProvider onAuthStateChange - signedIn - OuterCatchError] Static Google OAuth flag reset due to error in Google OAuth processing chain. New StaticFlag: $_isGoogleOAuthInProgressStatic");
         print("[UPP GOAuth FlashLog] Error path: After resetting staticGoogleFlag for ${authUser.id}. New StaticFlag: $_isGoogleOAuthInProgressStatic");
       }
        if(!_isDisposed) notifyListeners();
    });
  } else if (authUser == null && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed || event == AuthChangeEvent.userUpdated)) {
     print("[UserProfileProvider onAuthStateChange - $event] AuthUser is null. Clearing profile. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
     clearUserProfileData(notify: true);
  } else if (event == AuthChangeEvent.signedOut) {
    print("[UserProfileProvider onAuthStateChange] SignedOut. Clearing profile. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    if (_isGoogleOAuthInProgressStatic) {
      print("[UPP GOAuth FlashLog] SignedOut event: Resetting static Google flag. Flag before: $_isGoogleOAuthInProgressStatic. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
      UserProfileProvider.endGoogleOAuthProcess();
      print("[UserProfileProvider onAuthStateChange - signedOut] Resetting static Google flag on sign out. New StaticFlag: $_isGoogleOAuthInProgressStatic");
    }
    clearUserProfileData(notify: true);
  } else if (event == AuthChangeEvent.initialSession) {
    print("[UserProfileProvider onAuthStateChange] PROCESSING AuthChangeEvent.initialSession START. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    if (authUser != null) {
      print("[UserProfileProvider onAuthStateChange - initialSession] User session found. Setting ID: ${authUser.id}");
      await setUserIdAndLoadProfile(authUser);
      if (_isGoogleOAuthInProgressStatic) {
        print("[UPP GOAuth FlashLog] InitialSession with user ${authUser.id}: Google flag is true. Awaiting signedIn event for Google specific logic. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
        print("[UserProfileProvider onAuthStateChange - initialSession] Google flag is true during initial session with user. Awaiting signedIn event for Google specific logic.");
      }
    } else {
      print("[UserProfileProvider onAuthStateChange - initialSession] No user session. Clearing profile.");
      clearUserProfileData(notify: false);
       __isUserProfileLoaded = false;
      if (_isGoogleOAuthInProgressStatic) {
        print("[UPP GOAuth FlashLog] InitialSession with NO user: Google flag is true. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
        print("[UserProfileProvider onAuthStateChange - initialSession] Null user event for initialSession, but Google OAuth was in progress. Flag remains for now.");
      }
    }
    if (!_isDisposed) {
        _hasInitialAuthCheckCompleted = true;
        if (_isLoading && authUser == null && !_isGoogleOAuthInProgressStatic) {
             _isLoading = false;
        }
        print("[UserProfileProvider onAuthStateChange - initialSession] Marking initial auth check COMPLETED. isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, hasInitialAuthCheckCompleted: $_hasInitialAuthCheckCompleted, StaticFlag: $_isGoogleOAuthInProgressStatic, isPersonalized: $isPersonalized");
        notifyListeners();
    }
  }
   else if (event == AuthChangeEvent.tokenRefreshed && authUser != null ) {
    print("[UserProfileProvider onAuthStateChange] Token refreshed for user ${authUser.id}. Ensuring profile is loaded. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    if (_userId != authUser.id || !__isUserProfileLoaded) {
       await setUserIdAndLoadProfile(authUser);
    }
    if (_isGoogleOAuthInProgressStatic) {
        print("[UPP GOAuth FlashLog] TokenRefreshed event: Resetting static Google flag (was unexpectedly true). Flag before: $_isGoogleOAuthInProgressStatic. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
        UserProfileProvider.endGoogleOAuthProcess();
        print("[UserProfileProvider onAuthStateChange - tokenRefreshed] Resetting static Google flag during token refresh, was unexpectedly true. New StaticFlag: $_isGoogleOAuthInProgressStatic");
    }
    if (!_isDisposed) notifyListeners();
  }
   else if (event == AuthChangeEvent.userUpdated && authUser != null) {
    print("[UserProfileProvider onAuthStateChange] User object updated for ${authUser.id}. Reloading profile. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    await setUserIdAndLoadProfile(authUser);
     if (_isGoogleOAuthInProgressStatic) {
        print("[UPP GOAuth FlashLog] UserUpdated event: Resetting static Google flag (was unexpectedly true). Flag before: $_isGoogleOAuthInProgressStatic. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
        UserProfileProvider.endGoogleOAuthProcess();
        print("[UserProfileProvider onAuthStateChange - userUpdated] Resetting static Google flag during user update, was unexpectedly true. New StaticFlag: $_isGoogleOAuthInProgressStatic");
    }
    if (!_isDisposed) notifyListeners();
  }
  else if (event == AuthChangeEvent.passwordRecovery) {
    // This is the new logic added at the top of the listener,
    // this else-if block handles the rest of the event processing.
    print("[UserProfileProvider onAuthStateChange] Password recovery event. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    if (_isGoogleOAuthInProgressStatic) {
      print("[UPP GOAuth FlashLog] PasswordRecovery event: Resetting static Google flag. Flag before: $_isGoogleOAuthInProgressStatic. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
      UserProfileProvider.endGoogleOAuthProcess();
      print("[UserProfileProvider onAuthStateChange - passwordRecovery] Resetting static Google flag on password recovery event. New StaticFlag: $_isGoogleOAuthInProgressStatic");
    }
    if (!_isDisposed) {
       _isLoading = false;
       if (!_hasInitialAuthCheckCompleted) _hasInitialAuthCheckCompleted = true;
       notifyListeners();
    }
  }

  // This final check for _hasInitialAuthCheckCompleted and subsequent notify seems okay.
  // It also logs the StaticFlag.
  if (!_hasInitialAuthCheckCompleted && !_isDisposed) {
    if ((event == AuthChangeEvent.signedIn && authUser != null) ||
        event == AuthChangeEvent.signedOut ||
        (event == AuthChangeEvent.initialSession && !_isGoogleOAuthInProgressStatic) ) {
        print("[UserProfileProvider onAuthStateChange] General: Marking initial auth check completed post-event. Event: $event, StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
        _hasInitialAuthCheckCompleted = true;
        if (_isLoading && (event == AuthChangeEvent.signedOut || (event == AuthChangeEvent.initialSession && authUser == null && !_isGoogleOAuthInProgressStatic))) {
            _isLoading = false;
        }
        notifyListeners();
    }
  }

}, onError: (error) {
    print("[UserProfileProvider onAuthStateChange] Error in auth stream: $error. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    if (_isGoogleOAuthInProgressStatic) {
      print("[UPP GOAuth FlashLog] onAuthStateChange onError: Resetting static Google flag. Flag before: $_isGoogleOAuthInProgressStatic. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
      UserProfileProvider.endGoogleOAuthProcess();
      print("[UserProfileProvider onAuthStateChange onError] Resetting static Google flag due to auth stream error. New StaticFlag: $_isGoogleOAuthInProgressStatic");
    }

    if (!_isDisposed) {
        _isLoading = false;
        if (!_hasInitialAuthCheckCompleted) {
            _hasInitialAuthCheckCompleted = true;
             print("[UserProfileProvider onAuthStateChange onError] Auth stream error, marking initial auth check COMPLETED to prevent indefinite loading. isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
        }
        notifyListeners();
    }
});

_handleInitialAuthCheck();
}

  // ADDED THIS METHOD
  void consumeAuthEvent() {
    lastAuthEvent = null; // Reset the event after handling it
  }

// --- START OF CHANGE: Renamed method and updated URL ---
Future<bool> _backendApplyDeviceLimits(String userId, String deviceId) async {
  print("[UserProfileProvider _backendApplyDeviceLimits] Calling backend for User: $userId, Device: $deviceId");

  if (deviceId.isEmpty || userId.isEmpty) {
    print("[UserProfileProvider _backendApplyDeviceLimits] Missing userId or deviceId.");
    return false;
  }

  try {
    final response = await http.post(
      Uri.parse('$_yourBackendBaseUrl/api/auth/apply-device-limits'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'userId': userId,
        'deviceId': deviceId,
      }),
    ).timeout(const Duration(seconds: 15));

    if (_isDisposed) {
      print("[UserProfileProvider _backendApplyDeviceLimits] Disposed after HTTP call for user $userId.");
      return false;
    }

    final responseBody = jsonDecode(response.body);
    print("[UserProfileProvider _backendApplyDeviceLimits] Backend response: $responseBody");

    if (response.statusCode == 200 && responseBody['success'] == true) {
      if (responseBody['limitApplied'] == true) {
        print("[UserProfileProvider _backendApplyDeviceLimits] Backend confirmed device limit was applied.");
        return true;
      } else {
        print("[UserProfileProvider _backendApplyDeviceLimits] Backend confirmed no device limit was applied.");
        return false;
      }
    } else {
      print("[UserProfileProvider _backendApplyDeviceLimits] Error from backend (status ${response.statusCode}): ${responseBody['error'] ?? 'Unknown error'}");
      return false;
    }
  } catch (e, s) {
    if (_isDisposed) {
       print("[UserProfileProvider _backendApplyDeviceLimits] Disposed during exception handling for user $userId. Exception: $e");
       return false;
    }
    print("[UserProfileProvider _backendApplyDeviceLimits] Exception calling backend: $e\n$s");
    return false;
  }
}
// --- END OF CHANGE ---

Future<void> _handleInitialAuthCheck() async {
await Future.delayed(Duration.zero);
if (_isDisposed) return;

if (!_hasInitialAuthCheckCompleted) {
    final currentUser = _supabaseClient.auth.currentUser;
    print("[UserProfileProvider _handleInitialAuthCheck] Fallback initial auth check running. Current User: ${currentUser?.id}, isLoading: $_isLoading, hasInitialAuthCheckCompleted: $_hasInitialAuthCheckCompleted, StaticGoogleOAuthInProgress: $_isGoogleOAuthInProgressStatic, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");

    if (_isGoogleOAuthInProgressStatic && currentUser == null) {
      print("[UPP GOAuth FlashLog] _handleInitialAuthCheck: Google OAuth in progress, no current user yet. Listener will handle. isLoading: $_isLoading, StaticFlag: $_isGoogleOAuthInProgressStatic, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
      print("[UserProfileProvider _handleInitialAuthCheck] Google OAuth in progress, no current user yet. Listener will handle incoming OAuth event. Setting _isLoading to true if not already.");
      if (!_isLoading && !_isDisposed) {
        _isLoading = true;
      }
    } else if (currentUser != null) {
        if (!__isUserProfileLoaded && !_isLoading) {
             print("[UserProfileProvider _handleInitialAuthCheck] User found, profile not loaded, and not currently loading. Setting ID and loading profile.");
             await setUserIdAndLoadProfile(currentUser);
        } else if (__isUserProfileLoaded) {
            print("[UserProfileProvider _handleInitialAuthCheck] User found, profile already loaded. State should be current.");
            if (_isLoading && !_isDisposed) {
                _isLoading = false;
            }
        } else if (_isLoading) {
             print("[UserProfileProvider _handleInitialAuthCheck] User found, but profile load is already in progress. Listener should handle.");
        }
    } else {
        if (_isLoading || !__isUserProfileLoaded) {
            print("[UserProfileProvider _handleInitialAuthCheck] No user (and not Google OAuth in progress). Clearing profile and stopping load.");
            clearUserProfileData(notify: false);
        }
    }

    if (!_isDisposed) {
       _hasInitialAuthCheckCompleted = true;
       if (_supabaseClient.auth.currentUser == null && _isLoading && !_isGoogleOAuthInProgressStatic) {
           _isLoading = false;
       }
       print("[UserProfileProvider _handleInitialAuthCheck] Fallback initial auth check complete. Notifying. isLoading: $_isLoading, isProfileLoaded: $isProfileLoaded, hasInitialAuthCheckCompleted: $_hasInitialAuthCheckCompleted, StaticGoogleOAuthInProgress: $_isGoogleOAuthInProgressStatic, isPersonalized: $isPersonalized");
       notifyListeners();
    }
 } else {
    print("[UserProfileProvider _handleInitialAuthCheck] Skipped: authCheckCompleted: $_hasInitialAuthCheckCompleted, isLoading: $_isLoading, isProfileLoaded: $isProfileLoaded, StaticFlag: $_isGoogleOAuthInProgressStatic, isPersonalized: $isPersonalized");
    if (!_isDisposed && _isLoading && _supabaseClient.auth.currentUser == null && !__isUserProfileLoaded && !_isGoogleOAuthInProgressStatic) {
        print("[UserProfileProvider _handleInitialAuthCheck] Auth check completed, no user (not Google OAuth), profile NOT loaded, but still isLoading. Resetting isLoading.");
        _isLoading = false;
        notifyListeners();
    } else if (!_isDisposed && !_isLoading && _supabaseClient.auth.currentUser != null && !__isUserProfileLoaded) {
        print("[UserProfileProvider _handleInitialAuthCheck] Auth check completed, user exists, not loading, but profile not loaded. Triggering load.");
        await setUserIdAndLoadProfile(_supabaseClient.auth.currentUser!);
    }
 }
}

// ---- REVENUECAT INITIALIZATION METHOD ----
/// Initialize RevenueCat and perform one-time migration sync
/// This is called automatically after user profile is loaded
void _initializeRevenueCat(String userId) async {
  try {
    print("[UserProfileProvider] Initializing RevenueCat for user: $userId");
    
    final revenueCatService = RevenueCatService();
    
    // Initialize RevenueCat with user ID
    if (!revenueCatService.isInitialized) {
      await revenueCatService.initRevenueCat(userId);
      print("[UserProfileProvider] RevenueCat initialized successfully");
    }
    
    // Perform one-time migration sync (imports existing App Store/Play Store subscriptions)
    // This is safe to call multiple times - it will only run once per install
    final accessToken = _supabaseClient.auth.currentSession?.accessToken;
    if (accessToken != null) {
      print("[UserProfileProvider] Starting RevenueCat migration sync...");
      final syncSuccess = await revenueCatService.syncPurchasesForMigration(accessToken);
      
      if (syncSuccess) {
        print("[UserProfileProvider] RevenueCat migration sync completed successfully");
        // NOTE: We intentionally do NOT call loadUserProfile() here to prevent infinite loop
        // The sync updates the database via webhook, and the profile will be refreshed
        // on the next app launch or when the user navigates back to a profile-dependent screen
      } else {
        print("[UserProfileProvider] RevenueCat migration sync failed or was skipped");
      }
    } else {
      print("[UserProfileProvider] Cannot perform migration sync - no access token available");
    }
    
  } catch (e) {
    // Don't fail app startup if RevenueCat initialization fails
    // The user can still use the app, and purchases can be attempted later
    print("[UserProfileProvider] Error initializing RevenueCat: $e");
  }
}
// ---- END REVENUECAT INITIALIZATION METHOD ----


@override
void dispose() {
print("[UserProfileProvider] Disposing...");
_isDisposed = true;
_authStateSubscription?.cancel();
super.dispose();
}

// --- GETTERS ---
UserProfile? get userProfile => _userProfileModel;
String? get userId => _userId;
String get fullName => _fullName;
String? get email => _email;

// ---- ADDED GETTER FOR PREGNANCY DETAILS ----
UserPregnancyDetails? get userPregnancyDetails => _userPregnancyDetails;
// ---- END ADDED GETTER ----

bool get isLoggedIn {
return _supabaseClient.auth.currentSession != null &&
_supabaseClient.auth.currentUser != null &&
_userId != null &&
_userId == _supabaseClient.auth.currentUser!.id;
}
String? get selectedTrimester => _userProfileModel?.selectedTrimester;
String? get selectedDietaryPreferenceString => _userProfileModel?.dietaryPreference;
DietaryPreference? get selectedDietaryPreferenceEnum {
if (_userProfileModel?.dietaryPreference == null) return null;
return _parseDietaryPreference(_userProfileModel!.dietaryPreference!);
}
List<String> get knownAllergies => List.unmodifiable(_knownAllergies);
String get customAllergiesText => _customAllergiesText;
String get profileImageUrl => _profileImageUrl;
String? get languagePreference => _languagePreference;
int? get memberSinceYear => _memberSinceYear;
String? get mobileNumber => _mobileNumber;
String? get countryCode => _countryCode;
bool get isPhoneVerified => _isPhoneVerified;
bool get emailNotificationsEnabled => _emailNotificationsEnabled;
bool get dataSharingEnabled => _dataSharingEnabled;
bool get isLoading => _isLoading;
bool get isSaving => _isSaving;
bool get isProfileLoaded => __isUserProfileLoaded;
bool get hasInitialAuthCheckCompleted => _hasInitialAuthCheckCompleted;

bool get isPersonalized {
if (!isProfileLoaded || _userProfileModel == null) {
return false;
}
final trimesterSet = _userProfileModel!.selectedTrimester != null &&
_userProfileModel!.selectedTrimester!.isNotEmpty &&
_userProfileModel!.selectedTrimester != TrimesterOption.none.toSupabaseString();

final dietSet = _userProfileModel!.dietaryPreference != null &&
                _userProfileModel!.dietaryPreference!.isNotEmpty &&
                _userProfileModel!.dietaryPreference != DietaryPreferenceOption.none.toSupabaseString();

final result = trimesterSet && dietSet;
return result;
}
// --- End of GETTERS ---

Future<void> setUserIdAndLoadProfile(User user) async {
if (_isDisposed) return;

print("[UserProfileProvider] setUserIdAndLoadProfile called for User ID: ${user.id}. Current isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, currentUserID: $_userId, isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");

bool needsLoad = false;
if (_userId != user.id || !__isUserProfileLoaded) {
    needsLoad = true;
    print("[UserProfileProvider] Needs load: userId changed (${_userId} -> ${user.id}) or profile not loaded ($__isUserProfileLoaded).");
}

_userId = user.id;
_email = user.email;

if (needsLoad) {
    print("[UserProfileProvider] User ID set to: $_userId. Auth Email: $_email. Preparing to load profile.");
    if (!_isLoading && !_isDisposed) {
      _isLoading = true;
      // No notifyListeners here, loadUserProfile will handle it or the caller (onAuthStateChange)
    }
    await loadUserProfile();
} else {
    print("[UserProfileProvider] User ID $_userId same and profile previously loaded. Ensuring correct state for isLoading.");
    if (_isLoading && !_isDisposed) {
      _isLoading = false;
       // No notifyListeners here if called from onAuthStateChange, as it will notify at the end.
    } else if (!_isLoading && !_isDisposed && __isUserProfileLoaded) {
       if (_userProfileModel?.email != _email && _email != null) {
          print("[UserProfileProvider] Auth email '$_email' different from profile model email '${_userProfileModel?.email}'. Updating model.");
          _userProfileModel = _userProfileModel?.copyWith(email: _email);
          // No notifyListeners here if called from onAuthStateChange.
       }
    }
}
}

Future<void> loadUserProfile() async {
if (_userId == null) {
print("[UserProfileProvider] loadUserProfile: No user ID. Clearing profile. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
clearUserProfileData(notify: true); // This will also clear _userPregnancyDetails
return;
}

print("[UserProfileProvider] Loading user profile from Supabase for user: $_userId. Current isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");
if (!_isLoading && !_isDisposed) {
    _isLoading = true;
    notifyListeners(); // Notify if we are starting a load from scratch
}

try {
  final String comprehensiveSelectQuery = '''
    id, full_name, email, mobile_number, country_code, is_phone_verified,
    profile_image_url, selected_trimx, dietary_preference, known_allergies,
    custom_allergies, language_pref, email_notifications_enabled, due_date,
    data_sharing_consent, role, membership_tier, scan_count, last_share_timestamp,
    device_id, premium_expiry_date, is_pro_member, daily_scan_limit_reset_at,
    primary_goal, created_at, updated_at, ask_expert_count, personalized_guide_count,
    manual_search_count, lmp_calculator_count, due_date_calculator_count,
    ttc_calculator_count, baby_name_generator_count, kick_counter_sessions,
    contraction_timer_sessions, document_analysis_count, weight_gain_tracker_count,
    appointment_scheduler_count, fertility_tracker_count, postpartum_tracker_count,
    mental_health_assessments, nutrition_planning_count
  ''';

  final response = await _supabaseClient
      .from('profiles')
      .select(comprehensiveSelectQuery)
      .eq('id', _userId!)
      .maybeSingle();

  print('[UserProfileProvider loadUserProfile] Raw Supabase response for profiles table: $response');

  if (_isDisposed) {
    print("[UserProfileProvider] Disposed during loadUserProfile db call for $_userId");
    return;
  }

  if (response != null && response.isNotEmpty) {
    print("[UserProfileProvider] Supabase profile data received for $_userId");
    print("[UserProfileProvider] Premium Status Check - membership_tier: ${response['membership_tier']}, is_premium: ${response['is_premium']}, is_pro_member: ${response['is_pro_member']}");
    _userProfileModel = UserProfile.fromMap(response);
    print("[UserProfileProvider] After parsing - membershipTier: ${_userProfileModel?.membershipTier}, isPremium: ${_userProfileModel?.isPremium}, isPremiumUser: ${_userProfileModel?.isPremiumUser}");
    if (response['email'] != null && response['email'] != _email) {
        print("[UserProfileProvider] Email from profile ('${response['email']}') differs from auth email ('$_email'). Keeping auth email for provider state, but model reflects DB.");
    }
    _updateLocalStateFromData(response);
  } else {
    print("[UserProfileProvider] No profile found in Supabase for user $_userId. Creating temporary profile from auth data.");
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser != null && currentUser.id == _userId) {
        _userProfileModel = UserProfile(
            id: currentUser.id,
            email: _email ?? currentUser.email ?? '',
            fullName: currentUser.userMetadata?['full_name'] as String? ?? currentUser.userMetadata?['name'] as String? ?? _fullName,
            membershipTier: 'free',
            scanCount: 0,
            askExpertCount: 0,
            personalizedGuideCount: 0,
            manualSearchCount: 0,
            isPhoneVerified: currentUser.phone != null && currentUser.phone!.isNotEmpty,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            selectedTrimester: TrimesterOption.none.toSupabaseString(),
            dietaryPreference: DietaryPreferenceOption.none.toSupabaseString(),
        );
        _updateLocalStateFromModel(_userProfileModel!);
        print("[UserProfileProvider] Temporary profile created for ${_userId}. isPersonalized: $isPersonalized, scan_count: ${_userProfileModel?.scanCount}");
    } else {
        print("[UserProfileProvider] Could not create temporary profile: currentUser mismatch or null for $_userId.");
        _userProfileModel = null;
        _resetToDefaults(keepAuthDetails: true);
    }
  }

  if (_userId != null) {
    try {
      print("[UserProfileProvider] Fetching pregnancy details from user_pregnancy_details table for user: $_userId");
      _userPregnancyDetails = await _pregnancyDetailsService.getPregnancyDetails(_userId!);
      if (_isDisposed) return;
      print('[UserProfileProvider] Pregnancy details loaded: ${_userPregnancyDetails?.dueDate != null ? DateFormat('yyyy-MM-dd').format(_userPregnancyDetails!.dueDate!) : 'null'}');
    } catch (e, s) {
      if (_isDisposed) return;
      print('[UserProfileProvider] Failed to load pregnancy details for $_userId: $e\n$s');
      _userPregnancyDetails = null;
    }
  } else {
     _userPregnancyDetails = null;
  }
  print("[UserProfileProvider] Profile loaded successfully for $_userId. Model selectedTrimester: ${_userProfileModel?.selectedTrimester}, DueDate from profiles table (if any): ${_userProfileModel?.dueDate}, PregnancyDetails.dueDate: ${_userPregnancyDetails?.dueDate}, isPersonalized: $isPersonalized, scan_count: ${_userProfileModel?.scanCount}, device_id: ${_userProfileModel?.deviceId}");

} catch (e,s) {
  print("[UserProfileProvider] Error loading profile from Supabase for $_userId: $e\n$s");
  _userProfileModel = null;
  _userPregnancyDetails = null;
  _resetToDefaults(keepAuthDetails: true);
} finally {
  if (!_isDisposed) {
    _isLoading = false;
    __isUserProfileLoaded = true;
    this._localeProvider.initializeLocale(_userProfileModel?.languagePref);
    // =================================== THIS IS THE CORRECTED LINE ===================================
    print("[UserProfileProvider] Profile load attempt finished for $_userId. isLoaded: $isProfileLoaded, isLoading: $_isLoading, modelExists: ${_userProfileModel != null}, isPersonalized: $isPersonalized, language: ${_userProfileModel?.languagePref}, scan_count: ${_userProfileModel?.scanCount}, final profile.dueDate: ${_userProfileModel?.dueDate}, final pregnancyDetails.dueDate: ${_userPregnancyDetails?.dueDate}, StaticFlag: $_isGoogleOAuthInProgressStatic");
    // ==================================================================================================
    
    // ---- REVENUECAT INITIALIZATION & MIGRATION SYNC ----
    // Initialize RevenueCat after successful profile load
    if (_userId != null && _userProfileModel != null) {
      _initializeRevenueCat(_userId!);
    }
    // ---- END REVENUECAT INITIALIZATION ----
    
    // notifyListeners() here might be redundant if called from onAuthStateChange, but safe.
    // However, if loadUserProfile is called standalone, this notifyListeners is crucial.
    // The onAuthStateChange logic aims to call its own notifyListeners at the very end of its processing.
    // Let's rely on the caller (onAuthStateChange) to notify for consistency within that flow.
    // If loadUserProfile is called from elsewhere, ensure the caller handles notification or this one is intended.
    // For GOAuth flow, the primary notifyListeners is at the end of the .then() in onAuthStateChange.
  }
}
}

void clearUserProfileData({bool notify = true}) {
print("[UserProfileProvider] Clearing local user profile data. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
_userProfileModel = null;
_userPregnancyDetails = null; // ---- ADDED: Clear pregnancy details ----
_userId = null;
_email = null;
_resetToDefaults(keepAuthDetails: false);

_isLoading = false;
__isUserProfileLoaded = false;

this._localeProvider.initializeLocale(null);

// ---- RESET REVENUECAT ON LOGOUT ----
try {
  final revenueCatService = RevenueCatService();
  revenueCatService.reset();
  print("[UserProfileProvider] RevenueCat service reset on logout");
} catch (e) {
  print("[UserProfileProvider] Error resetting RevenueCat: $e");
}
// ---- END REVENUECAT RESET ----

if (notify && !_isDisposed) {
  print("[UserProfileProvider] Notifying after clearing profile data. isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, StaticFlag: $_isGoogleOAuthInProgressStatic, isPersonalized: $isPersonalized");
  notifyListeners();
} else if(!notify) {
  print("[UserProfileProvider] Profile data cleared (notify=false). isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, StaticFlag: $_isGoogleOAuthInProgressStatic, isPersonalized: $isPersonalized");
}
}

void _updateLocalStateFromModel(UserProfile profile) {
_fullName = profile.fullName ?? 'Mama';
_email = profile.email ?? _email;
_knownAllergies = profile.knownAllergies ?? [];
_customAllergiesText = profile.customAllergies ?? '';
_profileImageUrl = profile.profileImageUrl ?? '';
_languagePreference = profile.languagePref;
_emailNotificationsEnabled = profile.emailNotifications ?? false;
_dataSharingEnabled = profile.dataSharing ?? false;
_mobileNumber = profile.mobileNumber;
_countryCode = profile.countryCode;
_isPhoneVerified = profile.isPhoneVerified ?? false;
if (profile.createdAt != null) {
_memberSinceYear = profile.createdAt!.year;
} else {
_memberSinceYear = null;
}
}

void _updateLocalStateFromData(Map<String, dynamic> data) {
if (data['email'] != null && data['email'] != _email) {
// see comment in loadUserProfile
}
_fullName = data['full_name'] as String? ?? _userProfileModel?.fullName ?? _fullName;

if (data.containsKey('known_allergies') && data['known_allergies'] is List) {
  _knownAllergies = (data['known_allergies'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ?? _userProfileModel?.knownAllergies ?? [];
} else { _knownAllergies = _userProfileModel?.knownAllergies ?? []; }
_customAllergiesText = data['custom_allergies'] as String? ?? _userProfileModel?.customAllergies ?? '';
_profileImageUrl = data['profile_image_url'] as String? ?? _userProfileModel?.profileImageUrl ?? '';
_languagePreference = data['language_pref'] as String? ?? _userProfileModel?.languagePref;
_emailNotificationsEnabled = data['email_notifications_enabled'] as bool? ?? _userProfileModel?.emailNotifications ?? false;
_dataSharingEnabled = data['data_sharing_consent'] as bool? ?? data['data_sharing'] as bool? ?? _userProfileModel?.dataSharing ?? false;
_mobileNumber = data['mobile_number'] as String? ?? _userProfileModel?.mobileNumber;
_countryCode = data['country_code'] as String? ?? _userProfileModel?.countryCode;
_isPhoneVerified = data['is_phone_verified'] as bool? ?? _userProfileModel?.isPhoneVerified ?? false;

final createdAtString = data['created_at'] as String?;
if (createdAtString != null) {
  try {
      final parsedDate = DateTime.tryParse(createdAtString);
      if (parsedDate != null) {
        _memberSinceYear = parsedDate.year;
      } else {
        _memberSinceYear = _userProfileModel?.createdAt?.year;
      }
  }
  catch (e) {
    print("[UserProfileProvider] Error parsing memberSinceYear from 'created_at': $e. Using model's value if available.");
    _memberSinceYear = _userProfileModel?.createdAt?.year;
  }
} else {
  _memberSinceYear = _userProfileModel?.createdAt?.year;
}
print("[UserProfileProvider] Provider INDIVIDUAL state updated. lang=${_languagePreference}, model trimester (string): ${_userProfileModel?.selectedTrimester}");
}

void _resetToDefaults({bool keepAuthDetails = false}) {
if (!keepAuthDetails) {
// _userId and _email are nulled by clearUserProfileData or when authUser is null
}
_fullName = 'Mama';
_knownAllergies = [];
_customAllergiesText = '';
_profileImageUrl = '';
_languagePreference = null;
_memberSinceYear = null;
_emailNotificationsEnabled = false;
_dataSharingEnabled = false;
_mobileNumber = null;
_countryCode = null;
_isPhoneVerified = false;
// _userPregnancyDetails is cleared in clearUserProfileData
print("[UserProfileProvider] Local profile fields reset. KeepAuth: $keepAuthDetails.");
}

Future<bool> signInWithGoogle() async {
if (_isDisposed) return false;

print("[UPP GOAuth FlashLog] signInWithGoogle: Before startGoogleOAuthProcess. isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");
UserProfileProvider.startGoogleOAuthProcess();
print("[UPP GOAuth FlashLog] signInWithGoogle: After startGoogleOAuthProcess. isLoading: $_isLoading (before notify), isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");

if (!_isLoading && !_isDisposed) {
    _isLoading = true;
    notifyListeners();
} else if (_isLoading && !_isDisposed) {
    // Already loading, but notify to ensure any immediate UI updates tied to _isGoogleOAuthInProgressStatic change
    notifyListeners();
}
print("[UPP GOAuth FlashLog] signInWithGoogle: After potential notifyListeners. isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");

print("[UserProfileProvider signInWithGoogle] Attempting to initiate Google OAuth. Static flag _isGoogleOAuthInProgressStatic: $_isGoogleOAuthInProgressStatic");

try {
  print("[UPP GOAuth FlashLog] signInWithGoogle: Before _supabaseClient.auth.signInWithOAuth. redirectTo: com.safemama.app://login-callback/. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized, StaticFlag: $_isGoogleOAuthInProgressStatic");
  final success = await _supabaseClient.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'com.safemama.app://login-callback/',
  );
  if (!success) {
    _isLoading = false;
    UserProfileProvider.endGoogleOAuthProcess();
    print("[UPP GOAuth FlashLog] signInWithGoogle: Supabase signInWithOAuth returned false. StaticFlag after reset: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized (before notify)");
    print("[UserProfileProvider signInWithGoogle] Supabase signInWithOAuth returned false (initiation failed). Resetting static flag.");
    if (!_isDisposed) notifyListeners();
    return false;
  }
  print("[UPP GOAuth FlashLog] signInWithGoogle: Supabase signInWithOAuth returned true. Listener will handle. StaticFlag: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
  print("[UserProfileProvider signInWithGoogle] OAuth initiated successfully via Supabase. Static flag remains true. Listener will handle completion.");
  return true;
} catch (e,s) {
  print('[UserProfileProvider signInWithGoogle] error: $e\n$s');
  _isLoading = false;
  UserProfileProvider.endGoogleOAuthProcess();
  print("[UPP GOAuth FlashLog] signInWithGoogle: Exception during OAuth initiation. Error: $e. StaticFlag after reset: $_isGoogleOAuthInProgressStatic, isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized (before notify)");
  print("[UserProfileProvider signInWithGoogle] Exception during OAuth initiation. Resetting static flag.");
  if (!_isDisposed) notifyListeners();
  return false;
}
}

// Inside the UserProfileProvider class

// --- REPLACE the old signInWithApple method with this one ---

Future<bool> signInWithApple() async {
  if (_isDisposed) return false;

  print("[UserProfileProvider] Attempting to initiate Sign in with Apple.");
  _isLoading = true;
  notifyListeners();

  try {
    // 1. Create a raw nonce for security.
    final rawNonce = _generateRandomString();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

    // 2. Request the credential from Apple, asking for name and email.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // 3. Get the identity token.
    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw const AuthException('Could not find identity token.');
    }

    // 4. Sign in to Supabase. This creates the user in 'auth.users'.
    final authResponse = await _supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    final user = authResponse.user;
    if (user == null) {
      throw const AuthException('Sign in with Apple succeeded but no user was returned.');
    }
    
    // --- THIS IS THE NEW, CRUCIAL PART ---
    // 5. Check if Apple gave us the user's name (only happens on first sign-up).
    final String? firstName = appleCredential.givenName;
    final String? lastName = appleCredential.familyName;
    
    if (firstName != null) {
      final fullName = '$firstName ${lastName ?? ''}'.trim();
      
      // If we got a name, immediately update our 'profiles' table.
      if (fullName.isNotEmpty) {
        print("[UserProfileProvider] New Apple user. Saving name to profile: $fullName");
        await _supabaseClient
            .from('profiles')
            .update({'full_name': fullName})
            .eq('id', user.id);
      }
    }
    // --- END OF NEW PART ---
    
    // The onAuthStateChange listener will now fire. When it loads the
    // profile, the name will be there, and it will correctly redirect to home.
    return true;

  } on SignInWithAppleAuthorizationException catch (e) {
    print("[UserProfileProvider] Apple Sign-In cancelled or failed: ${e.code}");
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (error) {
    print("[UserProfileProvider] Error during Apple Sign-In: $error");
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

// Helper method to generate a random string for the nonce
String _generateRandomString([int length = 32]) {
  final random = math.Random.secure();
  return List.generate(length, (index) => random.nextInt(256))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

// =====================================================================
// ========== THIS IS THE CORRECTED METHOD =============================
// =====================================================================
Future<bool> signInWithEmail(String email, String password) async {
  if (_isDisposed) return false;

  // Set loading state and notify UI
  if (!_isLoading) {
    _isLoading = true;
    notifyListeners();
  }

  try {
    final AuthResponse res = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // On success, the onAuthStateChange listener will handle everything, including
    // setting isLoading = false after the profile is loaded. So we just return true.
    if (res.user != null) {
      return true;
    }
    // This case is unlikely but safe to handle.
    _isLoading = false;
    notifyListeners();
    return false;
  } on AuthException catch (e) {
    print('[UserProfileProvider signInWithEmail] AuthException: ${e.message}');
    // THE FIX: On failure, immediately reset loading state and notify.
    // This allows the UI to update and show an error *before* any potential
    // redirect could happen.
    _isLoading = false;
    if (!_isDisposed) notifyListeners();
    return false; // Return false to signal failure to the UI.
  } catch (e, s) {
    print('[UserProfileProvider signInWithEmail] unexpected error: $e\n$s');
    _isLoading = false;
    if (!_isDisposed) notifyListeners();
    return false;
  }
}
// =====================================================================
// ========== END OF CORRECTED METHOD ==================================
// =====================================================================

  Future<bool> signInWithPhoneAndPassword(String phoneNumber, String password) async {
    if (_isDisposed) return false;

    if (!_isLoading && !_isDisposed) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Calls the new custom endpoint on your server
      final url = Uri.parse('$_yourBackendBaseUrl/api/auth/login-with-phone');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber, 'password': password}),
      );

      if (_isDisposed) return false;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessionData = data['session'];
        if (sessionData != null && sessionData['refresh_token'] != null) {
          await _supabaseClient.auth.setSession(sessionData['refresh_token']);
          // The onAuthStateChange listener will automatically handle the rest.
          print("[UserProfileProvider] signInWithPhoneAndPassword successful. Session set.");
          return true;
        }
      }

      print("Failed to sign in with phone. Status: ${response.statusCode}, Body: ${response.body}");
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      return false;

    } catch (e, s) {
      print("Exception during phone sign-in: $e\n$s");
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> sendLoginOtp(String phoneNumber) async {
    if (_isDisposed) return false;
    _isLoading = true;
    notifyListeners();

    print("[UserProfileProvider] Sending login OTP to $phoneNumber");

    try {
      final response = await http.post(
        Uri.parse('$_yourBackendBaseUrl/api/auth/send-login-otp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      if (_isDisposed) return false;

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print("[UserProfileProvider] Backend failed to send login OTP: ${responseBody['error']}");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("[UserProfileProvider] Error sending login OTP: $e");
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> verifyLoginOtpAndSignIn(String phoneNumber, String otp) async {
    if (_isDisposed) return false;
    _isLoading = true;
    notifyListeners();

    print("[UserProfileProvider] Verifying login OTP for $phoneNumber");

    try {
      final response = await http.post(
        Uri.parse('$_yourBackendBaseUrl/api/auth/verify-login-otp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
      );

      if (_isDisposed) return false;

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['session'] != null) {
        final sessionData = responseBody['session'];
        final String refreshToken = sessionData['refresh_token'];

        await _supabaseClient.auth.setSession(refreshToken);

        print("[UserProfileProvider] Session set successfully. Auth listener will handle the rest.");
        return true;
      } else {
        print("[UserProfileProvider] Backend failed to verify login OTP: ${responseBody['error']}");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("[UserProfileProvider] Error verifying login OTP: $e");
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  // UPDATED METHOD AS PER INSTRUCTIONS
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      // --- THIS IS THE FINAL, CORRECT FIX ---
      // We explicitly tell Supabase what link to generate.
      // Supabase will take this value and embed it into the {{ .ConfirmationURL }} variable.
      // This MUST match a URL in your Supabase "Redirect URLs" list.
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.safemama.app://reset-password',
      );
      // --- END OF FIX ---
      return true;
    } catch (e) {
      print("Error sending password reset email: $e");
      return false;
    }
  }

  Future<bool> updateUserPassword(String newPassword) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword)
      );
      return true;
    } catch (e) {
      print("Error updating user password: $e");
      return false;
    }
  }

  // =====================================================================
  // ========== ADDED THESE TWO NEW METHODS TO THE CLASS =================
  // =====================================================================

  /// Sends a password reset OTP to a user's phone via the backend.
  Future<bool> sendPasswordResetOtp(String phoneNumber, String countryCode) async {
    try {
      final url = Uri.parse('$_yourBackendBaseUrl/api/auth/send-password-reset-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'countryCode': countryCode,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
      print("[UserProfileProvider] Failed to send reset OTP: ${response.body}");
      return false;
    } catch (e) {
      print("[UserProfileProvider] Exception sending password reset OTP: $e");
      return false;
    }
  }

  /// Verifies a reset OTP and sets a new password via the backend.
  Future<bool> verifyAndResetPassword(String phoneNumber, String countryCode, String otp, String newPassword) async {
    try {
      final url = Uri.parse('$_yourBackendBaseUrl/api/auth/verify-reset-otp-and-set-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'countryCode': countryCode,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
       print("[UserProfileProvider] Failed to verify/reset password: ${response.body}");
      return false;
    } catch (e) {
      print("[UserProfileProvider] Exception verifying/resetting password: $e");
      return false;
    }
  }

  /// Auto-login after password reset via WhatsApp OTP.
  /// Queries the backend to get the email associated with the phone number,
  /// then signs in with that email and the new password.
  Future<bool> autoLoginAfterPasswordReset(String phoneNumber, String countryCode, String newPassword) async {
    try {
      // First, get the email associated with this phone number from the backend
      final lookupUrl = Uri.parse('$_yourBackendBaseUrl/api/auth/lookup-email-by-phone');
      final lookupResponse = await http.post(
        lookupUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'countryCode': countryCode,
        }),
      );

      if (lookupResponse.statusCode != 200) {
        print("[UserProfileProvider] Failed to lookup email for phone: ${lookupResponse.body}");
        return false;
      }

      final lookupData = json.decode(lookupResponse.body);
      final email = lookupData['email'] as String?;
      
      if (email == null || email.isEmpty) {
        print("[UserProfileProvider] No email found for phone number");
        return false;
      }

      print("[UserProfileProvider] Found email $email for phone, attempting auto-login...");

      // Now sign in with the email and new password
      final authResponse = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: newPassword,
      );

      if (authResponse.session != null && authResponse.user != null) {
        print("[UserProfileProvider] Auto-login successful after password reset for user ${authResponse.user!.id}");
        return true;
      } else {
        print("[UserProfileProvider] Auto-login failed: no session returned");
        return false;
      }
    } catch (e) {
      print("[UserProfileProvider] Exception during auto-login after password reset: $e");
      return false;
    }
  }

Future<void> signOut() async {
print("[UserProfileProvider] Signing out user...");

if (_isGoogleOAuthInProgressStatic) {
    print("[UPP GOAuth FlashLog] signOut: Resetting static Google flag. Flag before: $_isGoogleOAuthInProgressStatic. Current State: isLoading: $_isLoading, isProfileLoaded: $__isUserProfileLoaded, isPersonalized: $isPersonalized");
    UserProfileProvider.endGoogleOAuthProcess();
    print("[UserProfileProvider signOut] Resetting _isGoogleOAuthInProgressStatic during sign out. New StaticFlag: $_isGoogleOAuthInProgressStatic");
}

if (!_isLoading && !_isDisposed) {
  _isLoading = true;
  notifyListeners();
}

try {
  await _supabaseClient.auth.signOut();
  print("[UserProfileProvider] Supabase sign out successful. Auth listener will clear local state.");
} catch (e,s) {
  print("[UserProfileProvider] Error during Supabase sign out: $e\n$s");
  clearUserProfileData(notify: false); // Manually clear if signOut fails before listener acts
  if (!_isDisposed) {
    _isLoading = false;
    notifyListeners();
  }
}
}

// TASK 3 UPDATE: Added the updateUserProfile method as specified
Future<void> updateUserProfile(Map<String, dynamic> updates) async {
  try {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    print('[UserProfileProvider] Updating profile for user: $userId with data: $updates');

    // Map incoming logical keys to actual Supabase column names
    final Map<String, dynamic> updatesToSend = {
      // Column renames/mappings
      if (updates.containsKey('selected_trimester')) 'selected_trimx': updates['selected_trimester'],
      if (updates.containsKey('email_notifications')) 'email_notifications_enabled': updates['email_notifications'],
      if (updates.containsKey('data_sharing')) 'data_sharing_consent': updates['data_sharing'],

      // Direct passthroughs
      if (updates.containsKey('dietary_preference')) 'dietary_preference': updates['dietary_preference'],
      if (updates.containsKey('primary_goal')) 'primary_goal': updates['primary_goal'],
      if (updates.containsKey('known_allergies')) 'known_allergies': updates['known_allergies'],
      if (updates.containsKey('custom_allergies')) 'custom_allergies': updates['custom_allergies'],
      if (updates.containsKey('language_pref')) 'language_pref': updates['language_pref'],
      if (updates.containsKey('full_name')) 'full_name': updates['full_name'],
    };

    // Never send non-existent columns
    updatesToSend.remove('is_personalized');

    // Update in Supabase
    final response = await _supabaseClient
        .from('profiles')
        .update(updatesToSend)
        .eq('id', userId)
        .select()
        .single();

    print('[UserProfileProvider] Profile update response: $response');

    // Update local state
    if (_userProfileModel != null) {
      _userProfileModel = _userProfileModel!.copyWith(
        selectedTrimester: updates['selected_trimester'] ?? _userProfileModel!.selectedTrimester,
        dietaryPreference: updates['dietary_preference'] ?? _userProfileModel!.dietaryPreference,
        primaryGoal: updates['primary_goal'] ?? _userProfileModel!.primaryGoal,
        knownAllergies: updates['known_allergies'] != null 
            ? List<String>.from(updates['known_allergies']) 
            : _userProfileModel!.knownAllergies,
        customAllergies: updates['custom_allergies'] ?? _userProfileModel!.customAllergies,
        emailNotifications: updates['email_notifications'] ?? _userProfileModel!.emailNotifications,
        dataSharing: updates['data_sharing'] ?? _userProfileModel!.dataSharing,
        languagePref: updates['language_pref'] ?? _userProfileModel!.languagePref,
        // Consider the user personalized if core fields were provided
        isPersonalized: (updates.containsKey('selected_trimester') ||
                         updates.containsKey('dietary_preference') ||
                         updates.containsKey('primary_goal'))
                        ? true
                        : _userProfileModel!.isPersonalized,
      );
      
      notifyListeners();
      print('[UserProfileProvider] Local profile updated. isPersonalized: ${_userProfileModel!.isPersonalized}');
    }
  } catch (e, stackTrace) {
    print('[UserProfileProvider] Error updating profile: $e');
    print('[UserProfileProvider] Stack trace: $stackTrace');
    rethrow;
  }
}

Future<bool> updateSingleProfileField(Map<String, dynamic> fieldUpdate) async {
if (_userId == null) {
print("[UserProfileProvider] Cannot update field: User ID empty.");
return false;
}
if (fieldUpdate.isEmpty) {
print("[UserProfileProvider] No field update provided.");
return false;
}

if (_isDisposed) return false;
if (_isSaving) { print("[UserProfileProvider] Already saving, cannot update field(s) now."); return false;}
_isSaving = true;
notifyListeners();
print("[UserProfileProvider] Updating profile field(s): $fieldUpdate for user $_userId");

try {
  final Map<String, dynamic> payload = {
    ...fieldUpdate,
    'updated_at': DateTime.now().toIso8601String(),
  };
  await _supabaseClient.from('profiles').update(payload).eq('id', _userId!);

  print("[UserProfileProvider] Field(s) updated in Supabase. Reloading profile.");
  await loadUserProfile();
  if (!_isDisposed) {
     _isSaving = false;
     notifyListeners();
  } else {
     _isSaving = false;
  }
  return true;
} catch (e,s) {
  print("[UserProfileProvider] Error updating profile field(s): $e\n$s");
  if (!_isDisposed) {
    _userProfileModel = null; // Reset profile state
    _isSaving = false;
    notifyListeners();
  } else {
    _isSaving = false;
  }
  return false;
}
}

// --- ADD THIS NEW METHOD ---
bool canPerformScan() {
if (_userProfileModel == null) return false;

final profile = _userProfileModel!;
final tier = profile.membershipTier;
final count = profile.scanCount;

if (tier == 'free') {
  return (count ?? 0) < AppConstants.freeScanLimit;
}
if (tier == 'premium_monthly') {
  return (count ?? 0) < AppConstants.premiumMonthlyScanLimit;
}
if (tier == 'premium_yearly') {
  // For unlimited (-1), this check will always be true.
  // For a hard cap like 1000, it will work correctly.
  return AppConstants.premiumYearlyScanLimit == -1 || (count ?? 0) < AppConstants.premiumYearlyScanLimit;
}

// Default to false if tier is unknown
return false;
}
// --- END OF NEW METHOD ---

Future<void> incrementScanCountForFreeUser() async {
if (_isDisposed || _userProfileModel == null || _userId == null) {
  print("[UserProfileProvider incrementScanCount] Aborting: Disposed, no profile, or no user ID.");
  return;
}

final bool isPremium = _userProfileModel?.isPremium ?? false;
if (isPremium) {
  print("[UserProfileProvider incrementScanCount] User is premium. Membership: ${_userProfileModel!.membershipTier}. Skipping count increment.");
  return;
}

if ((_userProfileModel?.scanCount ?? 0) >= FREE_SCAN_LIMIT) {
  print("[UserProfileProvider incrementScanCount] Scan count already at/above limit: ${_userProfileModel!.scanCount}/$FREE_SCAN_LIMIT. Not incrementing.");
  return;
}

final int newScanCount = (_userProfileModel?.scanCount ?? 0) + 1;
final UserProfile originalProfileState = _userProfileModel!.copyWith();
_userProfileModel = _userProfileModel!.copyWith(scanCount: newScanCount);
if (!_isDisposed) notifyListeners();
print("[UserProfileProvider incrementScanCount] Optimistically incremented scan count for user $_userId to $newScanCount.");

try {
  await _supabaseClient
      .from('profiles')
      .update({
    'scan_count': newScanCount,
    'updated_at': DateTime.now().toIso8601String(),
  })
      .eq('id', _userId!);

  print("[UserProfileProvider incrementScanCount] Scan count successfully updated in Supabase to $newScanCount for user $_userId.");

  if (newScanCount >= FREE_SCAN_LIMIT) {
    print("[UserProfileProvider incrementScanCount] User $_userId reached $FREE_SCAN_LIMIT. Triggering backend propagation.");
    String? currentDeviceId = _userProfileModel?.deviceId;
    if (currentDeviceId == null || currentDeviceId.isEmpty) {
      print("[UserProfileProvider incrementScanCount] DeviceId not in profile model for propagation. Fetching fresh.");
      try {
        currentDeviceId = await DeviceInfoService.getDeviceId();
        if (currentDeviceId != null && currentDeviceId.isNotEmpty && _userId != null) {
          await _supabaseClient.from('profiles').update({'device_id': currentDeviceId}).eq('id', _userId!);
          if (!_isDisposed) {
            _userProfileModel = _userProfileModel?.copyWith(deviceId: currentDeviceId);
            notifyListeners();
          }
          print("[UserProfileProvider incrementScanCount] Updated missing deviceId to $currentDeviceId for propagation.");
        }
      } catch (e) {
        print("[UserProfileProvider incrementScanCount] Error fetching/updating deviceId for propagation: $e");
        currentDeviceId = null;
      }
    }

    if (currentDeviceId != null && currentDeviceId.isNotEmpty && _userId != null) {
      print("[UserProfileProvider incrementScanCount] Calling /api/auth/propagate-device-limit for device $currentDeviceId, triggered by user $_userId");
      http.post(
        Uri.parse('$_yourBackendBaseUrl/api/auth/propagate-device-limit'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userIdWhoHitLimit': _userId,
          'deviceId': currentDeviceId,
        }),
      ).then((propagationResponse) {
        if (!_isDisposed) {
          try {
            final propagationResponseBody = jsonDecode(propagationResponse.body);
            print("[UserProfileProvider incrementScanCount] propagate-device-limit response: ${propagationResponse.statusCode}, $propagationResponseBody");
          } catch (e) {
            print("[UserProfileProvider incrementScanCount] propagate-device-limit invalid JSON response: ${propagationResponse.statusCode}, ${propagationResponse.body}");
          }
        }
      }).catchError((e, s) {
        if (!_isDisposed) {
          print("[UserProfileProvider incrementScanCount] Exception calling propagate-device-limit: $e\n$s");
        }
      }).timeout(const Duration(seconds: 20), onTimeout: () {
        if (!_isDisposed) {
          print("[UserProfileProvider incrementScanCount] Timeout calling propagate-device-limit.");
        }
      });
    } else {
      print("[UserProfileProvider incrementScanCount] Cannot propagate device limit - userId or deviceId is missing after attempts.");
    }
  }
} catch (e) {
  print("[UserProfileProvider incrementScanCount] Error updating scan count in Supabase for user $_userId: $e");
  if (!_isDisposed) {
    _userProfileModel = originalProfileState;
    notifyListeners();
  }
}
}

/// --- THIS METHOD IS FOR UPDATING THE LOCAL COUNT AFTER A SUCCESSFUL API CALL ---
void incrementAskExpertCount() {
if (_userProfileModel == null) return;
// This updates the local state. The backend already updated the database.
_userProfileModel = _userProfileModel!.copyWith(
    askExpertCount: (_userProfileModel!.askExpertCount ?? 0) + 1
);
notifyListeners();
}

void incrementPersonalizedGuideCount() {
if (_userProfileModel == null) return;
_userProfileModel = _userProfileModel!.copyWith(
    personalizedGuideCount: (_userProfileModel!.personalizedGuideCount ?? 0) + 1
);
notifyListeners();
}

/// --- THIS METHOD IS FOR UPDATING THE LOCAL COUNT AFTER A SUCCESSFUL API CALL ---
void incrementManualSearchCount() {
if (_userProfileModel == null) return;
_userProfileModel = _userProfileModel!.copyWith(
    manualSearchCount: (_userProfileModel!.manualSearchCount ?? 0) + 1
);
notifyListeners();
}

// NEW: Pregnancy Tools increment methods
void incrementLmpCalculatorCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    lmpCalculatorCount: (_userProfileModel!.lmpCalculatorCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementDueDateCalculatorCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    dueDateCalculatorCount: (_userProfileModel!.dueDateCalculatorCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementTtcCalculatorCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    ttcCalculatorCount: (_userProfileModel!.ttcCalculatorCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementBabyNameGeneratorCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    babyNameGeneratorCount: (_userProfileModel!.babyNameGeneratorCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementKickCounterSessions() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    kickCounterSessions: (_userProfileModel!.kickCounterSessions ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementContractionTimerSessions() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    contractionTimerSessions: (_userProfileModel!.contractionTimerSessions ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementDocumentAnalysisCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    documentAnalysisCount: (_userProfileModel!.documentAnalysisCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementWeightGainTrackerCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    weightGainTrackerCount: (_userProfileModel!.weightGainTrackerCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementAppointmentSchedulerCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    appointmentSchedulerCount: (_userProfileModel!.appointmentSchedulerCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

// NEW: Advanced Features increment methods
void incrementFertilityTrackerCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    fertilityTrackerCount: (_userProfileModel!.fertilityTrackerCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementPostpartumTrackerCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    postpartumTrackerCount: (_userProfileModel!.postpartumTrackerCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementMentalHealthAssessments() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    mentalHealthAssessments: (_userProfileModel!.mentalHealthAssessments ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

void incrementNutritionPlanningCount() {
if (_userProfileModel != null) {
  _userProfileModel = _userProfileModel!.copyWith(
    nutritionPlanningCount: (_userProfileModel!.nutritionPlanningCount ?? 0) + 1,
  );
  _updateUserProfile(_userProfileModel!);
}
}

// Helper method to update profile (add if not exists)
Future<void> _updateUserProfile(UserProfile updatedProfile) async {
try {
  // Update in Supabase
  await _supabaseClient
      .from('profiles')
      .update(updatedProfile.toJson())
      .eq('user_id', updatedProfile.id);

  // Update state
  _userProfileModel = updatedProfile;
  notifyListeners();
} catch (e) {
  // Handle error - maybe just update locally
  _userProfileModel = updatedProfile;
  notifyListeners();
}
}

Future<bool> saveUserProfile({
required String name,
String? newTrimester,
String? newDiet,
}) async {
if (_userId == null) {
  print("[UserProfileProvider saveUserProfile] Cannot save - User ID empty.");
  return false;
}

if (_isSaving) {
  print("[UserProfileProvider saveUserProfile] Save in progress, cannot save now.");
  return false;
}

_isSaving = true;
if (!_isDisposed) notifyListeners();

print("[UserProfileProvider saveUserProfile] For user $_userId...");

try {
  final Map<String, dynamic> dataToSaveForProfiles = {
    'updated_at': DateTime.now().toIso8601String(),
    'full_name': name,
    'selected_trimx': newTrimester ?? _userProfileModel?.selectedTrimester,
    'dietary_preference': newDiet ?? _userProfileModel?.dietaryPreference,
    'primary_goal': _userProfileModel?.primaryGoal,
    'known_allergies': _knownAllergies.isNotEmpty ? _knownAllergies : null,
    'custom_allergies': _customAllergiesText.isEmpty ? null : _customAllergiesText,
    'profile_image_url': _profileImageUrl.isEmpty ? null : _profileImageUrl,
    'language_pref': _languagePreference,
    'email_notifications_enabled': _emailNotificationsEnabled,
    'data_sharing_consent': _dataSharingEnabled,
    'mobile_number': _mobileNumber,
    'country_code': _countryCode,
    'is_phone_verified': _isPhoneVerified,
  };
  
  dataToSaveForProfiles.removeWhere((key, value) => value == null && !['custom_allergies', 'profile_image_url', 'known_allergies', 'language_pref', 'mobile_number', 'country_code', 'dietary_preference'].contains(key));

  print("[UserProfileProvider saveUserProfile] Data to profiles.update: $dataToSaveForProfiles");

  await _supabaseClient
      .from('profiles')
      .update(dataToSaveForProfiles)
      .eq('id', _userId!);

  print("[UserProfileProvider saveUserProfile] Supabase profiles.update FINISHED.");

  final String comprehensiveSelectQuery = '''
    id, full_name, email, mobile_number, country_code, is_phone_verified,
    profile_image_url, selected_trimx, dietary_preference, known_allergies,
    custom_allergies, language_pref, email_notifications_enabled, due_date,
    data_sharing_consent, role, membership_tier, scan_count, last_share_timestamp,
    device_id, premium_expiry_date, is_pro_member, daily_scan_limit_reset_at,
    primary_goal, created_at, updated_at, ask_expert_count, personalized_guide_count,
    manual_search_count, lmp_calculator_count, due_date_calculator_count,
    ttc_calculator_count, baby_name_generator_count, kick_counter_sessions,
    contraction_timer_sessions, document_analysis_count, weight_gain_tracker_count,
    appointment_scheduler_count, fertility_tracker_count, postpartum_tracker_count,
    mental_health_assessments, nutrition_planning_count
  ''';

  final updatedProfileDataFromDb = await _supabaseClient
      .from('profiles')
      .select(comprehensiveSelectQuery)
      .eq('id', _userId!)
      .maybeSingle();

  if (_isDisposed) return false;

  if (updatedProfileDataFromDb != null && updatedProfileDataFromDb.isNotEmpty) {
    print("[UserProfileProvider saveUserProfile] Data fetched IMMEDIATELY after update: $updatedProfileDataFromDb");
    _userProfileModel = UserProfile.fromMap(updatedProfileDataFromDb);
    _updateLocalStateFromModel(_userProfileModel!);

    if (_userId != null) {
      _userPregnancyDetails = await _pregnancyDetailsService.getPregnancyDetails(_userId!);
      if (_isDisposed) return false;
      print("[UserProfileProvider saveUserProfile] Pregnancy details after save: ${_userPregnancyDetails?.dueDate != null ? DateFormat('yyyy-MM-dd').format(_userPregnancyDetails!.dueDate!) : 'null'}");
    } else {
      _userPregnancyDetails = null;
    }
  } else {
    print("[UserProfileProvider saveUserProfile] FAILED to fetch profile immediately after update or response was empty. This is problematic.");
  }

  if (!_isDisposed) {
    _isSaving = false;
    __isUserProfileLoaded = true;
    _isLoading = false;
    notifyListeners();
  }
  print("[UserProfileProvider saveUserProfile] Process complete. isPersonalized: $isPersonalized");
  return true;
} catch (e, s) {
  print("[UserProfileProvider saveUserProfile] Error: $e\n$s");
  _isSaving = false;
  if (!_isDisposed) {
    _isLoading = false;
    notifyListeners();
  }
  return false;
}
}

Future<bool> savePreferences({
String? trimesterString,
String? dietPreferenceString,
Set<String>? allergies,
String? otherAllergies,
String? primaryGoalString,
}) async {
if (_userId == null) {
  print("[UserProfileProvider] Cannot save preferences - User not logged in or provider not initialized.");
  return false;
}

if (_isSaving) {
  print("[UserProfileProvider] Save in progress, cannot save preferences.");
  return false;
}

if (_isDisposed) return false;
_isSaving = true;
notifyListeners();

print("[UserProfileProvider] Saving preferences for user $_userId...");

try {
  Map<String, dynamic> dataToUpdate = {
    'updated_at': DateTime.now().toIso8601String(),
  };

  if (trimesterString != null) {
    dataToUpdate['selected_trimx'] = trimesterString == TrimesterOption.none.toSupabaseString() || trimesterString.isEmpty ? null : trimesterString;
  }

  if (dietPreferenceString != null) {
    dataToUpdate['dietary_preference'] = dietPreferenceString == DietaryPreferenceOption.none.toSupabaseString() || dietPreferenceString.isEmpty ? null : dietPreferenceString;
  }

  if (allergies != null) {
    dataToUpdate['known_allergies'] = allergies.toList().isEmpty ? null : allergies.toList();
  }

  if (otherAllergies != null) {
    dataToUpdate['custom_allergies'] = otherAllergies.isEmpty ? null : otherAllergies;
  }

  if (primaryGoalString != null) {
    dataToUpdate['primary_goal'] = primaryGoalString == UserGoalOption.none.toSupabaseString() || primaryGoalString.isEmpty ? null : primaryGoalString;
  }

  if (dataToUpdate.length > 1) {
    await _supabaseClient
        .from('profiles')
        .update(dataToUpdate)
        .eq('id', _userId!);

    await loadUserProfile();
    if (!_isDisposed) {
      _isSaving = false;
      notifyListeners();
    } else {
      _isSaving = false;
    }
    print("[UserProfileProvider] Preferences saved successfully, and full profile reloaded.");
    print("[UserProfileProvider SavePreferences] Updated model via reload - trimester:${_userProfileModel?.selectedTrimester}, diet:${_userProfileModel?.dietaryPreference}, isPersonalized:$isPersonalized");
  } else {
    print("[UserProfileProvider] No new preference data to save.");
    if (!_isDisposed) {
      _isSaving = false;
      notifyListeners();
    }
  }
  return true;
} catch (e, s) {
  print("[UserProfileProvider] Error saving preferences: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}

Future<void> updateUserToPremium(String membershipType, String expiryDateString) async {
try {
  if (_userId == null) {
    print("[UserProfileProvider] Cannot update to premium - User ID is null.");
    return;
  }

  if (_isDisposed) return;
  print("[UserProfileProvider] Attempting to update user $_userId to premium. Membership: $membershipType, Expiry: $expiryDateString");

  // Convert string back to DateTime for processing
  final expiryDate = DateTime.parse(expiryDateString);

  // Update the user profile with premium status
  await _supabaseClient
      .from('profiles')
      .update({
    'membership_tier': membershipType,
    'premium_expiry_date': expiryDate.toIso8601String(),
    'is_pro_member': true,
    'updated_at': DateTime.now().toIso8601String(),
  })
      .eq('id', _userId!);

  print("[UserProfileProvider] Successfully updated user $_userId to premium membership: $membershipType");

  // Reload user profile after update
  await loadUserProfile();
  print("[UserProfileProvider] Profile reloaded after premium upgrade. New tier: ${_userProfileModel?.membershipTier}");
} catch (e) {
  print("[UserProfileProvider] Error updating user to premium: $e");
  rethrow;
}
}

Future<bool> updateDataSharingPreference(bool isEnabled) async {
if (_userId == null) {
  print("[UserProfileProvider] Cannot update data sharing - User ID empty.");
  return false;
}
if (_isSaving) {
  print("[UserProfileProvider] Save in progress, cannot update data sharing.");
  return false;
}
if (_isDisposed) return false;
_isSaving = true;
notifyListeners();

try {
  await _supabaseClient.from('profiles').update({
    'data_sharing_consent': isEnabled,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', _userId!);

  await loadUserProfile();
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  } else {
    _isSaving = false;
  }
  print("[UserProfileProvider] Data sharing preference updated to $isEnabled. Full profile reloaded.");
  return true;
} catch (e, s) {
  print("[UserProfileProvider] Error updating data sharing preference: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}

Future<bool> uploadAndSaveProfilePicture(XFile imageFile) async {
if (_userId == null) {
  print("[UserProfileProvider] Cannot upload image - User ID empty.");
  return false;
}

if (_isSaving) {
  print("[UserProfileProvider] Another save/upload operation in progress.");
  return false;
}
if (_isDisposed) return false;
_isSaving = true;
notifyListeners();

print("[UserProfileProvider] Uploading profile picture for user $_userId...");

try {
  final fileExtension = imageFile.path.split('.').last.toLowerCase();
  final imagePath = 'public/$_userId.$fileExtension';
  final bytes = await imageFile.readAsBytes();

  await _supabaseClient.storage.from('profile-pictures').uploadBinary(
    imagePath,
    bytes,
    fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
  );

  final String publicUrl = _supabaseClient.storage.from('profile-pictures').getPublicUrl(imagePath);
  print("[UserProfileProvider] Image uploaded. Public URL: $publicUrl");

  await _supabaseClient.from('profiles').update({
    'profile_image_url': publicUrl,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', _userId!);

  await loadUserProfile();
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  } else {
    _isSaving = false;
  }
  print("[UserProfileProvider] Profile image URL updated in DB. Full profile reloaded.");
  return true;
} catch (e, s) {
  print("[UserProfileProvider] Error uploading profile picture: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}

Future<bool> updateUserLanguagePreference(String newLanguageCode) async {
if (_userId == null) {
  print("[UserProfileProvider] Cannot update language - User ID empty.");
  return false;
}
if (_isSaving) {
  print("[UserProfileProvider] Already saving, cannot update language now.");
  return false;
}
if (_isDisposed) return false;
_isSaving = true;
notifyListeners();

try {
  await _supabaseClient.from('profiles').update({
    'language_pref': newLanguageCode,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', _userId!);

  await loadUserProfile();
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  } else {
    _isSaving = false;
  }
  print("[UserProfileProvider] Language preference updated to $newLanguageCode. Full profile reloaded.");
  return true;
} catch (e, s) {
  print("[UserProfileProvider] Error updating language preference: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}

Future<bool> updateUserProfileImage(String imageUrl) async {
if (_userId == null) {
  print("[UserProfileProvider] Cannot update image - User ID empty.");
  return false;
}
if (_isSaving) {
  print("[UserProfileProvider] Save in progress, cannot update image URL.");
  return false;
}
if (_isDisposed) return false;
_isSaving = true;
notifyListeners();

print("[UserProfileProvider] Updating profile image URL directly (not uploading file) for user $_userId...");

try {
  await _supabaseClient.from('profiles').update({
    'profile_image_url': imageUrl.isEmpty ? null : imageUrl,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', _userId!);

  await loadUserProfile();
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  } else {
    _isSaving = false;
  }
  print("[UserProfileProvider] Profile image URL updated successfully via direct URL set. Full profile reloaded.");
  return true;
} catch (e, s) {
  print("[UserProfileProvider] Error updating profile image URL directly: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}

void updateLocalProfile(UserProfile newProfile) {
if (_isDisposed) return;
_userProfileModel = newProfile;
if (newProfile.email != null && _email != newProfile.email) {
  _updateLocalStateFromModel(newProfile);
}
print("[UserProfileProvider] Local UserProfileModel instance and fields updated.");
notifyListeners();
}

Future<void> clearHistory() async {
if (_userId == null) {
  print("[UserProfileProvider] Cannot clear history - User ID empty.");
  return;
}
if (_isDisposed) return;
if (_isSaving) {
  print("[UserProfileProvider] Save in progress, cannot clear history.");
  return;
}
_isSaving = true;
notifyListeners();

print("[UserProfileProvider] Clear history request for user $_userId. Actual logic depends on feature.");
await Future.delayed(const Duration(milliseconds: 100));

if (!_isDisposed) {
  _isSaving = false;
  notifyListeners();
}
}

DietaryPreference? _parseDietaryPreference(String? value) {
if (value == null) return null;

switch (value.trim().toLowerCase().replaceAll('-', '')) {
  case 'vegetarian':
    return DietaryPreference.vegetarian;
  case 'nonveg':
  case 'non_veg':
    return DietaryPreference.nonVeg;
  case 'vegan':
    return DietaryPreference.vegan;
  case 'none':
    return null;
  default:
    print("[UserProfileProvider] Unknown dietary preference value for enum parsing: $value");
    return null;
}
}

Future<bool> updateUserDueDate(DateTime? dueDate) async {
if (_userId == null) {
  print("[UserProfileProvider updateUserDueDate] Cannot update due date - User ID is null.");
  return false;
}

if (_isSaving) {
  print("[UserProfileProvider updateUserDueDate] Already saving, cannot update due date now.");
  return false;
}

if (_isDisposed) return false;
_isSaving = true;
notifyListeners();

print("[UserProfileProvider updateUserDueDate] Updating due date to ${dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate) : 'null'} for user $_userId via PregnancyDetailsService...");

try {
  final updatedDetails = await _pregnancyDetailsService.upsertPregnancyDetails(
    userId: _userId!,
    dueDate: dueDate,
  );

  if (_isDisposed) return false;

  if (updatedDetails != null) {
    _userPregnancyDetails = updatedDetails;
    print("[UserProfileProvider] Due date updated successfully via service: ${_userPregnancyDetails?.dueDate != null ? DateFormat('yyyy-MM-dd').format(_userPregnancyDetails!.dueDate!) : 'null'}");
    _isSaving = false;
    notifyListeners();
    return true;
  } else {
    print("[UserProfileProvider] Due date update via service returned null.");
    _isSaving = false;
    notifyListeners();
    return false;
  }
} catch (e, s) {
  print("[UserProfileProvider] Error updating due date via service: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}

Future<bool> updateUserPhoneAndVerificationStatus({
required String mobileNumber,
required String countryCode,
required bool isPhoneVerified,
}) async {
if (_userId == null) {
  print("[UserProfileProvider] No user ID for phone update.");
  return false;
}
if (_isDisposed) return false;
if (_isSaving) {
  print("[UserProfileProvider] Save in progress, cannot update phone.");
  return false;
}
_isSaving = true;
notifyListeners();

try {
  final Map<String, dynamic> dataToUpdate = {
    'mobile_number': mobileNumber,
    'country_code': countryCode,
    'is_phone_verified': isPhoneVerified,
    'updated_at': DateTime.now().toIso8601String(),
  };

  await _supabaseClient
      .from('profiles')
      .update(dataToUpdate)
      .eq('id', _userId!);

  await loadUserProfile();
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  } else {
    _isSaving = false;
  }
  print("[UserProfileProvider] User profile phone & verification status updated in Supabase, and full profile reloaded.");
  return true;
} catch (e, s) {
  print("[UserProfileProvider] Error updating user phone & verification status: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}

Future<bool> updateEmailNotificationPreference(bool isEnabled) async {
if (_userId == null) {
  print("[UserProfileProvider] Cannot update email pref - User ID empty.");
  return false;
}
if (_isSaving) {
  print("[UserProfileProvider] Save in progress, cannot update email pref.");
  return false;
}
if (_isDisposed) return false;
_isSaving = true;
notifyListeners();

try {
  await _supabaseClient.from('profiles').update({
    'email_notifications_enabled': isEnabled,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', _userId!);

  await loadUserProfile();
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  } else {
    _isSaving = false;
  }
  print("[UserProfileProvider] Email notification preference updated to $isEnabled. Full profile reloaded.");
  return true;
} catch (e, s) {
  print("[UserProfileProvider] Error updating email notification preference: $e\n$s");
  if (!_isDisposed) {
    _isSaving = false;
    notifyListeners();
  }
  return false;
}
}
}

// Provider definition
final userProfileProvider = ChangeNotifierProvider<UserProfileProvider>((ref) {
final localeProvider = ref.read(localeNotifierProvider.notifier);
return UserProfileProvider(localeProvider, ref);
});
