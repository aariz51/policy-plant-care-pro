import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/weekly_updates_service.dart';

class WeeklyUpdatesState {
  final Map<String, dynamic>? currentWeekUpdate;
  final List<Map<String, dynamic>> availableWeeks;
  final List<Map<String, dynamic>> updateHistory;
  final List<Map<String, dynamic>> reflections;
  final Map<String, dynamic>? currentReflection;
  final Map<String, dynamic>? notificationPreferences;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;
  final int selectedWeek;

  const WeeklyUpdatesState({
    this.currentWeekUpdate,
    this.availableWeeks = const [],
    this.updateHistory = const [],
    this.reflections = const [],
    this.currentReflection,
    this.notificationPreferences,
    this.stats = const {},
    this.isLoading = false,
    this.error,
    this.selectedWeek = 1,
  });

  WeeklyUpdatesState copyWith({
    Map<String, dynamic>? currentWeekUpdate,
    List<Map<String, dynamic>>? availableWeeks,
    List<Map<String, dynamic>>? updateHistory,
    List<Map<String, dynamic>>? reflections,
    Map<String, dynamic>? currentReflection,
    Map<String, dynamic>? notificationPreferences,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
    int? selectedWeek,
  }) {
    return WeeklyUpdatesState(
      currentWeekUpdate: currentWeekUpdate ?? this.currentWeekUpdate,
      availableWeeks: availableWeeks ?? this.availableWeeks,
      updateHistory: updateHistory ?? this.updateHistory,
      reflections: reflections ?? this.reflections,
      currentReflection: currentReflection ?? this.currentReflection,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedWeek: selectedWeek ?? this.selectedWeek,
    );
  }
}

class WeeklyUpdatesNotifier extends StateNotifier<WeeklyUpdatesState> {
  final WeeklyUpdatesService _service;

