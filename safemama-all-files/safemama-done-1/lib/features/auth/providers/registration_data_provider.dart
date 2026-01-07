// lib/features/auth/providers/registration_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart'; // Added for Country object
import 'package:safemama/features/auth/screens/personalize_trimester_screen.dart'; // For TrimesterOption
import 'package:safemama/features/auth/screens/personalize_diet_screen.dart'; // For DietaryPreferenceOption
import 'package:safemama/features/auth/screens/personalize_allergies_screen.dart'; // For KnownAllergy
import 'package:safemama/features/auth/screens/personalize_goal_screen.dart'; // For UserGoalOption

class RegistrationData {
  // Personalization Data
  final TrimesterOption trimester;
  final DietaryPreferenceOption diet;
  final List<KnownAllergy> knownAllergies;
  final String customAllergies;
  final UserGoalOption goal;

  // Account Creation Data (from form)
  String fullName;
  String email;
  String password;
  String? mobileNumber;
  Country? selectedCountry; // Store the whole Country object
  bool agreedToTerms;

  // New fields based on the prompt's requirements for raw_user_meta_data
  final bool isPhoneVerified;
  final String languagePref;
  final bool emailNotifications;
  final bool dataSharingConsent;
  // profile_image_url will be set directly in the metadata map as null for now

  RegistrationData({
    this.trimester = TrimesterOption.none,
    this.diet = DietaryPreferenceOption.none,
    this.knownAllergies = const [],
    this.customAllergies = '',
    this.goal = UserGoalOption.none,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.mobileNumber,
    this.selectedCountry,
    this.agreedToTerms = false,
    this.isPhoneVerified = false, // Default value
    this.languagePref = 'en',     // Default value
    this.emailNotifications = true, // Default value
    this.dataSharingConsent = false, // Default value
  });

  RegistrationData copyWith({
    TrimesterOption? trimester,
    DietaryPreferenceOption? diet,
    List<KnownAllergy>? knownAllergies,
    String? customAllergies,
    UserGoalOption? goal,
    String? fullName,
    String? email,
    String? password,
    String? mobileNumber,
    Country? selectedCountry,
    bool? agreedToTerms,
    bool? isPhoneVerified,
    String? languagePref,
    bool? emailNotifications,
    bool? dataSharingConsent,
    bool clearMobile = false,
  }) {
    return RegistrationData(
      trimester: trimester ?? this.trimester,
      diet: diet ?? this.diet,
      knownAllergies: knownAllergies ?? this.knownAllergies,
      customAllergies: customAllergies ?? this.customAllergies,
      goal: goal ?? this.goal,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      mobileNumber: clearMobile ? null : mobileNumber ?? this.mobileNumber,
      selectedCountry: clearMobile ? null : selectedCountry ?? this.selectedCountry,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      languagePref: languagePref ?? this.languagePref,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      dataSharingConsent: dataSharingConsent ?? this.dataSharingConsent,
    );
  }
}

class RegistrationDataNotifier extends StateNotifier<RegistrationData> {
  RegistrationDataNotifier() : super(RegistrationData());

  void updateTrimester(TrimesterOption trimester) => state = state.copyWith(trimester: trimester);
  void updateDiet(DietaryPreferenceOption diet) => state = state.copyWith(diet: diet);
  void updateAllergies({List<KnownAllergy>? known, String? custom}) =>
      state = state.copyWith(knownAllergies: known ?? state.knownAllergies, customAllergies: custom ?? state.customAllergies);
  void updateGoal(UserGoalOption goal) => state = state.copyWith(goal: goal);

  void updateFormField({
    String? fullName,
    String? email,
    String? password,
    String? mobileNumber,
    Country? selectedCountry,
    bool? agreedToTerms,
    bool? emailNotifications,
    bool? dataSharing,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      password: password,
      mobileNumber: mobileNumber,
      selectedCountry: selectedCountry,
      agreedToTerms: agreedToTerms,
      emailNotifications: emailNotifications,
      dataSharingConsent: dataSharing,
    );
  }

  // Add this method to RegistrationDataNotifier class
  void reset() {
    state = RegistrationData(); // Reset to default values
  }

  // ===================================================================
  // ================ THIS IS THE CORRECTED FUNCTION ===================
  // ===================================================================
  Map<String, dynamic> getFullSignupMetaDataForSupabaseTrigger() {
    final currentState = state;

    final Map<String, dynamic> metaData = {
      'full_name': currentState.fullName.trim(),
      'country_code': currentState.selectedCountry?.countryCode,
      'country_name': currentState.selectedCountry?.name,
      
      // Correctly use the extension methods for enums
      'selected_trimester': currentState.trimester.toSupabaseString(),
      'dietary_preference': currentState.diet.toSupabaseString(),
      'known_allergies': currentState.knownAllergies.map((a) => a.toSupabaseString()).toList(),
      'custom_allergies': currentState.customAllergies.trim(),
      'primary_goal': currentState.goal.toSupabaseString(),

      // Other fields from RegistrationData state
      'language_pref': currentState.languagePref,
      'email_notifications': currentState.emailNotifications,
      'data_sharing': currentState.dataSharingConsent,

      // === THE CRITICAL FIX ===
      // We explicitly add the mobile number from the state.
      // If it's null, the key will still be present with a null value,
      // which is fine for the database trigger.
      'mobile_number': currentState.mobileNumber?.trim(),
    };

    // We no longer need to remove nulls, as Supabase handles them gracefully.
    // This was the source of the problem.
    // metaData.removeWhere((key, value) => value == null); // REMOVED

    print("[RegProvider] Metadata for Supabase trigger: $metaData");
    return metaData;
  }
}


// The global provider instance
final registrationDataProvider =
    StateNotifierProvider<RegistrationDataNotifier, RegistrationData>((ref) {
  print("[ProvidersFile/RegDataFile] CREATING RegistrationDataNotifier instance."); // Log creation
  return RegistrationDataNotifier();
});
