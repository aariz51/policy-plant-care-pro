// lib/features/guide/screens/guide_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/models/guide_model.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/navigation/app_router.dart';

// This provider fetches the static guides ONCE and caches the result.
final staticGuidesProvider = FutureProvider.autoDispose<List<Guide>>((ref) {
  final guideService = ref.watch(guideServiceProvider);
  final userProfile = ref.watch(userProfileNotifierProvider).userProfile;
  if (userProfile == null) return [];

  int? targetTrimester;
  if (userProfile.selectedTrimester == 'first') targetTrimester = 1;
  if (userProfile.selectedTrimester == 'second') targetTrimester = 2;
  if (userProfile.selectedTrimester == 'third') targetTrimester = 3;

  return guideService.fetchGuides(
    languageCode: 'en',
    targetTrimester: targetTrimester,
    isUserPremium: userProfile.membershipTier == 'premium',
  );
});

class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context)!;
    final guidesAsync = ref.watch(staticGuidesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.pregnancyGuideTitle)),
      body: guidesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (guides) {
          if (guides.isEmpty) {
            return Center(child: Text(S.noGuidesAvailable));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(staticGuidesProvider.future),
            child: ListView.builder(
              itemCount: guides.length,
              itemBuilder: (context, index) {
                final guide = guides[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(guide.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRouter.guideDetailRouteName, extra: guide),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