  WeeklyUpdatesNotifier(this._service) : super(const WeeklyUpdatesState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final availableWeeks = await _service.getAvailableWeeks();
      final updateHistory = await _service.getUserUpdateHistory();
      final reflections = await _service.getWeeklyReflections();
      final notificationPrefs = await _service.getNotificationPreferences();
      final stats = await _service.getWeeklyUpdatesStats();
      
      // Load current week update
      final currentUpdate = await _service.getWeeklyUpdate(state.selectedWeek);

      state = state.copyWith(
        availableWeeks: availableWeeks,
        updateHistory: updateHistory,
        reflections: reflections,
        notificationPreferences: notificationPrefs,
        stats: stats,
        currentWeekUpdate: currentUpdate,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadWeeklyUpdate(int pregnancyWeek) async {
    state = state.copyWith(isLoading: true, error: null, selectedWeek: pregnancyWeek);

    try {
      final weeklyUpdate = await _service.getWeeklyUpdate(pregnancyWeek);
      state = state.copyWith(
        currentWeekUpdate: weeklyUpdate,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startNewReflection(int pregnancyWeek) {
    final reflection = {
      'pregnancyWeek': pregnancyWeek,
      'moodRating': 5.0,
      'energyLevel': 5.0,
      'symptoms': <String>[],
      'highlights': '',
      'concerns': '',
      'questionsForDoctor': '',
      'notes': '',
    };

    state = state.copyWith(currentReflection: reflection, error: null);
  }

  void updateCurrentReflection(Map<String, dynamic> updates) {
    if (state.currentReflection == null) return;

    final updatedReflection = {...state.currentReflection!, ...updates};
    state = state.copyWith(currentReflection: updatedReflection);
  }

  void addSymptomToReflection(String symptom) {
    if (state.currentReflection == null) return;

    final currentSymptoms = List<String>.from(state.currentReflection!['symptoms'] ?? []);
    if (!currentSymptoms.contains(symptom)) {
      currentSymptoms.add(symptom);
      updateCurrentReflection({'symptoms': currentSymptoms});
    }
  }

  void removeSymptomFromReflection(String symptom) {
    if (state.currentReflection == null) return;

    final currentSymptoms = List<String>.from(state.currentReflection!['symptoms'] ?? []);
    currentSymptoms.remove(symptom);
    updateCurrentReflection({'symptoms': currentSymptoms});
  }

  Future<void> saveReflection() async {
    if (state.currentReflection == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final pregnancyWeek = state.currentReflection!['pregnancyWeek'] as int;
      await _service.saveWeeklyReflection(
        pregnancyWeek: pregnancyWeek,
        reflection: state.currentReflection!,
      );

      state = state.copyWith(
        currentReflection: null,
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

  Future<void> loadReflection(int pregnancyWeek) async {
    try {
      final reflection = await _service.getWeeklyReflection(pregnancyWeek);
      if (reflection != null) {
        state = state.copyWith(currentReflection: reflection);
      } else {
        startNewReflection(pregnancyWeek);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateNotificationPreferences({
    required bool enablePush,
    required bool enableEmail,
    String? preferredTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.subscribeToWeeklyNotifications(
        enablePush: enablePush,
        enableEmail: enableEmail,
        preferredTime: preferredTime,
      );

      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteReflection(int pregnancyWeek) async {
    try {
      await _service.deleteWeeklyReflection(pregnancyWeek: pregnancyWeek);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Map<String, dynamic>? getReflectionForWeek(int pregnancyWeek) {
    try {
      return state.reflections.firstWhere(
        (reflection) => reflection['pregnancy_week'] == pregnancyWeek,
      );
    } catch (e) {
      return null;
    }
  }

  bool hasReflectionForWeek(int pregnancyWeek) {
    return getReflectionForWeek(pregnancyWeek) != null;
  }

  List<String> getCommonSymptoms() {
    return [
      'Nausea',
      'Fatigue',
      'Breast tenderness',
      'Frequent urination',
      'Heartburn',
      'Back pain',
      'Swelling',
      'Headaches',
      'Insomnia',
      'Mood swings',
      'Food aversions',
      'Cravings',
      'Constipation',
      'Dizziness',
      'Shortness of breath',
    ];
  }

  List<String> getRecommendationsForWeek(int pregnancyWeek) {
    final recommendations = <String>[];

    if (pregnancyWeek <= 12) {
      // First trimester
      recommendations.addAll([
        'Take prenatal vitamins with folic acid',
        'Stay hydrated and eat small, frequent meals',
        'Get plenty of rest - your body is working hard',
        'Avoid alcohol, smoking, and raw foods',
        'Schedule your first prenatal appointment',
      ]);
    } else if (pregnancyWeek <= 28) {
      // Second trimester
      recommendations.addAll([
        'Continue regular prenatal check-ups',
        'Consider prenatal exercise like swimming or yoga',
        'Start thinking about baby names and nursery planning',
        'Discuss genetic screening options with your doctor',
        'Begin shopping for maternity clothes',
      ]);
    } else {
      // Third trimester
      recommendations.addAll([
        'Start preparing your hospital bag',
        'Practice breathing and relaxation techniques',
        'Attend childbirth and breastfeeding classes',
        'Create a birth plan and discuss it with your care team',
        'Install the car seat and childproof your home',
      ]);
    }

    return recommendations;
  }

  Map<String, dynamic> getProgressSummary() {
    final totalWeeks = 40;
    final viewedWeeks = state.updateHistory.length;
    final completedReflections = state.reflections.length;
    
    return {
      'viewedWeeks': viewedWeeks,
      'totalWeeks': totalWeeks,
      'progressPercentage': viewedWeeks / totalWeeks,
      'completedReflections': completedReflections,
      'reflectionRate': viewedWeeks > 0 ? completedReflections / viewedWeeks : 0.0,
      'hasNotifications': state.notificationPreferences != null,
    };
  }

  List<int> getAvailableWeekNumbers() {
    return state.availableWeeks
        .map((week) => week['pregnancy_week'] as int)
        .toList()
        ..sort();
  }

  String? getPreferredNotificationTime() {
    return state.notificationPreferences?['preferred_time'] as String?;
  }

  bool get notificationsEnabled {
    final prefs = state.notificationPreferences;
    if (prefs == null) return false;
    return (prefs['push_enabled'] as bool? ?? false) || 
           (prefs['email_enabled'] as bool? ?? false);
  }

  void cancelCurrentReflection() {
    state = state.copyWith(currentReflection: null, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setSelectedWeek(int week) {
    state = state.copyWith(selectedWeek: week);
    loadWeeklyUpdate(week);
  }
}

// Providers
final weeklyUpdatesServiceProvider = Provider<WeeklyUpdatesService>((ref) {
  return WeeklyUpdatesService();
});

final weeklyUpdatesProvider = StateNotifierProvider<WeeklyUpdatesNotifier, WeeklyUpdatesState>((ref) {
  final service = ref.watch(weeklyUpdatesServiceProvider);
  return WeeklyUpdatesNotifier(service);
});
