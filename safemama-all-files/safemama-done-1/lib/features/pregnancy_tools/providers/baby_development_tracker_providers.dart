import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/baby_development_tracker_service.dart';

class BabyDevelopmentTrackerState {
  final List<Map<String, dynamic>> milestones;
  final List<Map<String, dynamic>> growthEntries;
  final List<Map<String, dynamic>> upcomingMilestones;
  final Map<String, dynamic> stats;
  final Map<String, dynamic>? currentMilestone;
  final Map<String, dynamic>? currentGrowthEntry;
  final bool isLoading;
  final String? error;
  final int currentBabyAgeWeeks;

  const BabyDevelopmentTrackerState({
    this.milestones = const [],
    this.growthEntries = const [],
    this.upcomingMilestones = const [],
    this.stats = const {},
    this.currentMilestone,
    this.currentGrowthEntry,
    this.isLoading = false,
    this.error,
    this.currentBabyAgeWeeks = 0,
  });

  BabyDevelopmentTrackerState copyWith({
    List<Map<String, dynamic>>? milestones,
    List<Map<String, dynamic>>? growthEntries,
    List<Map<String, dynamic>>? upcomingMilestones,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? currentMilestone,
    Map<String, dynamic>? currentGrowthEntry,
    bool? isLoading,
    String? error,
    int? currentBabyAgeWeeks,
  }) {
    return BabyDevelopmentTrackerState(
      milestones: milestones ?? this.milestones,
      growthEntries: growthEntries ?? this.growthEntries,
      upcomingMilestones: upcomingMilestones ?? this.upcomingMilestones,
      stats: stats ?? this.stats,
      currentMilestone: currentMilestone ?? this.currentMilestone,
      currentGrowthEntry: currentGrowthEntry ?? this.currentGrowthEntry,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentBabyAgeWeeks: currentBabyAgeWeeks ?? this.currentBabyAgeWeeks,
    );
  }
}

class BabyDevelopmentTrackerNotifier extends StateNotifier<BabyDevelopmentTrackerState> {
  final BabyDevelopmentTrackerService _service;

  BabyDevelopmentTrackerNotifier(this._service) : super(const BabyDevelopmentTrackerState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final milestones = await _service.getBabyMilestones();
      final growthEntries = await _service.getBabyGrowthEntries();
      final stats = await _service.getBabyDevelopmentStats();
      
      // Calculate baby's current age in weeks (assuming birth date is available)
      int currentBabyAge = _calculateCurrentBabyAge();
      
      final upcomingMilestones = await _service.getUpcomingMilestones(
        currentBabyAgeWeeks: currentBabyAge,
        weeksAhead: 4,
      );

      state = state.copyWith(
        milestones: milestones,
        growthEntries: growthEntries,
        upcomingMilestones: upcomingMilestones,
        stats: stats,
        currentBabyAgeWeeks: currentBabyAge,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  int _calculateCurrentBabyAge() {
    // This would typically be calculated from birth date stored in user profile
    // For now, returning a placeholder value
    // In production, you'd get the birth date from user profile and calculate weeks since birth
    return 12; // 12 weeks old baby as example
  }

  void startNewMilestone({
    required String milestoneType,
    required String title,
    required String description,
    required int expectedAgeWeeks,
  }) {
    final milestone = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': milestoneType,
      'title': title,
      'description': description,
      'expectedAgeWeeks': expectedAgeWeeks,
      'achievedAgeWeeks': null,
      'isAchieved': false,
      'achievedDate': null,
      'notes': '',
      'photoUrl': null,
    };

    state = state.copyWith(currentMilestone: milestone, error: null);
  }

  void startNewGrowthEntry() {
    final growthEntry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'babyAgeWeeks': state.currentBabyAgeWeeks,
      'weightGrams': 0.0,
      'heightCm': 0.0,
      'headCircumferenceCm': 0.0,
      'measurementDate': DateTime.now().toIso8601String(),
      'notes': '',
    };

    state = state.copyWith(currentGrowthEntry: growthEntry, error: null);
  }

