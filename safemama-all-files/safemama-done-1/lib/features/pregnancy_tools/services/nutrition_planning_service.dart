import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class NutritionPlanningService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveNutritionPlan(Map<String, dynamic> nutritionPlan) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveNutritionPlanLocally(nutritionPlan);
        return;
      }

      final planData = {
        'user_id': user.id,
        'plan_id': nutritionPlan['id'],
        'plan_name': nutritionPlan['name'],
        'pregnancy_week': nutritionPlan['pregnancyWeek'],
        'meal_plan': nutritionPlan['mealPlan'],
        'dietary_restrictions': nutritionPlan['dietaryRestrictions'],
        'nutrition_goals': nutritionPlan['nutritionGoals'],
        'calorie_target': nutritionPlan['calorieTarget'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('nutrition_plans')
          .insert(planData);

      await _saveNutritionPlanLocally(nutritionPlan);
    } catch (e) {
      await _saveNutritionPlanLocally(nutritionPlan);
      rethrow;
    }
  }

  Future<void> _saveNutritionPlanLocally(Map<String, dynamic> plan) async {
    try {
      final List<Map<String, dynamic>> plans = await getNutritionPlans();
      plans.insert(0, plan);
      
      // Keep only last 10 plans locally
      if (plans.length > 10) {
        plans.removeRange(10, plans.length);
      }

      await _storageService.setString('nutrition_plans', 
          plans.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getNutritionPlans({int limit = 10}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('nutrition_plans')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getNutritionPlansLocally();
    } catch (e) {
      return await _getNutritionPlansLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getNutritionPlansLocally() async {
    try {
      final plansStr = await _storageService.getString('nutrition_plans');
      if (plansStr != null) {
        // Parse plans - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNutritionEntry(Map<String, dynamic> entry) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveNutritionEntryLocally(entry);
        return;
      }

      final entryData = {
        'user_id': user.id,
        'entry_id': entry['id'],
        'meal_type': entry['mealType'],
        'food_items': entry['foodItems'],
        'calories': entry['calories'],
        'nutrients': entry['nutrients'],
        'entry_date': entry['date'],
        'notes': entry['notes'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('nutrition_entries')
          .insert(entryData);

      await _saveNutritionEntryLocally(entry);
    } catch (e) {
      await _saveNutritionEntryLocally(entry);
      rethrow;
    }
  }

  Future<void> _saveNutritionEntryLocally(Map<String, dynamic> entry) async {
    try {
      final List<Map<String, dynamic>> entries = await getNutritionEntries();
      entries.insert(0, entry);
      
      // Keep only last 100 entries locally
      if (entries.length > 100) {
        entries.removeRange(100, entries.length);
      }

      await _storageService.setString('nutrition_entries', 
          entries.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getNutritionEntries({int limit = 30}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('nutrition_entries')
            .select()
            .eq('user_id', user.id)
            .order('entry_date', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getNutritionEntriesLocally();
    } catch (e) {
      return await _getNutritionEntriesLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getNutritionEntriesLocally() async {
    try {
      final entriesStr = await _storageService.getString('nutrition_entries');
      if (entriesStr != null) {
        // Parse entries - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCurrentNutritionPlan() async {
    try {
      final plans = await getNutritionPlans(limit: 1);
      return plans.isNotEmpty ? plans.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getNutritionStats() async {
    try {
      final entries = await getNutritionEntries(limit: 30); // Last 30 entries
      
      if (entries.isEmpty) {
        return {
          'totalEntries': 0,
          'averageDailyCalories': 0.0,
          'nutritionGoalProgress': 0.0,
          'lastEntryDate': null,
        };
      }

      double totalCalories = 0.0;
      final nutritionTotals = <String, double>{};
      
      for (final entry in entries) {
        totalCalories += (entry['calories'] as double? ?? 0.0);
        
        final nutrients = entry['nutrients'] as Map<String, dynamic>? ?? {};
        for (final nutrient in nutrients.entries) {
          nutritionTotals[nutrient.key] = (nutritionTotals[nutrient.key] ?? 0.0) + 
              (nutrient.value as double? ?? 0.0);
        }
      }

      return {
        'totalEntries': entries.length,
        'averageDailyCalories': entries.length > 0 ? totalCalories / entries.length : 0.0,
        'nutritionTotals': nutritionTotals,
        'lastEntryDate': entries.isNotEmpty ? entries.first['entry_date'] : null,
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'averageDailyCalories': 0.0,
        'nutritionGoalProgress': 0.0,
        'lastEntryDate': null,
      };
    }
  }

  Future<void> deleteNutritionPlan(String planId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('nutrition_plans')
            .delete()
            .eq('plan_id', planId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteNutritionEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('nutrition_entries')
            .delete()
            .eq('entry_id', entryId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
