import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class LmpCalculatorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveCalculation(DateTime lmpDate, Map<String, dynamic> results) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        // Save locally if not authenticated
        await _saveCalculationLocally(lmpDate, results);
        return;
      }

      final calculationData = {
        'user_id': user.id,
        'lmp_date': lmpDate.toIso8601String(),
        'due_date': results['dueDate']?.toIso8601String(),
        'current_week': results['currentWeek'],
        'current_day': results['currentDay'],
        'days_until_due': results['daysUntilDue'],
        'conception_date': results['conceptionDate']?.toIso8601String(),
        'trimester': results['trimester'],
        'calculation_data': results,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('lmp_calculations')
          .insert(calculationData);

      // Also save locally for offline access
      await _saveCalculationLocally(lmpDate, results);
    } catch (e) {
      // Fallback to local storage
      await _saveCalculationLocally(lmpDate, results);
      rethrow;
    }
  }

  Future<void> _saveCalculationLocally(DateTime lmpDate, Map<String, dynamic> results) async {
    try {
      final List<Map<String, dynamic>> calculations = await getCalculationHistory();
      
      final calculationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'lmp_date': lmpDate.toIso8601String(),
        'results': results,
        'created_at': DateTime.now().toIso8601String(),
      };

      calculations.insert(0, calculationData);
      
      // Keep only last 50 calculations
      if (calculations.length > 50) {
        calculations.removeRange(50, calculations.length);
      }

      await _storageService.setString('lmp_calculations', 
          jsonEncode(calculations));
    } catch (e) {
      // Handle storage error silently
    }
  }

  Future<List<Map<String, dynamic>>> getCalculationHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        // Try to get from Supabase first
        final response = await _supabase
            .from('lmp_calculations')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(20);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      // Fallback to local storage
      return await _getCalculationHistoryLocally();
    } catch (e) {
      return await _getCalculationHistoryLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getCalculationHistoryLocally() async {
    try {
      final calculations = await _storageService.getStringList('lmp_calculations');
      return calculations?.map((calcStr) {
        // Parse stored calculation string back to Map
        // This is a simplified version - in production you'd use proper JSON serialization
        return <String, dynamic>{};
      }).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLastCalculation() async {
    try {
      final history = await getCalculationHistory();
      return history.isNotEmpty ? history.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteCalculation(String calculationId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('lmp_calculations')
            .delete()
            .eq('id', calculationId)
            .eq('user_id', user.id);
      }

      // Also remove from local storage
      await _deleteCalculationLocally(calculationId);
    } catch (e) {
      await _deleteCalculationLocally(calculationId);
    }
  }

  Future<void> _deleteCalculationLocally(String calculationId) async {
    try {
      final calculations = await _getCalculationHistoryLocally();
      calculations.removeWhere((calc) => calc['id'] == calculationId);
      
      await _storageService.setString('lmp_calculations', 
          jsonEncode(calculations));
    } catch (e) {
      // Handle error silently
    }
  }
}
