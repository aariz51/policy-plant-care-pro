import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/models/ttc_tracker.dart';
import 'package:safemama/core/models/fertility_tracker.dart';
import 'package:safemama/features/fertility/services/fertility_service.dart';

// TTC Tracker State
class TtcTrackerState {
  final TtcTracker? currentCycle;
  final List<FertilityTracker> fertilityData;
  final bool isLoading;
  final String? error;

  const TtcTrackerState({
    this.currentCycle,
    this.fertilityData = const [],
    this.isLoading = false,
    this.error,
  });

  TtcTrackerState copyWith({
    TtcTracker? currentCycle,
    List<FertilityTracker>? fertilityData,
    bool? isLoading,
    String? error,
  }) {
    return TtcTrackerState(
      currentCycle: currentCycle ?? this.currentCycle,
      fertilityData: fertilityData ?? this.fertilityData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// TTC Tracker Notifier
class TtcTrackerNotifier extends StateNotifier<TtcTrackerState> {
  final FertilityService _fertilityService;

  TtcTrackerNotifier(this._fertilityService) : super(const TtcTrackerState());

  Future<void> loadTtcData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final currentCycle = await _fertilityService.getCurrentTtcCycle();
      final fertilityData = await _fertilityService.getFertilityData();
      
      state = state.copyWith(
        currentCycle: currentCycle,
        fertilityData: fertilityData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveTtcCycle(TtcTracker cycle) async {
    try {
      await _fertilityService.saveTtcCycle(cycle);
      state = state.copyWith(currentCycle: cycle);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addFertilityData(FertilityTracker data) async {
    try {
      await _fertilityService.addFertilityData(data);
      final updatedData = [...state.fertilityData, data];
      state = state.copyWith(fertilityData: updatedData);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final fertilityServiceProvider = Provider<FertilityService>((ref) {
  return FertilityService();
});

final ttcTrackerProvider = StateNotifierProvider<TtcTrackerNotifier, TtcTrackerState>((ref) {
  final service = ref.watch(fertilityServiceProvider);
  return TtcTrackerNotifier(service);
});
