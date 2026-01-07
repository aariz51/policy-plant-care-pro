import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/lmp_calculator_service.dart';
import 'package:safemama/core/models/pregnancy_tools.dart';

class LmpCalculatorState {
  final Map<String, dynamic>? results;
  final bool isLoading;
  final String? error;

  const LmpCalculatorState({
    this.results,
    this.isLoading = false,
    this.error,
  });

  LmpCalculatorState copyWith({
    Map<String, dynamic>? results,
    bool? isLoading,
    String? error,
  }) {
    return LmpCalculatorState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LmpCalculatorNotifier extends StateNotifier<LmpCalculatorState> {
  final LmpCalculatorService _service;

  LmpCalculatorNotifier(this._service) : super(const LmpCalculatorState());

  void calculatePregnancy(DateTime lmpDate) {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final results = PregnancyCalculator.calculateFromLMP(lmpDate);
      
      // Save calculation to history
      _service.saveCalculation(lmpDate, results);
      
      state = state.copyWith(
        results: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearResults() {
    state = state.copyWith(results: null, error: null);
  }
}

// Providers
final lmpCalculatorServiceProvider = Provider<LmpCalculatorService>((ref) {
  return LmpCalculatorService();
});

final lmpCalculatorProvider = StateNotifierProvider<LmpCalculatorNotifier, LmpCalculatorState>((ref) {
  final service = ref.watch(lmpCalculatorServiceProvider);
  return LmpCalculatorNotifier(service);
});
