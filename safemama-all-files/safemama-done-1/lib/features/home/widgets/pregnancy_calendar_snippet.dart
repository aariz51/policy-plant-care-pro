// lib/features/home/widgets/pregnancy_calendar_snippet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/features/home/data/weekly_pregnancy_data.dart';
import 'package:safemama/features/home/models/weekly_pregnancy_info.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/theme/app_theme.dart';

class PregnancyCalendarSnippet extends ConsumerWidget {
  const PregnancyCalendarSnippet({super.key});

  int? _calculateCurrentWeek(DateTime? dueDate) {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (today.isAfter(dueDay)) return 40;
    
    final difference = dueDay.difference(today);
    final weeksRemaining = (difference.inDays / 7).ceil();
    
    int currentWeek = 40 - weeksRemaining + 1;
    if (difference.inDays == 279) currentWeek = 1;
    if (difference.inDays < 0) currentWeek = 41;

    return currentWeek.clamp(1, 42);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final currentLocale = ref.watch(localeProvider).currentLocale;

    if (userProfileState.userProfile == null) {
      return const SizedBox.shrink();
    }

    final DateTime? dueDate = userProfileState.userPregnancyDetails?.dueDate;
    final int? currentWeek = _calculateCurrentWeek(dueDate);

    if (dueDate == null || currentWeek == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.homeCalendarSnippetTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(S.homeCalendarSnippetAddDueDatePrompt),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  GoRouter.of(AppRouter.rootNavigatorKey.currentContext ?? context)
                      .push(AppRouter.profilePath);
                },
                child: Text(S.homeCalendarSnippetGoToSettingsButton),
              )
            ],
          ),
        ),
      );
    }

    WeeklyPregnancyInfo? weeklyInfo;
    try {
      weeklyInfo = allWeeklyPregnancyData.firstWhere((info) => info.weekNumber == currentWeek);
    } catch (e) {
      weeklyInfo = null;
    }

    if (weeklyInfo == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(S.homeCalendarSnippetWeekDataUnavailable(currentWeek.toString())),
        ),
      );
    }

    final String babySizeText = weeklyInfo.getLocalizedBabySize(currentLocale.languageCode);
    final String developmentHighlightsText = weeklyInfo.getLocalizedDevelopmentHighlights(currentLocale.languageCode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 1.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.homeCalendarSnippetCurrentWeekTitle(currentWeek.toString()),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "${S.homeCalendarSnippetBabySize(babySizeText)}\n${developmentHighlightsText}",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}