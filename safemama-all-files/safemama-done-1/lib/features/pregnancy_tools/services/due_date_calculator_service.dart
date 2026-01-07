import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class DueDateCalculatorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveCalculation(String method, Map<String, dynamic> results) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveCalculationLocally(method, results);
        return;
      }

      final calculationData = {
        'user_id': user.id,
        'calculation_method': method,
        'due_date': results['dueDate']?.toIso8601String(),
        'current_week': results['currentWeek'],
        'remaining_days': results['remainingDays'],
        'formatted_due_date': results['formattedDueDate'],
        'calculation_data': results,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('due_date_calculations')
          .insert(calculationData);

      await _saveCalculationLocally(method, results);
    } catch (e) {
      await _saveCalculationLocally(method, results);
      rethrow;
    }
  }

  Future<void> _saveCalculationLocally(String method, Map<String, dynamic> results) async {
    try {
      final List<Map<String, dynamic>> calculations = await getCalculationHistory();
      
      final calculationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'method': method,
        'results': results,
        'created_at': DateTime.now().toIso8601String(),
      };

      calculations.insert(0, calculationData);
      
      if (calculations.length > 30) {
        calculations.removeRange(30, calculations.length);
      }

      await _storageService.setString('due_date_calculations', 
          calculations.toString()); // In production, use proper JSON serialization
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getCalculationHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('due_date_calculations')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(15);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getCalculationHistoryLocally();
    } catch (e) {
      return await _getCalculationHistoryLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getCalculationHistoryLocally() async {
    try {
      final calculationsStr = await _storageService.getString('due_date_calculations');
      if (calculationsStr != null) {
        // Parse stored calculations - in production use proper JSON
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLastCalculationByMethod(String method) async {
    try {
      final history = await getCalculationHistory();
      return history
          .where((calc) => calc['calculation_method'] == method)
          .firstOrNull;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteCalculation(String calculationId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('due_date_calculations')
            .delete()
            .eq('id', calculationId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
