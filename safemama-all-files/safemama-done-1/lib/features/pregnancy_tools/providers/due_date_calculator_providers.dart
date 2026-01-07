// lib/features/pregnancy_tools/providers/due_date_calculator_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/providers/app_providers.dart';

class DueDateState {
  final String? dueDate;
  final int? weeksRemaining;
  final int? daysRemaining;
  final String? calculationMethod;
  final bool isLoading;
  final String? error;

  DueDateState({
    this.dueDate,
    this.weeksRemaining,
    this.daysRemaining,
    this.calculationMethod,
    this.isLoading = false,
    this.error,
  });

  DueDateState copyWith({
    String? dueDate,
    int? weeksRemaining,
    int? daysRemaining,
    String? calculationMethod,
    bool? isLoading,
    String? error,
  }) {
    return DueDateState(
      dueDate: dueDate ?? this.dueDate,
      weeksRemaining: weeksRemaining ?? this.weeksRemaining,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DueDateNotifier extends StateNotifier<DueDateState> {
  final ApiService _apiService;

  DueDateNotifier(this._apiService) : super(DueDateState());

  Future<void> calculateDueDate({
    String? conceptionDate,
    String? lastMenstrualPeriod,
    int? cycleLength,
  }) async {
    if (conceptionDate == null && lastMenstrualPeriod == null) {
      state = state.copyWith(
        error: 'Please provide either conception date or last menstrual period',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('[DueDateCalculator] Calling API...');
      print('Conception: $conceptionDate, LMP: $lastMenstrualPeriod, Cycle: $cycleLength');
      
      final response = await _apiService.post(
        '/api/pregnancy-tools/due-date-calculator',
        {
          if (conceptionDate != null) 'conceptionDate': conceptionDate,
          if (lastMenstrualPeriod != null) 'lastMenstrualPeriod': lastMenstrualPeriod,
          if (cycleLength != null) 'cycleLength': cycleLength,
        },
      );

      print('[DueDateCalculator] Response: $response');

      if (response['success'] == true) {
        // ✅ FIX: Handle null values properly
        state = state.copyWith(
          dueDate: response['dueDate']?.toString() ?? '',
          weeksRemaining: response['weeksRemaining'] is int 
              ? response['weeksRemaining'] 
              : int.tryParse(response['weeksRemaining']?.toString() ?? '0') ?? 0,
          daysRemaining: response['daysRemaining'] is int
              ? response['daysRemaining']
              : int.tryParse(response['daysRemaining']?.toString() ?? '0') ?? 0,
          calculationMethod: response['calculationMethod']?.toString() ?? 'unknown',
          isLoading: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Calculation failed');
      }
    } catch (e) {
      print('[DueDateCalculator] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearResult() {
    state = DueDateState();
  }
}

final dueDateCalculatorProvider =
    StateNotifierProvider<DueDateNotifier, DueDateState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DueDateNotifier(apiService);
});
