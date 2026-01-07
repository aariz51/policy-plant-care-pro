import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/weight_gain_tracker_service.dart';
import 'package:safemama/core/models/pregnancy_tools.dart';

class WeightGainTrackerState {
  final List<Map<String, dynamic>> weightEntries;
  final Map<String, dynamic>? currentAnalysis;
  final Map<String, dynamic>? userSettings;
  final bool isLoading;
  final String? error;

  const WeightGainTrackerState({
    this.weightEntries = const [],
    this.currentAnalysis,
    this.userSettings,
    this.isLoading = false,
    this.error,
  });

  WeightGainTrackerState copyWith({
    List<Map<String, dynamic>>? weightEntries,
    Map<String, dynamic>? currentAnalysis,
    Map<String, dynamic>? userSettings,
    bool? isLoading,
    String? error,
  }) {
    return WeightGainTrackerState(
      weightEntries: weightEntries ?? this.weightEntries,
      currentAnalysis: currentAnalysis ?? this.currentAnalysis,
      userSettings: userSettings ?? this.userSettings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WeightGainTrackerNotifier extends StateNotifier<WeightGainTrackerState> {
  final WeightGainTrackerService _service;

  WeightGainTrackerNotifier(this._service) : super(const WeightGainTrackerState()) {
    _loadUserData();
  }

  Future<void> addWeightEntry({
    required double weight,
    required int pregnancyWeek,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'date': DateTime.now().toIso8601String(),
        'weight': weight,
        'pregnancyWeek': pregnancyWeek,
        'notes': notes ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _service.saveWeightEntry(entry);
      
      final updatedEntries = [entry, ...state.weightEntries];
      
      state = state.copyWith(
        weightEntries: updatedEntries,
        isLoading: false,
      );

      // Recalculate analysis with new data
      _calculateWeightGainAnalysis();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateUserSettings({
    required double prePregnancyWeight,
    required double height,
    required int currentWeek,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final settings = {
        'prePregnancyWeight': prePregnancyWeight,
        'height': height,
        'currentWeek': currentWeek,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _service.saveUserSettings(settings);
      
      state = state.copyWith(
        userSettings: settings,
        isLoading: false,
      );

      // Recalculate analysis with new settings
      _calculateWeightGainAnalysis();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _calculateWeightGainAnalysis() {
    final settings = state.userSettings;
    final entries = state.weightEntries;
    
    if (settings == null || entries.isEmpty) return;

    try {
      final prePregnancyWeight = settings['prePregnancyWeight'] as double;
      final height = settings['height'] as double;
      final currentWeek = settings['currentWeek'] as int;
      
      // Get latest weight entry
      final latestEntry = entries.first;
      final currentWeight = latestEntry['weight'] as double;

      final analysis = PregnancyCalculator.getWeightGainRecommendations(
        prePregnancyBMI: prePregnancyWeight / (height / 100 * height / 100),
        currentWeek: currentWeek,
        currentWeight: currentWeight,
        prePregnancyWeight: prePregnancyWeight,
      );

      // Add additional analysis data
      analysis['weightHistory'] = entries.map((e) => {
        'date': e['date'],
        'weight': e['weight'],
        'week': e['pregnancyWeek'],
      }).toList();

      analysis['trends'] = _calculateTrends(entries);
      analysis['projectedFinalWeight'] = _projectFinalWeight(entries, currentWeek);

      state = state.copyWith(currentAnalysis: analysis);
    } catch (e) {
      // Handle analysis error silently
    }
  }

  Map<String, dynamic> _calculateTrends(List<Map<String, dynamic>> entries) {
    if (entries.length < 2) {
      return {'trend': 'insufficient_data', 'weeklyAverage': 0.0};
    }

    final sortedEntries = List<Map<String, dynamic>>.from(entries)
      ..sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

    double totalWeightGain = 0;
    int totalWeeks = 0;

    for (int i = 1; i < sortedEntries.length; i++) {
      final current = sortedEntries[i];
      final previous = sortedEntries[i - 1];
      
      final weightDiff = (current['weight'] as double) - (previous['weight'] as double);
      final weekDiff = (current['pregnancyWeek'] as int) - (previous['pregnancyWeek'] as int);
      
      if (weekDiff > 0) {
        totalWeightGain += weightDiff;
        totalWeeks += weekDiff;
      }
    }

    final weeklyAverage = totalWeeks > 0 ? totalWeightGain / totalWeeks : 0.0;
    
    String trend;
    if (weeklyAverage > 0.7) {
      trend = 'rapid';
    } else if (weeklyAverage > 0.3) {
      trend = 'normal';
    } else if (weeklyAverage > 0) {
      trend = 'slow';
    } else {
      trend = 'loss';
    }

    return {
      'trend': trend,
      'weeklyAverage': weeklyAverage,
      'totalGain': totalWeightGain,
    };
  }

  double _projectFinalWeight(List<Map<String, dynamic>> entries, int currentWeek) {
    if (entries.isEmpty || currentWeek >= 40) {
      return entries.isNotEmpty ? entries.first['weight'] as double : 0.0;
    }

    final trends = _calculateTrends(entries);
    final weeklyAverage = trends['weeklyAverage'] as double;
    final remainingWeeks = 40 - currentWeek;
    final currentWeight = entries.first['weight'] as double;

    return currentWeight + (weeklyAverage * remainingWeeks);
  }

  Future<void> _loadUserData() async {
    state = state.copyWith(isLoading: true);

    try {
      final settings = await _service.getUserSettings();
      final entries = await _service.getWeightEntries();

      state = state.copyWith(
        userSettings: settings,
        weightEntries: entries,
        isLoading: false,
      );

      if (settings != null && entries.isNotEmpty) {
        _calculateWeightGainAnalysis();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteWeightEntry(String entryId) async {
    try {
      await _service.deleteWeightEntry(entryId);
      
      final updatedEntries = state.weightEntries
          .where((entry) => entry['id'] != entryId)
          .toList();
      
      state = state.copyWith(weightEntries: updatedEntries);
      
      if (updatedEntries.isNotEmpty && state.userSettings != null) {
        _calculateWeightGainAnalysis();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final weightGainTrackerServiceProvider = Provider<WeightGainTrackerService>((ref) {
  return WeightGainTrackerService();
});

final weightGainTrackerProvider = StateNotifierProvider<WeightGainTrackerNotifier, WeightGainTrackerState>((ref) {
  final service = ref.watch(weightGainTrackerServiceProvider);
  return WeightGainTrackerNotifier(service);
});
