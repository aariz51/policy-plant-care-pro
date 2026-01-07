import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/models/user_profile.dart';

class VaccineTrackerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Standard vaccine schedule for children (0-18 months)
  static const List<Map<String, dynamic>> _defaultSchedule = [
    {'id': 'bcg', 'name': 'BCG', 'dueDate': '0', 'ageMonths': 0, 'completed': false},
    {'id': 'hep_b_1', 'name': 'Hepatitis B (1st dose)', 'dueDate': '0', 'ageMonths': 0, 'completed': false},
    {'id': 'dpt_1', 'name': 'DPT (1st dose)', 'dueDate': '6', 'ageMonths': 6, 'completed': false},
    {'id': 'polio_1', 'name': 'Polio (1st dose)', 'dueDate': '6', 'ageMonths': 6, 'completed': false},
    {'id': 'hib_1', 'name': 'Hib (1st dose)', 'dueDate': '6', 'ageMonths': 6, 'completed': false},
    {'id': 'dpt_2', 'name': 'DPT (2nd dose)', 'dueDate': '10', 'ageMonths': 10, 'completed': false},
    {'id': 'polio_2', 'name': 'Polio (2nd dose)', 'dueDate': '10', 'ageMonths': 10, 'completed': false},
    {'id': 'hib_2', 'name': 'Hib (2nd dose)', 'dueDate': '10', 'ageMonths': 10, 'completed': false},
    {'id': 'dpt_3', 'name': 'DPT (3rd dose)', 'dueDate': '14', 'ageMonths': 14, 'completed': false},
    {'id': 'polio_3', 'name': 'Polio (3rd dose)', 'dueDate': '14', 'ageMonths': 14, 'completed': false},
    {'id': 'hib_3', 'name': 'Hib (3rd dose)', 'dueDate': '14', 'ageMonths': 14, 'completed': false},
    {'id': 'mmr_1', 'name': 'MMR (1st dose)', 'dueDate': '15', 'ageMonths': 15, 'completed': false},
  ];

  Future<List<Map<String, dynamic>>> getVaccineSchedule() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return _defaultSchedule.map((v) => Map<String, dynamic>.from(v)).toList();
      }

      // Try to get saved schedule from database
      final response = await _supabase
          .from('vaccine_schedules')
          .select()
          .eq('user_id', user.id)
          .order('age_months', ascending: true);

      if (response != null && response.isNotEmpty) {
        return List<Map<String, dynamic>>.from(response.map((r) => {
          'id': r['vaccine_id'],
          'name': r['vaccine_name'],
          'dueDate': r['due_date'],
          'ageMonths': r['age_months'],
          'completed': r['completed'] ?? false,
          'completedDate': r['completed_date'],
        }));
      }

      // Return default schedule if no saved schedule
      return _defaultSchedule.map((v) => Map<String, dynamic>.from(v)).toList();
    } catch (e) {
      // Return default schedule on error
      return _defaultSchedule.map((v) => Map<String, dynamic>.from(v)).toList();
    }
  }

  Future<void> markVaccineCompleted(String vaccineId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('vaccine_schedules')
          .update({
            'completed': true,
            'completed_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('vaccine_id', vaccineId);
    } catch (e) {
      // Handle error silently - might not have database table yet
      print('Error marking vaccine as completed: $e');
    }
  }

  Future<void> addVaccineRecord(Map<String, dynamic> vaccineData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('vaccine_schedules')
          .insert({
            'user_id': user.id,
            'vaccine_id': vaccineData['id'],
            'vaccine_name': vaccineData['name'],
            'due_date': vaccineData['dueDate'],
            'age_months': vaccineData['ageMonths'],
            'completed': vaccineData['completed'] ?? false,
            'completed_date': vaccineData['completedDate'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error adding vaccine record: $e');
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (response != null) {
        return UserProfile.fromMap(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

