import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/vaccine_tracker_service.dart';
import 'package:safemama/core/services/api_service.dart';

class VaccineTrackerState {
  final List<Map<String, dynamic>> vaccineSchedule;
  final List<Map<String, dynamic>> completedVaccines;
  final List<Map<String, dynamic>> upcomingVaccines;
  final Map<String, dynamic>? aiInsights;
  final bool isLoading;
  final bool isGeneratingAI;
  final String? error;
  final bool hasAIInsights;

  const VaccineTrackerState({
    this.vaccineSchedule = const [],
    this.completedVaccines = const [],
    this.upcomingVaccines = const [],
    this.aiInsights,
    this.isLoading = false,
    this.isGeneratingAI = false,
    this.error,
    this.hasAIInsights = false,
  });

  VaccineTrackerState copyWith({
    List<Map<String, dynamic>>? vaccineSchedule,
    List<Map<String, dynamic>>? completedVaccines,
    List<Map<String, dynamic>>? upcomingVaccines,
    Map<String, dynamic>? aiInsights,
    bool? isLoading,
    bool? isGeneratingAI,
    String? error,
    bool? hasAIInsights,
  }) {
    return VaccineTrackerState(
      vaccineSchedule: vaccineSchedule ?? this.vaccineSchedule,
      completedVaccines: completedVaccines ?? this.completedVaccines,
      upcomingVaccines: upcomingVaccines ?? this.upcomingVaccines,
      aiInsights: aiInsights ?? this.aiInsights,
      isLoading: isLoading ?? this.isLoading,
      isGeneratingAI: isGeneratingAI ?? this.isGeneratingAI,
      error: error,
      hasAIInsights: hasAIInsights ?? this.hasAIInsights,
    );
  }
}

class VaccineTrackerNotifier extends StateNotifier<VaccineTrackerState> {
  final VaccineTrackerService _service;
  final ApiService _apiService;

  VaccineTrackerNotifier(this._service, this._apiService) 
      : super(const VaccineTrackerState()) {
    loadVaccines();
  }

  Future<void> loadVaccines() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedule = await _service.getVaccineSchedule();
      final completed = schedule.where((v) => v['completed'] == true).toList();
      final upcoming = schedule.where((v) {
        final completed = v['completed'] as bool? ?? false;
        if (completed) return false;
        final dueDate = v['dueDate'];
        if (dueDate == null) return false;
        try {
          final date = DateTime.parse(dueDate as String);
          return date.isAfter(DateTime.now()) || date.isAtSameMomentAs(DateTime.now());
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort upcoming by date
      upcoming.sort((a, b) {
        final dateA = a['dueDate'] != null ? DateTime.parse(a['dueDate'] as String) : DateTime(2100);
        final dateB = b['dueDate'] != null ? DateTime.parse(b['dueDate'] as String) : DateTime(2100);
        return dateA.compareTo(dateB);
      });

      state = state.copyWith(
        vaccineSchedule: schedule,
        completedVaccines: completed,
        upcomingVaccines: upcoming,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generateAIInsights() async {
    state = state.copyWith(isGeneratingAI: true, error: null);

    try {
      final userProfile = await _service.getUserProfile();
      if (userProfile == null) {
        throw Exception('User profile not available');
      }

      // Call backend AI endpoint
      final response = await _apiService.askExpert(
        question: 'Analyze my child\'s vaccination status and provide personalized recommendations based on the schedule: ${state.vaccineSchedule.length} vaccines scheduled, ${state.completedVaccines.length} completed, ${state.upcomingVaccines.length} upcoming. Child age context: ${userProfile.currentTrimester ?? 'N/A'}.',
        userProfile: userProfile,
      );

      // Parse AI response
      final aiResponse = response['answer'] ?? response['response'] ?? '';
      
      final insights = {
        'status': _extractStatus(aiResponse),
        'recommendations': _extractRecommendations(aiResponse),
        'nextSteps': _extractNextSteps(aiResponse),
        'rawResponse': aiResponse,
        'generatedAt': DateTime.now().toIso8601String(),
      };

      state = state.copyWith(
        aiInsights: insights,
        isGeneratingAI: false,
        hasAIInsights: true,
      );
    } catch (e) {
      state = state.copyWith(
        isGeneratingAI: false,
        error: e.toString(),
      );
    }
  }

  String _extractStatus(String response) {
    // Simple extraction - in production, use better parsing
    if (response.toLowerCase().contains('up to date') || 
        response.toLowerCase().contains('on track')) {
      return 'Your child\'s vaccinations are on track!';
    } else if (response.toLowerCase().contains('behind') ||
               response.toLowerCase().contains('missed')) {
      return 'Some vaccinations may be behind schedule.';
    }
    return 'Vaccination status analysis: ' + response.substring(0, response.length > 100 ? 100 : response.length) + '...';
  }

  String _extractRecommendations(String response) {
    // Extract recommendations section
    if (response.toLowerCase().contains('recommend')) {
      final start = response.toLowerCase().indexOf('recommend');
      return response.substring(start, response.length > start + 200 ? start + 200 : response.length);
    }
    return response.substring(0, response.length > 200 ? 200 : response.length);
  }

  String _extractNextSteps(String response) {
    // Extract next steps
    if (response.toLowerCase().contains('next step') ||
        response.toLowerCase().contains('should')) {
      final lines = response.split('\n');
      for (final line in lines) {
        if (line.toLowerCase().contains('next') || 
            line.toLowerCase().contains('should')) {
          return line.trim();
        }
      }
    }
    return 'Continue following the recommended vaccination schedule.';
  }

  Future<void> markVaccineAsCompleted(String vaccineId) async {
    try {
      await _service.markVaccineCompleted(vaccineId);
      await loadVaccines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addVaccineRecord(Map<String, dynamic> vaccineData) async {
    try {
      await _service.addVaccineRecord(vaccineData);
      await loadVaccines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final vaccineTrackerServiceProvider = Provider<VaccineTrackerService>((ref) {
  return VaccineTrackerService();
});

final vaccineTrackerProvider = StateNotifierProvider<VaccineTrackerNotifier, VaccineTrackerState>((ref) {
  final service = ref.watch(vaccineTrackerServiceProvider);
  final apiService = ApiService();
  return VaccineTrackerNotifier(service, apiService);
});

