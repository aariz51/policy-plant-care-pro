// lib/features/auth/screens/personalize_goal_screen.dart
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


// --- Enums and Extensions remain the same ---
enum UserGoalOption { scanItems, getGuidance, understandNutrition, askExpertAI, none }

extension UserGoalOptionExtension on UserGoalOption {
  String toSupabaseString() {
    switch (this) {
      case UserGoalOption.scanItems: return 'scan_items';
      case UserGoalOption.getGuidance: return 'get_guidance';
      case UserGoalOption.understandNutrition: return 'understand_nutrition';
      case UserGoalOption.askExpertAI: return 'ask_expert_ai';
      default: return 'none';
    }
  }
  static UserGoalOption fromSupabaseString(String? value) {
    switch (value) {
      case 'scan_items': return UserGoalOption.scanItems;
      case 'get_guidance': return UserGoalOption.getGuidance;
      case 'understand_nutrition': return UserGoalOption.understandNutrition;
      case 'ask_expert_ai': return UserGoalOption.askExpertAI;
      default: return UserGoalOption.none;
    }
  }
}

final selectedUserGoalProvider = StateProvider<UserGoalOption>((ref) => UserGoalOption.none);

// <<< ENTIRE WIDGET REDESIGNED >>>
class PersonalizeGoalScreen extends ConsumerWidget {
  const PersonalizeGoalScreen({super.key});

  String _getGoalDisplayName(BuildContext context, UserGoalOption option) {
    final S = AppLocalizations.of(context)!;
    switch (option) {
      case UserGoalOption.scanItems: return S.goalScanItems;
      case UserGoalOption.getGuidance: return S.goalGetGuidance;
      case UserGoalOption.understandNutrition: return S.goalUnderstandNutrition;
      case UserGoalOption.askExpertAI: return S.goalAskExpertAI;
      default: return "";
    }
  }

  IconData _getGoalIcon(UserGoalOption option) {
    switch (option) {
      case UserGoalOption.scanItems: return Icons.qr_code_scanner_rounded;
      case UserGoalOption.getGuidance: return Icons.lightbulb_rounded;
      case UserGoalOption.understandNutrition: return Icons.restaurant_menu_rounded;
      case UserGoalOption.askExpertAI: return Icons.chat_rounded;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final currentSelectedGoal = ref.watch(selectedUserGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        title: Text(S.yourMainGoalTitle, style: textTheme.titleLarge?.copyWith(color: AppColors.textDark)),
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
              const ProgressIndicatorBar(currentStep: 4, totalSteps: 4),
              const SizedBox(height: 24),
              Text(
                S.whatIsYourMainGoalQuestion,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
               const SizedBox(height: 8),
              Text(
                "Let us know what's most important to you.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: UserGoalOption.values
                      .where((g) => g != UserGoalOption.none)
                      // <<< CHANGED: Using the new shared widget
                      .map((goal) => PersonalizationSelectionCard( 
                        title: _getGoalDisplayName(context, goal),
                        subtitle: "We'll highlight features for this.", // Generic subtitle
                        icon: _getGoalIcon(goal),
                        isSelected: currentSelectedGoal == goal,
                        onTap: () => ref.read(selectedUserGoalProvider.notifier).state = goal,
                      )).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: CustomElevatedButton(
                  text: S.continueButton,
                  onPressed: currentSelectedGoal == UserGoalOption.none
                      ? null
                      : () {
                          ref.read(registrationDataProvider.notifier).updateGoal(currentSelectedGoal);
                          context.push(AppRouter.accountCreationHubPath);
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