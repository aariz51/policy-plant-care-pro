import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/postpartum_tracker_service.dart';

class PostpartumTrackerState {
  final List<Map<String, dynamic>> postpartumEntries;
  final List<Map<String, dynamic>> milestones;
  final Map<String, dynamic>? todayEntry;
  final Map<String, dynamic> stats;
  final Map<String, dynamic>? currentEntry;
  final bool isLoading;
  final String? error;

  const PostpartumTrackerState({
    this.postpartumEntries = const [],
    this.milestones = const [],
    this.todayEntry,
    this.stats = const {},
    this.currentEntry,
    this.isLoading = false,
    this.error,
  });

  PostpartumTrackerState copyWith({
    List<Map<String, dynamic>>? postpartumEntries,
    List<Map<String, dynamic>>? milestones,
    Map<String, dynamic>? todayEntry,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? currentEntry,
    bool? isLoading,
    String? error,
  }) {
    return PostpartumTrackerState(
      postpartumEntries: postpartumEntries ?? this.postpartumEntries,
      milestones: milestones ?? this.milestones,
      todayEntry: todayEntry ?? this.todayEntry,
      stats: stats ?? this.stats,
      currentEntry: currentEntry ?? this.currentEntry,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PostpartumTrackerNotifier extends StateNotifier<PostpartumTrackerState> {
  final PostpartumTrackerService _service;

  PostpartumTrackerNotifier(this._service) : super(const PostpartumTrackerState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = await _service.getPostpartumEntries();
      final milestones = await _service.getPostpartumMilestones();
      final stats = await _service.getPostpartumStats();

      // Normalize entries to use camelCase keys for UI
      final normalizedEntries = entries.map((entry) {
        return {
          'id': entry['entry_id'] ?? entry['id'],
          'type': entry['entry_type'] ?? entry['type'],
          'date': entry['entry_date'] ?? entry['date'],
          'moodRating': entry['mood_rating'] ?? entry['moodRating'] ?? 3.0,
          'physicalSymptoms': entry['physical_symptoms'] ?? entry['physicalSymptoms'] ?? [],
          'bleedingLevel': entry['bleeding_level'] ?? entry['bleedingLevel'] ?? 'none',
          'painLevel': entry['pain_level'] ?? entry['painLevel'] ?? 0.0,
          'feedingData': entry['feeding_data'] ?? entry['feedingData'] ?? {},
          'sleepHours': entry['sleep_hours'] ?? entry['sleepHours'] ?? 0.0,
          'notes': entry['notes'] ?? '',
          'babyData': entry['baby_data'] ?? entry['babyData'] ?? {},
        };
      }).toList();

      // Normalize milestones to use camelCase keys for UI
      final normalizedMilestones = milestones.map((milestone) {
        return {
          'id': milestone['milestone_id'] ?? milestone['id'],
          'type': milestone['milestone_type'] ?? milestone['type'],
          'title': milestone['title'] ?? '',
          'description': milestone['description'] ?? '',
          'achievedDate': milestone['achieved_date'] ?? milestone['achievedDate'],
          'weekPostpartum': milestone['week_postpartum'] ?? milestone['weekPostpartum'] ?? 0,
        };
      }).toList();

      // Find today's entry
      final today = DateTime.now();
      final todayEntry = normalizedEntries.where((entry) {
        final entryDateStr = entry['date'] as String?;
        if (entryDateStr == null) return false;
        final entryDate = DateTime.parse(entryDateStr);
        return entryDate.year == today.year && 
               entryDate.month == today.month && 
               entryDate.day == today.day;
      }).firstOrNull;

      state = state.copyWith(
        postpartumEntries: normalizedEntries,
        milestones: normalizedMilestones,
        todayEntry: todayEntry,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      print('[PostpartumProvider] Error loading data: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startNewEntry({required String entryType}) {
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': entryType,
      'date': DateTime.now().toIso8601String(),
      'moodRating': 3.0, // Default to "Okay" mood (range is 1-5)
      'physicalSymptoms': <String>[],
      'bleedingLevel': 'none',
      'painLevel': 0.0,
      'feedingData': <String, dynamic>{},
      'sleepHours': 0.0,
      'notes': '',
      'babyData': <String, dynamic>{},
    };

    state = state.copyWith(currentEntry: entry, error: null);
  }

  void updateCurrentEntry(Map<String, dynamic> updates) {
    if (state.currentEntry == null) return;

    final updatedEntry = {...state.currentEntry!, ...updates};
    state = state.copyWith(currentEntry: updatedEntry);
  }

  Future<void> saveCurrentEntry() async {
    if (state.currentEntry == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.savePostpartumEntry(state.currentEntry!);
      
      state = state.copyWith(
        currentEntry: null,
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

  Future<void> logQuickMood({
    required double moodRating,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'mood',
        'date': DateTime.now().toIso8601String(),
        'moodRating': moodRating,
        'physicalSymptoms': <String>[],
        'bleedingLevel': 'none',
        'painLevel': 0.0,
        'feedingData': <String, dynamic>{},
        'sleepHours': 0.0,
        'notes': notes ?? '',
        'babyData': <String, dynamic>{},
      };

      await _service.savePostpartumEntry(entry);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addMilestone({
    required String milestoneType,
    required String title,
    required String description,
    required int weekPostpartum,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final milestone = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': milestoneType,
        'title': title,
        'description': description,
        'achievedDate': DateTime.now().toIso8601String(),
        'weekPostpartum': weekPostpartum,
      };

      await _service.savePostpartumMilestone(milestone);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _service.deletePostpartumEntry(entryId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteMilestone(String milestoneId) async {
    try {
      await _service.deletePostpartumMilestone(milestoneId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Map<String, dynamic>> getEntriesByType(String entryType) {
    return state.postpartumEntries
        .where((entry) => entry['type'] == entryType)
        .toList();
  }

  List<Map<String, dynamic>> getMilestonesByType(String milestoneType) {
    return state.milestones
        .where((milestone) => milestone['type'] == milestoneType)
        .toList();
  }

  Map<String, dynamic> getWeeklyProgress(int weekPostpartum) {
    final weekEntries = state.postpartumEntries.where((entry) {
      final entryDate = DateTime.parse(entry['date'] ?? entry['entry_date']);
      final daysSinceDelivery = DateTime.now().difference(entryDate).inDays;
      final entryWeek = (daysSinceDelivery / 7).floor() + 1;
      return entryWeek == weekPostpartum;
    }).toList();

    if (weekEntries.isEmpty) {
      return {
        'averageMood': 0.0,
        'averagePain': 0.0,
        'totalEntries': 0,
        'milestones': 0,
      };
    }

    double totalMood = 0.0;
    double totalPain = 0.0;
    int moodCount = 0;
    int painCount = 0;

    for (final entry in weekEntries) {
      final mood = entry['moodRating'] as double?;
      final pain = entry['painLevel'] as double?;
      
      if (mood != null) {
        totalMood += mood;
        moodCount++;
      }
      
      if (pain != null) {
        totalPain += pain;
        painCount++;
      }
    }

    final weekMilestones = state.milestones
        .where((m) => m['weekPostpartum'] == weekPostpartum)
        .length;

    return {
      'averageMood': moodCount > 0 ? totalMood / moodCount : 0.0,
      'averagePain': painCount > 0 ? totalPain / painCount : 0.0,
      'totalEntries': weekEntries.length,
      'milestones': weekMilestones,
    };
  }

  List<String> getRecoveryRecommendations() {
    final stats = state.stats;
    final recommendations = <String>[];

    final avgMood = stats['averageMoodRating'] as double? ?? 0.0;
    final avgPain = stats['averagePainLevel'] as double? ?? 0.0;
    final recoveryProgress = stats['recoveryProgress'] as double? ?? 0.0;

    if (avgMood < 3.0) {
      recommendations.add('Consider talking to your healthcare provider about mood support');
    }

    if (avgPain > 6.0) {
      recommendations.add('Discuss pain management options with your doctor');
    }

    if (recoveryProgress < 0.5) {
      recommendations.add('Focus on rest and gentle recovery activities');
    }

    recommendations.addAll([
      'Stay hydrated and eat nutritious meals',
      'Get rest when possible',
      'Don\'t hesitate to ask for help with daily tasks',
      'Attend all postpartum check-ups',
    ]);

    return recommendations;
  }

  void cancelCurrentEntry() {
    state = state.copyWith(currentEntry: null, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final postpartumTrackerServiceProvider = Provider<PostpartumTrackerService>((ref) {
  return PostpartumTrackerService();
});

final postpartumTrackerProvider = StateNotifierProvider<PostpartumTrackerNotifier, PostpartumTrackerState>((ref) {
  final service = ref.watch(postpartumTrackerServiceProvider);
  return PostpartumTrackerNotifier(service);
});
