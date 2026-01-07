// lib/features/pregnancy_tools/providers/premium_ai_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/providers/app_providers.dart';

enum PremiumToolType {
  birthPlan,
  postpartumTracker,
  vaccineTracker,
  weightGain,
  hospitalBag,
}

class PremiumAIState {
  final String? response;
  final bool isLoading;
  final String? error;
  final PremiumToolType? toolType;

  PremiumAIState({
    this.response,
    this.isLoading = false,
    this.error,
    this.toolType,
  });

  PremiumAIState copyWith({
    String? response,
    bool? isLoading,
    String? error,
    PremiumToolType? toolType,
  }) {
    return PremiumAIState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      toolType: toolType ?? this.toolType,
    );
  }
}

class PremiumAINotifier extends StateNotifier<PremiumAIState> {
  final ApiService _apiService;

  PremiumAINotifier(this._apiService) : super(PremiumAIState());

  // Birth Plan AI
  Future<void> analyzeBirthPlan(Map<String, dynamic> birthPlanData) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      toolType: PremiumToolType.birthPlan
    );

    try {
      print('[PremiumAI] Analyzing birth plan...');

      final response = await _apiService.post(
        '/api/pregnancy-tools/birth-plan-ai',  // ✅ FIXED - Added /api
        {'birthPlanData': birthPlanData},
      );

      if (response['success'] == true) {
        state = state.copyWith(
          response: response['advice'],
          isLoading: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('[PremiumAI] Birth Plan Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Postpartum Tracker AI
  Future<void> analyzePostpartum({
    required String symptoms,
    required int daysPostpartum,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      toolType: PremiumToolType.postpartumTracker
    );

    try {
      print('[PremiumAI] Analyzing postpartum symptoms...');

      final response = await _apiService.post(
        '/api/pregnancy-tools/postpartum-tracker-ai',  // ✅ FIXED - Added /api
        {
          'symptoms': symptoms,
          'daysPostpartum': daysPostpartum,
        },
      );

      if (response['success'] == true) {
        state = state.copyWith(
          response: response['guidance'],
          isLoading: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('[PremiumAI] Postpartum Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Vaccine Tracker AI
  Future<void> analyzeVaccines({
    required int babyAgeMonths,
    required List<String> completedVaccines,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      toolType: PremiumToolType.vaccineTracker
    );

    try {
      print('[PremiumAI] Analyzing vaccine schedule...');

      final response = await _apiService.post(
        '/api/pregnancy-tools/vaccine-tracker-ai',  // ✅ FIXED - Added /api
        {
          'babyAgeMonths': babyAgeMonths,
          'completedVaccines': completedVaccines,
        },
      );

      if (response['success'] == true) {
        state = state.copyWith(
          response: response['recommendations'],
          isLoading: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('[PremiumAI] Vaccine Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Weight Gain AI
  Future<void> analyzeWeightGain({
    required double currentWeight,
    required double prePregnancyWeight,
    required int currentWeek,
    double? height,
    String? bmi,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      toolType: PremiumToolType.weightGain
    );

    try {
      print('[PremiumAI] Analyzing weight gain...');

      final response = await _apiService.post(
        '/api/pregnancy-tools/weight-gain-ai',  // ✅ FIXED - Added /api
        {
          'currentWeight': currentWeight,
          'prePregnancyWeight': prePregnancyWeight,
          'currentWeek': currentWeek,
          'height': height,
          'bmi': bmi,
        },
      );

      if (response['success'] == true) {
        state = state.copyWith(
          response: response['analysis'],
          isLoading: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('[PremiumAI] Weight Gain Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Hospital Bag AI
  Future<void> analyzeHospitalBag({
    required List<String> packedItems,
    required List<String> missingItems,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      toolType: PremiumToolType.hospitalBag
    );

    try {
      print('[PremiumAI] Analyzing hospital bag...');

      final response = await _apiService.post(
        '/api/pregnancy-tools/hospital-bag-ai',  // ✅ FIXED - Added /api
        {
          'packedItems': packedItems,
          'missingItems': missingItems,
        },
      );

      if (response['success'] == true) {
        state = state.copyWith(
          response: response['suggestions'],
          isLoading: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      print('[PremiumAI] Hospital Bag Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearResponse() {
    state = PremiumAIState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final premiumAIProvider =
    StateNotifierProvider<PremiumAINotifier, PremiumAIState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PremiumAINotifier(apiService);
});
