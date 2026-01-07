import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/hospital_bag_checklist_service.dart';

class HospitalBagChecklistState {
  final Map<String, List<Map<String, dynamic>>> checklistData;
  final bool isLoading;
  final String? error;
  final double completionPercentage;
  final int totalItems;
  final int completedItems;

  const HospitalBagChecklistState({
    this.checklistData = const {},
    this.isLoading = false,
    this.error,
    this.completionPercentage = 0.0,
    this.totalItems = 0,
    this.completedItems = 0,
  });

  HospitalBagChecklistState copyWith({
    Map<String, List<Map<String, dynamic>>>? checklistData,
    bool? isLoading,
    String? error,
    double? completionPercentage,
    int? totalItems,
    int? completedItems,
  }) {
    return HospitalBagChecklistState(
      checklistData: checklistData ?? this.checklistData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
    );
  }
}

class HospitalBagChecklistNotifier extends StateNotifier<HospitalBagChecklistState> {
  final HospitalBagChecklistService _service;

  HospitalBagChecklistNotifier(this._service) : super(const HospitalBagChecklistState()) {
    _loadChecklistData();
  }

  Future<void> _loadChecklistData() async {
    state = state.copyWith(isLoading: true);

    try {
      final checklistData = await _service.getChecklistData();
      _updateStats(checklistData);
      
      state = state.copyWith(
        checklistData: checklistData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void toggleItem(String category, String itemId) {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.checklistData);
    
    if (updatedData[category] != null) {
      final categoryItems = List<Map<String, dynamic>>.from(updatedData[category]!);
      
      for (int i = 0; i < categoryItems.length; i++) {
        if (categoryItems[i]['id'] == itemId) {
          categoryItems[i] = Map<String, dynamic>.from(categoryItems[i]);
          categoryItems[i]['checked'] = !(categoryItems[i]['checked'] as bool);
          break;
        }
      }
      
      updatedData[category] = categoryItems;
    }

    _updateStats(updatedData);
    state = state.copyWith(checklistData: updatedData);
    
    // Save to storage
    _service.saveChecklistData(updatedData);
  }

  void addCustomItem({
    required String category,
    required String itemName,
    required String priority,
    String? note,
  }) {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.checklistData);
    
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'item': itemName,
      'category': 'Custom',
      'checked': false,
      'priority': priority,
      'note': note ?? '',
      'isCustom': true,
    };

    if (updatedData[category] != null) {
      updatedData[category] = [...updatedData[category]!, newItem];
    } else {
      updatedData[category] = [newItem];
    }

    _updateStats(updatedData);
    state = state.copyWith(checklistData: updatedData);
    
    _service.saveChecklistData(updatedData);
  }

  void removeItem(String category, String itemId) {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.checklistData);
    
    if (updatedData[category] != null) {
      updatedData[category] = updatedData[category]!
          .where((item) => item['id'] != itemId)
          .toList();
    }

    _updateStats(updatedData);
    state = state.copyWith(checklistData: updatedData);
    
    _service.saveChecklistData(updatedData);
  }

  void updateItemNote(String category, String itemId, String note) {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.checklistData);
    
    if (updatedData[category] != null) {
      final categoryItems = List<Map<String, dynamic>>.from(updatedData[category]!);
      
      for (int i = 0; i < categoryItems.length; i++) {
        if (categoryItems[i]['id'] == itemId) {
          categoryItems[i] = Map<String, dynamic>.from(categoryItems[i]);
          categoryItems[i]['note'] = note;
          break;
        }
      }
      
      updatedData[category] = categoryItems;
    }

    state = state.copyWith(checklistData: updatedData);
    _service.saveChecklistData(updatedData);
  }

  void resetChecklist() {
    final updatedData = Map<String, List<Map<String, dynamic>>>.from(state.checklistData);
    
    for (final category in updatedData.keys) {
      final categoryItems = List<Map<String, dynamic>>.from(updatedData[category]!);
      
      for (int i = 0; i < categoryItems.length; i++) {
        categoryItems[i] = Map<String, dynamic>.from(categoryItems[i]);
        categoryItems[i]['checked'] = false;
      }
      
      updatedData[category] = categoryItems;
    }

    _updateStats(updatedData);
    state = state.copyWith(checklistData: updatedData);
    
    _service.saveChecklistData(updatedData);
  }

  void _updateStats(Map<String, List<Map<String, dynamic>>> checklistData) {
    int totalItems = 0;
    int completedItems = 0;

    for (final categoryItems in checklistData.values) {
      totalItems += categoryItems.length;
      completedItems += categoryItems.where((item) => item['checked'] == true).length;
    }

    final percentage = totalItems > 0 ? (completedItems / totalItems) : 0.0;

    state = state.copyWith(
      totalItems: totalItems,
      completedItems: completedItems,
      completionPercentage: percentage,
    );
  }

  Map<String, dynamic> getChecklistStats() {
    return {
      'totalItems': state.totalItems,
      'completedItems': state.completedItems,
      'completionPercentage': state.completionPercentage,
      'isReady': state.completionPercentage >= 0.8,
    };
  }
}

// Providers
final hospitalBagChecklistServiceProvider = Provider<HospitalBagChecklistService>((ref) {
  return HospitalBagChecklistService();
});

final hospitalBagChecklistProvider = StateNotifierProvider<HospitalBagChecklistNotifier, HospitalBagChecklistState>((ref) {
  final service = ref.watch(hospitalBagChecklistServiceProvider);
  return HospitalBagChecklistNotifier(service);
});
