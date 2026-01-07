// lib/features/auth/screens/personalize_allergies_screen.dart
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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- Enums and Extensions remain the same ---
enum KnownAllergy { nuts, dairy, gluten, soy, seafood, eggs }

extension KnownAllergyExtensions on KnownAllergy {
  String toSupabaseString() => name;
}

final selectedKnownAllergiesProvider = StateProvider<List<KnownAllergy>>((ref) => []);
final customAllergiesTextProvider = StateProvider<String>((ref) => '');

// <<< ENTIRE WIDGET REDESIGNED >>>
class PersonalizeAllergiesScreen extends ConsumerWidget {
  const PersonalizeAllergiesScreen({super.key});

  String _getKnownAllergyDisplayName(BuildContext context, KnownAllergy allergy) {
    final S = AppLocalizations.of(context)!;
    switch (allergy) {
      case KnownAllergy.nuts: return S.allergyNuts;
      case KnownAllergy.dairy: return S.allergyDairy;
      case KnownAllergy.gluten: return S.allergyGluten;
      case KnownAllergy.soy: return S.allergySoy;
      case KnownAllergy.seafood: return S.allergySeafood;
      case KnownAllergy.eggs: return S.allergyEggs;
    }
  }

  IconData _getAllergyIcon(KnownAllergy allergy) {
    switch (allergy) {
      case KnownAllergy.nuts: return FontAwesomeIcons.pagelines; // Represents peanuts
      case KnownAllergy.dairy: return FontAwesomeIcons.cheese;
      case KnownAllergy.gluten: return FontAwesomeIcons.breadSlice;
      case KnownAllergy.soy: return FontAwesomeIcons.leaf;
      case KnownAllergy.seafood: return FontAwesomeIcons.shrimp;
      case KnownAllergy.eggs: return FontAwesomeIcons.egg;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final selectedAllergies = ref.watch(selectedKnownAllergiesProvider);
    final customAllergiesController = TextEditingController(text: ref.watch(customAllergiesTextProvider));
    customAllergiesController.addListener(() {
      if (ref.exists(customAllergiesTextProvider) && ref.read(customAllergiesTextProvider.notifier).state != customAllergiesController.text) {
          ref.read(customAllergiesTextProvider.notifier).state = customAllergiesController.text;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        title: Text(S.knownAllergiesTitle, style: textTheme.titleLarge?.copyWith(color: AppColors.textDark)),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // <<< CHANGED: Using the new shared widget
              const ProgressIndicatorBar(currentStep: 3, totalSteps: 4),
              const SizedBox(height: 24),
              Text(
                S.anyKnownFoodAllergiesQuestion,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                S.helpsProvideSaferRecommendations,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView( // Use ListView to contain GridView and TextFormField
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.4, // Adjust for card size
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: KnownAllergy.values.length,
                      itemBuilder: (context, index) {
                        final allergy = KnownAllergy.values[index];
                        final isSelected = selectedAllergies.contains(allergy);
                        return _AllergyCard(
                          title: _getKnownAllergyDisplayName(context, allergy),
                          icon: _getAllergyIcon(allergy),
                          isSelected: isSelected,
                          onTap: () {
                            final currentList = List<KnownAllergy>.from(selectedAllergies);
                            if (isSelected) {
                              currentList.remove(allergy);
                            } else {
                              currentList.add(allergy);
                            }
                            ref.read(selectedKnownAllergiesProvider.notifier).state = currentList;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: customAllergiesController,
                      decoration: InputDecoration(
                        labelText: S.otherAllergiesLabel,
                        hintText: S.otherAllergiesHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                      ),
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: CustomElevatedButton(
                  text: S.continueButton,
                  onPressed: () {
                    final knownAllergiesList = ref.read(selectedKnownAllergiesProvider);
                    final customAllergies = ref.read(customAllergiesTextProvider);
                    ref.read(registrationDataProvider.notifier).updateAllergies(known: knownAllergiesList, custom: customAllergies);
                    context.push(AppRouter.personalizeGoalPath);
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

// --- NEW REUSABLE WIDGET FOR ALLERGY CARDS ---
// This widget is local to this file and remains unchanged.
class _AllergyCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AllergyCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.greyLight,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 32, color: isSelected ? AppColors.primary : AppColors.textMedium),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}