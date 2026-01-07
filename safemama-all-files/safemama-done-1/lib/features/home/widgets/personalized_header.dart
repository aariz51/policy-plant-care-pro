// lib/features/home/widgets/personalized_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/l10n/app_localizations.dart'; // Or your direct path
import 'package:safemama/core/models/user_profile.dart';
import 'package:safemama/features/auth/screens/personalize_trimester_screen.dart'; // Assuming TrimesterOption is here
import 'package:safemama/core/theme/app_theme.dart'; // For new colors


class PersonalizedHeader extends ConsumerWidget {
  const PersonalizedHeader({super.key});

  String _getDisplayTrimester(String? dbTrimesterValue, AppLocalizations S) {
    if (dbTrimesterValue == null || dbTrimesterValue.isEmpty || dbTrimesterValue == TrimesterOption.none.toSupabaseString()) {
      return S.trimesterPlanningOrEarly;
    }
    if (dbTrimesterValue == 'first' || dbTrimesterValue == TrimesterOption.first.name) return S.trimesterFirst;
    if (dbTrimesterValue == 'second' || dbTrimesterValue == TrimesterOption.second.name) return S.trimesterSecond;
    if (dbTrimesterValue == 'third' || dbTrimesterValue == TrimesterOption.third.name) return S.trimesterThird;
    if (dbTrimesterValue == 'planning_or_early' || dbTrimesterValue == TrimesterOption.planningOrEarly.name) return S.trimesterPlanningOrEarly;
    return dbTrimesterValue;
  }

  String _getTipOfTheDay(String? trimesterKey, AppLocalizations S) {
    if (trimesterKey == 'first') {
      return S.tipFirstTrimester;
    } else if (trimesterKey == 'second') {
      return S.tipSecondTrimester;
    } else if (trimesterKey == 'third') {
      return S.tipThirdTrimester;
    }
    return S.tipGeneral;
  }

  int? _calculateCurrentPregnancyWeek(DateTime? dueDate) {
    if (dueDate == null) {
      return null;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (today.isAfter(dueDay)) {
      final daysOverdue = today.difference(dueDay).inDays;
      return (40 + (daysOverdue / 7)).ceil().clamp(40,42);
    }
    final difference = dueDay.difference(today);
    final weeksRemaining = (difference.inDays / 7).ceil();
    int currentWeek = 40 - weeksRemaining + 1;
    if (difference.inDays >= 274 && difference.inDays <= 279) currentWeek = 1;
    else if (difference.inDays >= 280) return null;
    return currentWeek.clamp(1, 42);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final userProfile = userProfileState.userProfile;
    final S = AppLocalizations.of(context)!;

    String greetingName = userProfile?.fullName?.isNotEmpty == true ? userProfile!.fullName! : S.mamaFallbackName;
    String trimesterDisplay = _getDisplayTrimester(userProfile?.selectedTrimester, S);
    String tipOfTheDay = _getTipOfTheDay(userProfile?.selectedTrimester, S);

    final DateTime? dueDate = userProfileState.userPregnancyDetails?.dueDate;
    int? currentWeek = _calculateCurrentPregnancyWeek(dueDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.helloUser(greetingName),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${S.currentTrimesterStatus(trimesterDisplay)}${currentWeek != null ? ' ${S.approxWeek(currentWeek.toString())}' : ''}",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Card( // Tip of the Day Card
          elevation: 1.0,
          color: AppTheme.lightYellowBackground.withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.warningOrange.withOpacity(0.2))
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.warningOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.tipForYouToday,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tipOfTheDay,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}