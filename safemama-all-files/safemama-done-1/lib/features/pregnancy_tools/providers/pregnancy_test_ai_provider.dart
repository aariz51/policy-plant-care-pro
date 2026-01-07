// lib/features/pregnancy_tools/providers/pregnancy_test_ai_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/providers/app_providers.dart';

/// Response model for pregnancy test analysis
class PregnancyTestAnalysis {
  final String id;
  final String likelihood; // low|medium|high
  final String summary;
  final String nextSteps;
  final String whenToTest;
  final List<String> urgentWarnings;
  final String reassuranceNote;
  final int currentUsage;
  final int limit;
  final String period;

  PregnancyTestAnalysis({
    required this.id,
    required this.likelihood,
    required this.summary,
    required this.nextSteps,
    required this.whenToTest,
    required this.urgentWarnings,
    required this.reassuranceNote,
    required this.currentUsage,
    required this.limit,
    required this.period,
  });

  factory PregnancyTestAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] ?? {};
    final usage = json['usage'] ?? {};
    
    return PregnancyTestAnalysis(
      id: analysis['id'] ?? '',
      likelihood: analysis['likelihood'] ?? 'low',
      summary: analysis['summary'] ?? '',
      nextSteps: analysis['nextSteps'] ?? '',
      whenToTest: analysis['whenToTest'] ?? '',
      urgentWarnings: List<String>.from(analysis['urgentWarnings'] ?? []),
      reassuranceNote: analysis['reassuranceNote'] ?? '',
      currentUsage: usage['current'] ?? 0,
      limit: usage['limit'] ?? 0,
      period: usage['period'] ?? 'month',
    );
  }
}

/// State for pregnancy test AI analysis
class PregnancyTestAIState {
  final PregnancyTestAnalysis? analysis;
  final bool isLoading;
  final String? error;
  final bool isPremiumRequired;
  final bool limitReached;

  PregnancyTestAIState({
    this.analysis,
    this.isLoading = false,
    this.error,
    this.isPremiumRequired = false,
    this.limitReached = false,
  });

  PregnancyTestAIState copyWith({
    PregnancyTestAnalysis? analysis,
    bool? isLoading,
    String? error,
    bool? isPremiumRequired,
    bool? limitReached,
  }) {
    return PregnancyTestAIState(
      analysis: analysis ?? this.analysis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPremiumRequired: isPremiumRequired ?? this.isPremiumRequired,
      limitReached: limitReached ?? this.limitReached,
    );
  }
}

/// Notifier for pregnancy test AI analysis
class PregnancyTestAINotifier extends StateNotifier<PregnancyTestAIState> {
  final ApiService _apiService;

  PregnancyTestAINotifier(this._apiService) : super(PregnancyTestAIState());

  /// Analyze pregnancy likelihood based on user input
  Future<void> analyzePregnancyTest({
    required String lmpDate,
    required int cycleLength,
    required List<String> hadUnprotectedSexDates,
    required List<String> symptoms,
    required bool testTaken,
    String? testTakenDate,
    String? testResult,
    required int anxietyLevel,
    String? notes,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      isPremiumRequired: false,
      limitReached: false,
    );

    try {
      print('[PregnancyTestAI] Analyzing pregnancy test data...');

      final requestBody = {
        'lmpDate': lmpDate,
        'cycleLength': cycleLength,
        'hadUnprotectedSexDates': hadUnprotectedSexDates,
        'symptoms': symptoms,
        'testTaken': testTaken,
        if (testTakenDate != null) 'testTakenDate': testTakenDate,
        if (testResult != null) 'testResult': testResult,
        'anxietyLevel': anxietyLevel,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      print('[PregnancyTestAI] Request body: $requestBody');

      final response = await _apiService.post(
        '/api/pregnancy-tools/pregnancy-test-ai',
        requestBody,
      );

      print('[PregnancyTestAI] Response received: $response');

      if (response['success'] == true) {
        final analysis = PregnancyTestAnalysis.fromJson(response);
        state = state.copyWith(
          analysis: analysis,
          isLoading: false,
        );
        print('[PregnancyTestAI] Analysis completed successfully');
      } else if (response['isPremiumRequired'] == true) {
        // Premium feature - show paywall
        print('[PregnancyTestAI] Premium required');
        state = state.copyWith(
          isLoading: false,
          isPremiumRequired: true,
          error: response['error'] ?? 'Premium subscription required',
        );
      } else if (response['limitReached'] == true) {
        // Usage limit exceeded
        print('[PregnancyTestAI] Usage limit reached');
        state = state.copyWith(
          isLoading: false,
          limitReached: true,
          error: response['error'] ?? 'Usage limit reached',
        );
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('[PregnancyTestAI] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clear the current analysis and reset state
  void clearAnalysis() {
    state = PregnancyTestAIState();
  }

  /// Clear only the error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for pregnancy test AI analysis
final pregnancyTestAIProvider =
    StateNotifierProvider<PregnancyTestAINotifier, PregnancyTestAIState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PregnancyTestAINotifier(apiService);
});