  void updateCurrentMilestone(Map<String, dynamic> updates) {
    if (state.currentMilestone == null) return;

    final updatedMilestone = {...state.currentMilestone!, ...updates};
    state = state.copyWith(currentMilestone: updatedMilestone);
  }

  void updateCurrentGrowthEntry(Map<String, dynamic> updates) {
    if (state.currentGrowthEntry == null) return;

    final updatedEntry = {...state.currentGrowthEntry!, ...updates};
    state = state.copyWith(currentGrowthEntry: updatedEntry);
  }

  Future<void> saveMilestone() async {
    if (state.currentMilestone == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.saveBabyMilestone(state.currentMilestone!);
      
      state = state.copyWith(
        currentMilestone: null,
        isLoading: false,
      );
      
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveGrowthEntry() async {
    if (state.currentGrowthEntry == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.saveBabyGrowthEntry(state.currentGrowthEntry!);
      
      state = state.copyWith(
        currentGrowthEntry: null,
        isLoading: false,
      );
      
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markMilestoneAchieved({
    required String milestoneId,
    String? notes,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.markMilestoneAchieved(
        milestoneId: milestoneId,
        achievedAgeWeeks: state.currentBabyAgeWeeks,
        notes: notes,
        photoUrl: photoUrl,
      );

      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addPredefinedMilestones() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final predefinedMilestones = _getPredefinedMilestones();
      
      for (final milestone in predefinedMilestones) {
        await _service.saveBabyMilestone(milestone);
      }

      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<Map<String, dynamic>> _getPredefinedMilestones() {
    return [
      // Motor milestones
      {
        'id': 'motor_hold_head_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'motor',
        'title': 'Holds head up',
        'description': 'Baby can hold their head up while on tummy',
        'expectedAgeWeeks': 6,
        'isAchieved': false,
      },
      {
        'id': 'motor_roll_over_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'motor',
        'title': 'Rolls over',
        'description': 'Baby can roll from tummy to back or back to tummy',
        'expectedAgeWeeks': 16,
        'isAchieved': false,
      },
      {
        'id': 'motor_sits_up_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'motor',
        'title': 'Sits without support',
        'description': 'Baby can sit up without assistance',
        'expectedAgeWeeks': 24,
        'isAchieved': false,
      },
      {
        'id': 'motor_crawls_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'motor',
        'title': 'Crawls',
        'description': 'Baby moves forward on hands and knees',
        'expectedAgeWeeks': 32,
        'isAchieved': false,
      },
      {
        'id': 'motor_walks_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'motor',
        'title': 'Takes first steps',
        'description': 'Baby takes first independent steps',
        'expectedAgeWeeks': 52,
        'isAchieved': false,
      },
      
      // Social milestones
      {
        'id': 'social_smiles_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'social',
        'title': 'Social smiles',
        'description': 'Baby smiles in response to people',
        'expectedAgeWeeks': 8,
        'isAchieved': false,
      },
      {
        'id': 'social_laughs_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'social',
        'title': 'Laughs',
        'description': 'Baby laughs out loud',
        'expectedAgeWeeks': 16,
        'isAchieved': false,
      },
      {
        'id': 'social_stranger_anxiety_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'social',
        'title': 'Shows stranger anxiety',
        'description': 'Baby shows preference for familiar people',
        'expectedAgeWeeks': 32,
        'isAchieved': false,
      },

      // Language milestones
      {
        'id': 'language_coos_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'language',
        'title': 'Coos and gurgles',
        'description': 'Baby makes cooing sounds',
        'expectedAgeWeeks': 8,
        'isAchieved': false,
      },
      {
        'id': 'language_babbles_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'language',
        'title': 'Babbles',
        'description': 'Baby makes babbling sounds like "ba-ba" or "da-da"',
        'expectedAgeWeeks': 24,
        'isAchieved': false,
      },
      {
        'id': 'language_first_word_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'language',
        'title': 'Says first word',
        'description': 'Baby says their first recognizable word',
        'expectedAgeWeeks': 48,
        'isAchieved': false,
      },

      // Cognitive milestones
      {
        'id': 'cognitive_tracks_objects_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'cognitive',
        'title': 'Tracks objects with eyes',
        'description': 'Baby follows moving objects with their eyes',
        'expectedAgeWeeks': 12,
        'isAchieved': false,
      },
      {
        'id': 'cognitive_object_permanence_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'cognitive',
        'title': 'Shows object permanence',
        'description': 'Baby looks for hidden objects',
        'expectedAgeWeeks': 36,
        'isAchieved': false,
      },
    ];
  }

  List<Map<String, dynamic>> getMilestonesByType(String type) {
    return state.milestones
        .where((milestone) => milestone['type'] == type)
        .toList();
  }

  List<Map<String, dynamic>> getAchievedMilestones() {
    return state.milestones
        .where((milestone) => milestone['isAchieved'] == true)
        .toList();
  }

  Map<String, dynamic> getDevelopmentProgress() {
    final totalMilestones = state.milestones.length;
    final achievedMilestones = getAchievedMilestones().length;
    
    if (totalMilestones == 0) {
      return {
        'overallProgress': 0.0,
        'motorProgress': 0.0,
        'socialProgress': 0.0,
        'languageProgress': 0.0,
        'cognitiveProgress': 0.0,
      };
    }

    final typeProgress = <String, double>{};
    for (final type in ['motor', 'social', 'language', 'cognitive']) {
      final typeMilestones = getMilestonesByType(type);
      final achievedInType = typeMilestones.where((m) => m['isAchieved'] == true).length;
      typeProgress['${type}Progress'] = typeMilestones.isNotEmpty ? achievedInType / typeMilestones.length : 0.0;
    }

    return {
      'overallProgress': achievedMilestones / totalMilestones,
      ...typeProgress,
    };
  }

  List<String> getDevelopmentRecommendations() {
    final recommendations = <String>[];
    final progress = getDevelopmentProgress();
    final babyAge = state.currentBabyAgeWeeks;

    // Age-appropriate recommendations
    if (babyAge < 12) {
      recommendations.addAll([
        'Encourage tummy time to strengthen neck and shoulder muscles',
        'Talk and sing to your baby to support language development',
        'Make eye contact during feeding and diaper changes',
      ]);
    } else if (babyAge < 24) {
      recommendations.addAll([
        'Provide colorful toys to encourage reaching and grasping',
        'Read books with simple pictures',
        'Play peek-a-boo to support social development',
      ]);
    } else if (babyAge < 52) {
      recommendations.addAll([
        'Encourage crawling by placing toys just out of reach',
        'Practice simple words and respond to baby\'s babbling',
        'Provide safe spaces for exploration',
      ]);
    }

    // Progress-based recommendations
    if ((progress['motorProgress'] as double) < 0.5) {
      recommendations.add('Consider more physical play activities for motor development');
    }

    if ((progress['languageProgress'] as double) < 0.5) {
      recommendations.add('Increase verbal interaction and reading time');
    }

    return recommendations.take(5).toList();
  }

  Future<void> deleteMilestone(String milestoneId) async {
    try {
      await _service.deleteBabyMilestone(milestoneId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteGrowthEntry(String entryId) async {
    try {
      await _service.deleteBabyGrowthEntry(entryId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void cancelCurrentMilestone() {
    state = state.copyWith(currentMilestone: null, error: null);
  }

  void cancelCurrentGrowthEntry() {
    state = state.copyWith(currentGrowthEntry: null, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateBabyAge(int ageInWeeks) {
    state = state.copyWith(currentBabyAgeWeeks: ageInWeeks);
    _loadData(); // Reload to update upcoming milestones
  }
}

// Providers
final babyDevelopmentTrackerServiceProvider = Provider<BabyDevelopmentTrackerService>((ref) {
  return BabyDevelopmentTrackerService();
});

final babyDevelopmentTrackerProvider = StateNotifierProvider<BabyDevelopmentTrackerNotifier, BabyDevelopmentTrackerState>((ref) {
  final service = ref.watch(babyDevelopmentTrackerServiceProvider);
  return BabyDevelopmentTrackerNotifier(service);
});
