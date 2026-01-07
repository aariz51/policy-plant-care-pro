// lib/features/pregnancy_tools/providers/baby_name_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/providers/app_providers.dart';  // ✅ ADD THIS IMPORT

class BabyNameState {
  final List<Map<String, dynamic>> suggestions;
  final bool isLoading;
  final String? error;

  BabyNameState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  BabyNameState copyWith({
    List<Map<String, dynamic>>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return BabyNameState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BabyNameNotifier extends StateNotifier<BabyNameState> {
  final ApiService _apiService;

  BabyNameNotifier(this._apiService) : super(BabyNameState());

  Future<void> generateNames({
    required String gender,
    required String origin,
    required String meaning,
    int count = 5,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('[BabyNameGenerator] Calling API with: gender=$gender, origin=$origin, meaning=$meaning');
      
      final response = await _apiService.post(
  '/api/pregnancy-tools/baby-name-generator',
        {
          'gender': gender,
          'origin': origin,
          'meaning': meaning,
          'count': count,
        },
      );

      print('[BabyNameGenerator] Response received: ${response.toString()}');

      if (response['success'] == true && response['names'] != null) {
        final names = (response['names'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        
        print('[BabyNameGenerator] Parsed ${names.length} names successfully');
        
        state = state.copyWith(
          suggestions: names,
          isLoading: false,
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to generate names');
      }
    } catch (e) {
      print('[BabyNameGenerator] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuggestions() {
    state = BabyNameState();
  }
}

final babyNameGeneratorProvider =
    StateNotifierProvider<BabyNameNotifier, BabyNameState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BabyNameNotifier(apiService);
});
