// lib/features/auth/screens/personalize_diet_screen.dart
import 'package:safemama/features/auth/providers/registration_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/constants/app_colors.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/widgets/custom_button.dart';
import 'package:safemama/l10n/app_localizations.dart';
// <<< NEW: Import the shared widgets
import 'package:safemama/features/auth/widgets/personalization_widgets.dart';

// --- Enums and Extensions remain the same, they are correct ---
enum DietaryPreferenceOption { nonVegetarian, vegetarian, vegan, pescatarian, none }

extension DietaryPreferenceOptionExtension on DietaryPreferenceOption {
  String toSupabaseString() {
    switch (this) {
      case DietaryPreferenceOption.nonVegetarian: return 'non_vegetarian';
      case DietaryPreferenceOption.vegetarian: return 'vegetarian';
      case DietaryPreferenceOption.vegan: return 'vegan';
      case DietaryPreferenceOption.pescatarian: return 'pescatarian';
      default: return 'none';
    }
  }
  static DietaryPreferenceOption fromSupabaseString(String? value) {
    switch (value) {
      case 'non_vegetarian': return DietaryPreferenceOption.nonVegetarian;
      case 'vegetarian': return DietaryPreferenceOption.vegetarian;
      case 'vegan': return DietaryPreferenceOption.vegan;
      case 'pescatarian': return DietaryPreferenceOption.pescatarian;
      default: return DietaryPreferenceOption.none;
    }
  }
}

final selectedDietaryPreferenceProvider = StateProvider<DietaryPreferenceOption>((ref) => DietaryPreferenceOption.none);

// <<< ENTIRE WIDGET REDESIGNED >>>
class PersonalizeDietScreen extends ConsumerWidget {
  const PersonalizeDietScreen({super.key});

  String _getDietDisplayName(BuildContext context, DietaryPreferenceOption option) {
    final S = AppLocalizations.of(context)!;
    switch (option) {
      case DietaryPreferenceOption.nonVegetarian: return S.dietNonVegetarian;
      case DietaryPreferenceOption.vegetarian: return S.dietVegetarian;
      case DietaryPreferenceOption.vegan: return S.dietVegan;
      case DietaryPreferenceOption.pescatarian: return S.dietPescatarian;
      default: return "";
    }
  }

  IconData _getDietIcon(DietaryPreferenceOption option) {
    switch (option) {
      case DietaryPreferenceOption.nonVegetarian: return Icons.egg_alt_outlined;
      case DietaryPreferenceOption.vegetarian: return Icons.grass;
      case DietaryPreferenceOption.vegan: return Icons.local_florist_outlined;
      case DietaryPreferenceOption.pescatarian: return Icons.phishing_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final currentSelectedDiet = ref.watch(selectedDietaryPreferenceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        title: Text(S.dietaryPreferencesTitle, style: textTheme.titleLarge?.copyWith(color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: <Widget>[
              // <<< CHANGED: Using the new shared widget
              const ProgressIndicatorBar(currentStep: 2, totalSteps: 4),
              const SizedBox(height: 24),
              Text(
                S.whatAreYourDietaryPreferencesQuestion,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: DietaryPreferenceOption.values
                      .where((d) => d != DietaryPreferenceOption.none)
                      // <<< CHANGED: Using the new shared widget
                      .map((diet) => PersonalizationSelectionCard( 
                        title: _getDietDisplayName(context, diet),
                        subtitle: "Recommendations will be tailored.", // Generic subtitle
                        icon: _getDietIcon(diet),
                        isSelected: currentSelectedDiet == diet,
                        onTap: () => ref.read(selectedDietaryPreferenceProvider.notifier).state = diet,
                      )).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: CustomElevatedButton(
                  text: S.continueButton,
                  onPressed: currentSelectedDiet == DietaryPreferenceOption.none
                      ? null
                      : () {
                          ref.read(registrationDataProvider.notifier).updateDiet(currentSelectedDiet);
                          context.push(AppRouter.personalizeAllergiesPath);
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}