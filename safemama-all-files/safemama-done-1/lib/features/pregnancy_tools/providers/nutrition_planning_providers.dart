import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/nutrition_planning_service.dart';

class NutritionPlanningState {
  final Map<String, dynamic>? currentPlan;
  final List<Map<String, dynamic>> nutritionPlans;
  final List<Map<String, dynamic>> nutritionEntries;
  final List<Map<String, dynamic>> todayEntries;
  final Map<String, dynamic> dailyStats;
  final Map<String, dynamic> overallStats;
  final bool isLoading;
  final String? error;

  const NutritionPlanningState({
    this.currentPlan,
    this.nutritionPlans = const [],
    this.nutritionEntries = const [],
    this.todayEntries = const [],
    this.dailyStats = const {},
    this.overallStats = const {},
    this.isLoading = false,
    this.error,
  });

  NutritionPlanningState copyWith({
    Map<String, dynamic>? currentPlan,
    List<Map<String, dynamic>>? nutritionPlans,
    List<Map<String, dynamic>>? nutritionEntries,
    List<Map<String, dynamic>>? todayEntries,
    Map<String, dynamic>? dailyStats,
    Map<String, dynamic>? overallStats,
    bool? isLoading,
    String? error,
  }) {
    return NutritionPlanningState(
      currentPlan: currentPlan ?? this.currentPlan,
      nutritionPlans: nutritionPlans ?? this.nutritionPlans,
      nutritionEntries: nutritionEntries ?? this.nutritionEntries,
      todayEntries: todayEntries ?? this.todayEntries,
      dailyStats: dailyStats ?? this.dailyStats,
      overallStats: overallStats ?? this.overallStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NutritionPlanningNotifier extends StateNotifier<NutritionPlanningState> {
  final NutritionPlanningService _service;

  NutritionPlanningNotifier(this._service) : super(const NutritionPlanningState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final plans = await _service.getNutritionPlans();
      final currentPlan = await _service.getCurrentNutritionPlan();
      final entries = await _service.getNutritionEntries();
      final stats = await _service.getNutritionStats();
      
      // Filter today's entries
      final today = DateTime.now();
      final todayEntries = entries.where((entry) {
        final entryDate = DateTime.parse(entry['date'] ?? entry['entry_date']);
        return entryDate.year == today.year && 
               entryDate.month == today.month && 
               entryDate.day == today.day;
      }).toList();

      // Calculate daily stats
      final dailyStats = _calculateDailyStats(todayEntries);

      state = state.copyWith(
        nutritionPlans: plans,
        currentPlan: currentPlan,
        nutritionEntries: entries,
        todayEntries: todayEntries,
        dailyStats: dailyStats,
        overallStats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Map<String, dynamic> _calculateDailyStats(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return {
        'totalCalories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'calcium': 0.0,
        'iron': 0.0,
        'folate': 0.0,
      };
    }

    double totalCalories = 0.0;
    final nutrients = <String, double>{
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'fiber': 0.0,
      'calcium': 0.0,
      'iron': 0.0,
      'folate': 0.0,
    };

    for (final entry in entries) {
      totalCalories += (entry['calories'] as double? ?? 0.0);
      
      final entryNutrients = entry['nutrients'] as Map<String, dynamic>? ?? {};
      for (final nutrient in nutrients.keys) {
        nutrients[nutrient] = (nutrients[nutrient] ?? 0.0) + 
                             (entryNutrients[nutrient] as double? ?? 0.0);
      }
    }

    return {
      'totalCalories': totalCalories,
      ...nutrients,
    };
  }

  Future<void> createNutritionPlan({
    required String planName,
    required int pregnancyWeek,
    required List<String> dietaryRestrictions,
    required Map<String, double> nutritionGoals,
    required double calorieTarget,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final mealPlan = _generateMealPlan(pregnancyWeek, dietaryRestrictions, nutritionGoals);
      
      final nutritionPlan = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': planName,
        'pregnancyWeek': pregnancyWeek,
        'mealPlan': mealPlan,
        'dietaryRestrictions': dietaryRestrictions,
        'nutritionGoals': nutritionGoals,
        'calorieTarget': calorieTarget,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _service.saveNutritionPlan(nutritionPlan);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Map<String, List<Map<String, dynamic>>> _generateMealPlan(
    int pregnancyWeek,
    List<String> dietaryRestrictions,
    Map<String, double> nutritionGoals,
  ) {
    // Generate a sample meal plan based on pregnancy week and restrictions
    return {
      'breakfast': [
        {
          'meal': 'Whole grain cereal with milk and berries',
          'calories': 350.0,
          'nutrients': {'protein': 12.0, 'calcium': 300.0, 'folate': 50.0},
        },
        {
          'meal': 'Greek yogurt with granola and fruit',
          'calories': 280.0,
          'nutrients': {'protein': 15.0, 'calcium': 200.0, 'fiber': 5.0},
        },
      ],
      'lunch': [
        {
          'meal': 'Quinoa salad with vegetables and chicken',
          'calories': 450.0,
          'nutrients': {'protein': 25.0, 'iron': 4.0, 'fiber': 8.0},
        },
        {
          'meal': 'Lentil soup with whole grain bread',
          'calories': 380.0,
          'nutrients': {'protein': 18.0, 'iron': 6.0, 'folate': 180.0},
        },
      ],
      'dinner': [
        {
          'meal': 'Grilled salmon with sweet potato and broccoli',
          'calories': 520.0,
          'nutrients': {'protein': 35.0, 'calcium': 150.0, 'iron': 3.0},
        },
        {
          'meal': 'Lean beef stir-fry with brown rice',
          'calories': 480.0,
          'nutrients': {'protein': 30.0, 'iron': 5.0, 'fiber': 6.0},
        },
      ],
      'snacks': [
        {
          'meal': 'Apple slices with almond butter',
          'calories': 190.0,
          'nutrients': {'protein': 6.0, 'fiber': 4.0, 'calcium': 50.0},
        },
        {
          'meal': 'Handful of nuts and dried fruit',
          'calories': 150.0,
          'nutrients': {'protein': 5.0, 'iron': 2.0, 'fiber': 3.0},
        },
      ],
    };
  }

  Future<void> logNutritionEntry({
    required String mealType,
    required List<Map<String, dynamic>> foodItems,
    required double totalCalories,
    required Map<String, double> nutrients,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'mealType': mealType,
        'foodItems': foodItems,
        'calories': totalCalories,
        'nutrients': nutrients,
        'date': DateTime.now().toIso8601String(),
        'notes': notes ?? '',
      };

      await _service.saveNutritionEntry(entry);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteNutritionPlan(String planId) async {
    try {
      await _service.deleteNutritionPlan(planId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNutritionEntry(String entryId) async {
    try {
      await _service.deleteNutritionEntry(entryId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Map<String, dynamic> getNutritionGoalProgress() {
    if (state.currentPlan == null) return {};

    final goals = state.currentPlan!['nutritionGoals'] as Map<String, double>? ?? {};
    final dailyStats = state.dailyStats;
    final progress = <String, double>{};

    for (final goal in goals.entries) {
      final currentValue = dailyStats[goal.key] as double? ?? 0.0;
      final targetValue = goal.value;
      progress[goal.key] = targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    }

    return progress;
  }

  List<String> getNutritionRecommendations() {
    final progress = getNutritionGoalProgress();
    final recommendations = <String>[];

    if ((progress['protein'] ?? 0.0) < 0.8) {
      recommendations.add('Consider adding more protein-rich foods like lean meats, beans, or dairy');
    }
    
    if ((progress['calcium'] ?? 0.0) < 0.8) {
      recommendations.add('Include more calcium sources like dairy products or leafy greens');
    }
    
    if ((progress['iron'] ?? 0.0) < 0.8) {
      recommendations.add('Add iron-rich foods like spinach, lentils, or lean red meat');
    }
    
    if ((progress['folate'] ?? 0.0) < 0.8) {
      recommendations.add('Include folate sources like fortified cereals, citrus fruits, or leafy greens');
    }

    if (recommendations.isEmpty) {
      recommendations.add('You\'re meeting your nutrition goals well! Keep up the great work.');
    }

    return recommendations;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final nutritionPlanningServiceProvider = Provider<NutritionPlanningService>((ref) {
  return NutritionPlanningService();
});

final nutritionPlanningProvider = StateNotifierProvider<NutritionPlanningNotifier, NutritionPlanningState>((ref) {
  final service = ref.watch(nutritionPlanningServiceProvider);
  return NutritionPlanningNotifier(service);
});
