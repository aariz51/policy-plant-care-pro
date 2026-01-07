import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class WeightGainTrackerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveWeightEntry(Map<String, dynamic> entry) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveWeightEntryLocally(entry);
        return;
      }

      final weightData = {
        'user_id': user.id,
        'entry_id': entry['id'],
        'weight': entry['weight'],
        'pregnancy_week': entry['pregnancyWeek'],
        'notes': entry['notes'],
        'entry_date': entry['date'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('weight_entries')
          .insert(weightData);

      await _saveWeightEntryLocally(entry);
    } catch (e) {
      await _saveWeightEntryLocally(entry);
      rethrow;
    }
  }

  Future<void> _saveWeightEntryLocally(Map<String, dynamic> entry) async {
    try {
      final List<Map<String, dynamic>> entries = await getWeightEntries();
      entries.insert(0, entry);
      
      // Keep only last 200 entries locally
      if (entries.length > 200) {
        entries.removeRange(200, entries.length);
      }

      await _storageService.setString('weight_entries', 
          entries.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getWeightEntries() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('weight_entries')
            .select()
            .eq('user_id', user.id)
            .order('entry_date', ascending: false);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getWeightEntriesLocally();
    } catch (e) {
      return await _getWeightEntriesLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getWeightEntriesLocally() async {
    try {
      final entriesStr = await _storageService.getString('weight_entries');
      if (entriesStr != null) {
        // Parse entries - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveUserSettingsLocally(settings);
        return;
      }

      await _supabase
          .from('weight_tracker_settings')
          .upsert({
            'user_id': user.id,
            'pre_pregnancy_weight': settings['prePregnancyWeight'],
            'height': settings['height'],
            'current_week': settings['currentWeek'],
            'updated_at': DateTime.now().toIso8601String(),
          });

      await _saveUserSettingsLocally(settings);
    } catch (e) {
      await _saveUserSettingsLocally(settings);
      rethrow;
    }
  }

  Future<void> _saveUserSettingsLocally(Map<String, dynamic> settings) async {
    try {
      await _storageService.setString('weight_tracker_settings', 
          settings.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('weight_tracker_settings')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null) {
          return Map<String, dynamic>.from(response);
        }
      }

      return await _getUserSettingsLocally();
    } catch (e) {
      return await _getUserSettingsLocally();
    }
  }

  Future<Map<String, dynamic>?> _getUserSettingsLocally() async {
    try {
      final settingsStr = await _storageService.getString('weight_tracker_settings');
      if (settingsStr != null) {
        // Parse settings - use proper JSON in production
        return {}; // Placeholder
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteWeightEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('weight_entries')
            .delete()
            .eq('entry_id', entryId)
            .eq('user_id', user.id);
      }

      // Remove from local storage
      final entries = await _getWeightEntriesLocally();
      entries.removeWhere((entry) => entry['id'] == entryId);
      
      await _storageService.setString('weight_entries', 
          entries.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getWeightEntriesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('weight_entries')
            .select()
            .eq('user_id', user.id)
            .gte('entry_date', startDate.toIso8601String())
            .lte('entry_date', endDate.toIso8601String())
            .order('entry_date', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      }

      // Filter local entries by date range
      final allEntries = await _getWeightEntriesLocally();
      return allEntries.where((entry) {
        final entryDate = DateTime.parse(entry['date']);
        return entryDate.isAfter(startDate) && entryDate.isBefore(endDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestWeightEntry() async {
    try {
      final entries = await getWeightEntries();
      return entries.isNotEmpty ? entries.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<double?> getAverageWeeklyGain({int weeksBack = 4}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: weeksBack * 7));
      
      final entries = await getWeightEntriesByDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      if (entries.length < 2) return null;

      final sortedEntries = entries..sort((a, b) => 
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      double totalGain = 0.0;
      int totalWeeks = 0;

      for (int i = 1; i < sortedEntries.length; i++) {
        final current = sortedEntries[i];
        final previous = sortedEntries[i - 1];
        
        final weightDiff = (current['weight'] as double) - (previous['weight'] as double);
        final currentWeek = current['pregnancyWeek'] as int;
        final previousWeek = previous['pregnancyWeek'] as int;
        final weekDiff = currentWeek - previousWeek;
        
        if (weekDiff > 0) {
          totalGain += weightDiff;
          totalWeeks += weekDiff;
        }
      }

      return totalWeeks > 0 ? totalGain / totalWeeks : null;
    } catch (e) {
      return null;
    }
  }
}
