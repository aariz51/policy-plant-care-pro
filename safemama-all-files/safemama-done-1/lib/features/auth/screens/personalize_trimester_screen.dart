// lib/features/auth/screens/personalize_trimester_screen.dart
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
enum TrimesterOption {
  first,
  second,
  third,
  planningOrEarly,
  none
}

extension TrimesterOptionExtension on TrimesterOption {
  String toSupabaseString() {
    switch (this) {
      case TrimesterOption.first: return 'first';
      case TrimesterOption.second: return 'second';
      case TrimesterOption.third: return 'third';
      case TrimesterOption.planningOrEarly: return 'planning_or_early';
      default: return 'none';
    }
  }
  static TrimesterOption fromSupabaseString(String? value) {
    switch (value) {
      case 'first': return TrimesterOption.first;
      case 'second': return TrimesterOption.second;
      case 'third': return TrimesterOption.third;
      case 'planning_or_early': return TrimesterOption.planningOrEarly;
      default: return TrimesterOption.none;
    }
  }
}

final selectedTrimesterProvider = StateProvider<TrimesterOption>((ref) => TrimesterOption.none);

// <<< ENTIRE WIDGET REDESIGNED FOR A BETTER LOOK AND FEEL >>>
class PersonalizeTrimesterScreen extends ConsumerWidget {
  const PersonalizeTrimesterScreen({super.key});

  String _getTrimesterDisplayName(BuildContext context, TrimesterOption option) {
    final S = AppLocalizations.of(context)!;
    switch (option) {
      case TrimesterOption.first: return S.trimesterFirst;
      case TrimesterOption.second: return S.trimesterSecond;
      case TrimesterOption.third: return S.trimesterThird;
      case TrimesterOption.planningOrEarly: return S.trimesterPlanningOrEarly;
      default: return "";
    }
  }

  String _getTrimesterWeeks(BuildContext context, TrimesterOption option) {
    final S = AppLocalizations.of(context)!;
    switch (option) {
      case TrimesterOption.first: return S.trimester1stWeeks;
      case TrimesterOption.second: return S.trimester2ndWeeks;
      case TrimesterOption.third: return S.trimester3rdWeeks;
      case TrimesterOption.planningOrEarly: return "Let's get started!"; // Custom subtitle
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final currentSelectedTrimester = ref.watch(selectedTrimesterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt, // Softer background color
      appBar: AppBar(
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
              const ProgressIndicatorBar(currentStep: 1, totalSteps: 4),
              const SizedBox(height: 24),
              Text(
                S.whichTrimesterQuestion,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "This helps us tailor guidance for you.", // Add this to l10n later if needed
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // <<< CHANGED: Using the new shared widget
                      PersonalizationSelectionCard(
                        title: _getTrimesterDisplayName(context, TrimesterOption.first),
                        subtitle: _getTrimesterWeeks(context, TrimesterOption.first),
                        icon: Icons.filter_1_rounded,
                        isSelected: currentSelectedTrimester == TrimesterOption.first,
                        onTap: () => ref.read(selectedTrimesterProvider.notifier).state = TrimesterOption.first,
                      ),
                      // <<< CHANGED: Using the new shared widget
                      PersonalizationSelectionCard(
                        title: _getTrimesterDisplayName(context, TrimesterOption.second),
                        subtitle: _getTrimesterWeeks(context, TrimesterOption.second),
                        icon: Icons.filter_2_rounded,
                        isSelected: currentSelectedTrimester == TrimesterOption.second,
                        onTap: () => ref.read(selectedTrimesterProvider.notifier).state = TrimesterOption.second,
                      ),
                      // <<< CHANGED: Using the new shared widget
                      PersonalizationSelectionCard(
                        title: _getTrimesterDisplayName(context, TrimesterOption.third),
                        subtitle: _getTrimesterWeeks(context, TrimesterOption.third),
                        icon: Icons.filter_3_rounded,
                        isSelected: currentSelectedTrimester == TrimesterOption.third,
                        onTap: () => ref.read(selectedTrimesterProvider.notifier).state = TrimesterOption.third,
                      ),
                      // <<< CHANGED: Using the new shared widget
                      PersonalizationSelectionCard(
                        title: _getTrimesterDisplayName(context, TrimesterOption.planningOrEarly),
                        subtitle: _getTrimesterWeeks(context, TrimesterOption.planningOrEarly),
                        icon: Icons.egg_outlined,
                        isSelected: currentSelectedTrimester == TrimesterOption.planningOrEarly,
                        onTap: () => ref.read(selectedTrimesterProvider.notifier).state = TrimesterOption.planningOrEarly,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: CustomElevatedButton(
                  text: S.continueButton,
                  onPressed: currentSelectedTrimester == TrimesterOption.none
                      ? null
                      : () {
                          ref.read(registrationDataProvider.notifier).updateTrimester(currentSelectedTrimester);
                          context.push(AppRouter.personalizeDietPath);
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

// <<< REMOVED the old _ProgressIndicator and _PersonalizationCard widgets >>>