import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/contraction_timer_service.dart';
import 'package:safemama/core/services/api_service.dart';

class ContractionTimerState {
  final Map<String, dynamic>? currentContraction;
  final List<Map<String, dynamic>> contractions;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? analysis;
  final bool isAnalyzing;

  const ContractionTimerState({
    this.currentContraction,
    this.contractions = const [],
    this.isLoading = false,
    this.error,
    this.analysis,
    this.isAnalyzing = false,
  });

  ContractionTimerState copyWith({
    Map<String, dynamic>? currentContraction,
    List<Map<String, dynamic>>? contractions,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? analysis,
    bool? isAnalyzing,
  }) {
    return ContractionTimerState(
      currentContraction: currentContraction ?? this.currentContraction,
      contractions: contractions ?? this.contractions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      analysis: analysis ?? this.analysis,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}

class ContractionTimerNotifier extends StateNotifier<ContractionTimerState> {
  final ContractionTimerService _service;
  final ApiService _apiService;

  ContractionTimerNotifier(this._service, this._apiService) : super(const ContractionTimerState()) {
    _loadRecentContractions();
  }

  void startContraction() {
    final contraction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'startTime': DateTime.now().toIso8601String(),
      'isActive': true,
      'intensity': 0,
    };

    state = state.copyWith(currentContraction: contraction);
  }

void clearContractions() {
  state = state.copyWith(contractions: []);
}

  void stopContraction() {
    if (state.currentContraction == null) return;

    final contraction = Map<String, dynamic>.from(state.currentContraction!);
    contraction['endTime'] = DateTime.now().toIso8601String();
    contraction['isActive'] = false;

    // Calculate duration
    final startTime = DateTime.parse(contraction['startTime']);
    final endTime = DateTime.parse(contraction['endTime']);
    contraction['duration'] = endTime.difference(startTime).inSeconds;

    // Save contraction
    _service.saveContraction(contraction);

    // Add to contractions list
    final updatedContractions = [contraction, ...state.contractions];

    state = state.copyWith(
      currentContraction: null,
      contractions: updatedContractions,
    );

    // Auto-analyze if we have enough data
    if (updatedContractions.length >= 3) {
      _analyzeContractionPattern();
    }
  }

  void setIntensity(int intensity) {
    if (state.currentContraction == null) return;

    final updatedContraction = Map<String, dynamic>.from(state.currentContraction!);
    updatedContraction['intensity'] = intensity;

    state = state.copyWith(currentContraction: updatedContraction);
  }

  void pauseContraction() {
    if (state.currentContraction == null) return;

    final updatedContraction = Map<String, dynamic>.from(state.currentContraction!);
    updatedContraction['isActive'] = false;
    updatedContraction['pausedAt'] = DateTime.now().toIso8601String();

    state = state.copyWith(currentContraction: updatedContraction);
  }

  void resumeContraction() {
    if (state.currentContraction == null) return;

    final updatedContraction = Map<String, dynamic>.from(state.currentContraction!);
    updatedContraction['isActive'] = true;
    updatedContraction.remove('pausedAt');

    state = state.copyWith(currentContraction: updatedContraction);
  }

  Future<void> _loadRecentContractions() async {
    state = state.copyWith(isLoading: true);

    try {
      final contractions = await _service.getRecentContractions();
      state = state.copyWith(
        contractions: contractions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // AI-Powered Analysis (NEW)
  Future<void> analyzeContractions() async {
    if (state.contractions.isEmpty) {
      state = state.copyWith(error: 'No contractions to analyze');
      return;
    }

    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      print('[ContractionTimer] Analyzing ${state.contractions.length} contractions with AI');
      
      final response = await _apiService.post(
        '/api/pregnancy-tools/contraction-analyze',
        {'contractions': state.contractions},
      );

      print('[ContractionTimer] AI Analysis response: $response');

      if (response['success'] == true) {
        final analysis = {
          'aiAnalysis': response['analysis'],
          'statistics': response['statistics'],
          'timestamp': DateTime.now().toIso8601String(),
          'isAiPowered': true,
        };
        
        state = state.copyWith(
          analysis: analysis,
          isAnalyzing: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('[ContractionTimer] AI Analysis error: $e');
      
      // Fall back to local analysis
      _analyzeContractionPattern();
      
      state = state.copyWith(
        isAnalyzing: false,
        error: 'AI analysis unavailable. Showing basic analysis.',
      );
    }
  }

  void _analyzeContractionPattern() {
    if (state.contractions.length < 3) return;

    try {
      final recentContractions = state.contractions.take(5).toList();
      final intervals = <Duration>[];
      final durations = <Duration>[];

      // Calculate intervals between contractions
      for (int i = 1; i < recentContractions.length; i++) {
        final currentStr = recentContractions[i]['startTime'];
        final previousStr = recentContractions[i - 1]['startTime'];
        if (currentStr != null && currentStr is String && 
            previousStr != null && previousStr is String) {
          try {
            final current = DateTime.parse(currentStr);
            final previous = DateTime.parse(previousStr);
            intervals.add(current.difference(previous));
          } catch (e) {
            // Skip invalid date
          }
        }
      }

      // Calculate contraction durations
      for (final contraction in recentContractions) {
        final startStr = contraction['startTime'];
        final endStr = contraction['endTime'];
        if (startStr != null && startStr is String && 
            endStr != null && endStr is String) {
          try {
            final start = DateTime.parse(startStr);
            final end = DateTime.parse(endStr);
            durations.add(end.difference(start));
          } catch (e) {
            // Skip invalid date
          }
        }
      }

      if (intervals.isEmpty || durations.isEmpty) return;

      // Calculate averages
      final avgInterval = intervals.reduce((a, b) => 
        Duration(seconds: a.inSeconds + b.inSeconds)) ~/ intervals.length;
      final avgDuration = durations.reduce((a, b) => 
        Duration(seconds: a.inSeconds + b.inSeconds)) ~/ durations.length;

      // Determine labor stage
      String stage;
      String advice;
      String urgency;

      if (avgInterval.inMinutes <= 5 && avgDuration.inSeconds >= 60) {
        stage = 'Active Labor';
        advice = 'Head to the hospital immediately. Your contractions are consistent and strong.';
        urgency = 'high';
      } else if (avgInterval.inMinutes <= 10 && avgDuration.inSeconds >= 45) {
        stage = 'Early Active Labor';
        advice = 'Labor is progressing. Prepare to leave for the hospital soon.';
        urgency = 'medium';
      } else if (avgInterval.inMinutes <= 20 && avgDuration.inSeconds >= 30) {
        stage = 'Early Labor';
        advice = 'Early labor has begun. Rest and stay hydrated. Monitor the pattern.';
        urgency = 'low';
      } else {
        stage = 'Pre-labor';
        advice = 'These may be practice contractions. Keep monitoring.';
        urgency = 'none';
      }

      final analysis = {
        'stage': stage,
        'advice': advice,
        'urgency': urgency,
        'avgInterval': avgInterval.inMinutes,
        'avgDuration': avgDuration.inSeconds,
        'contractionCount': recentContractions.length,
        'timestamp': DateTime.now().toIso8601String(),
        'isAiPowered': false,
      };

      state = state.copyWith(analysis: analysis);
    } catch (e) {
      // Handle analysis error silently
    }
  }

  void clearSession() {
    state = state.copyWith(
      currentContraction: null,
      contractions: [],
      analysis: null,
    );
  }

  void clearAnalysis() {
    state = state.copyWith(analysis: null);
  }
}

// Providers
final contractionTimerServiceProvider = Provider<ContractionTimerService>((ref) {
  return ContractionTimerService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final contractionTimerProvider = StateNotifierProvider<ContractionTimerNotifier, ContractionTimerState>((ref) {
  final service = ref.watch(contractionTimerServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return ContractionTimerNotifier(service, apiService);
});
