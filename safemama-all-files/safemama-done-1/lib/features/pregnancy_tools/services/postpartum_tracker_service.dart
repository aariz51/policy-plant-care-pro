import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class PostpartumTrackerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> savePostpartumEntry(Map<String, dynamic> entry) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _savePostpartumEntryLocally(entry);
        return;
      }

      final entryData = {
        'user_id': user.id,
        'entry_id': entry['id'],
        'entry_type': entry['type'], // mood, physical, feeding, sleep, appointment
        'entry_date': entry['date'],
        'mood_rating': entry['moodRating'],
        'physical_symptoms': entry['physicalSymptoms'],
        'bleeding_level': entry['bleedingLevel'],
        'pain_level': entry['painLevel'],
        'feeding_data': entry['feedingData'],
        'sleep_hours': entry['sleepHours'],
        'notes': entry['notes'],
        'baby_data': entry['babyData'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('postpartum_entries')
          .insert(entryData);

      await _savePostpartumEntryLocally(entry);
    } catch (e) {
      await _savePostpartumEntryLocally(entry);
      rethrow;
    }
  }

  Future<void> _savePostpartumEntryLocally(Map<String, dynamic> entry) async {
    try {
      final List<Map<String, dynamic>> entries = await getPostpartumEntries();
      entries.insert(0, entry);
      
      // Keep only last 200 entries locally (6+ months of data)
      if (entries.length > 200) {
        entries.removeRange(200, entries.length);
      }

      await _storageService.setString('postpartum_entries', 
          entries.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getPostpartumEntries({int limit = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      print('[PostpartumService] getPostpartumEntries called. User ID: ${user?.id}');
      
      if (user != null) {
        final response = await _supabase
            .from('postpartum_entries')
            .select()
            .eq('user_id', user.id)
            .order('entry_date', ascending: false)
            .limit(limit);

        print('[PostpartumService] Supabase response: ${response.length} entries');
        if (response.isNotEmpty) {
          print('[PostpartumService] First entry: ${response.first}');
          return List<Map<String, dynamic>>.from(response);
        }
      }

      print('[PostpartumService] No Supabase entries, checking local');
      return await _getPostpartumEntriesLocally();
    } catch (e) {
      print('[PostpartumService] Error fetching entries: $e');
      return await _getPostpartumEntriesLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getPostpartumEntriesLocally() async {
    try {
      final entriesStr = await _storageService.getString('postpartum_entries');
      if (entriesStr != null) {
        // Parse entries - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> savePostpartumMilestone(Map<String, dynamic> milestone) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _savePostpartumMilestoneLocally(milestone);
        return;
      }

      final milestoneData = {
        'user_id': user.id,
        'milestone_id': milestone['id'],
        'milestone_type': milestone['type'], // recovery, baby_first, medical
        'title': milestone['title'],
        'description': milestone['description'],
        'achieved_date': milestone['achievedDate'],
        'week_postpartum': milestone['weekPostpartum'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('postpartum_milestones')
          .insert(milestoneData);

      await _savePostpartumMilestoneLocally(milestone);
    } catch (e) {
      await _savePostpartumMilestoneLocally(milestone);
      rethrow;
    }
  }

  Future<void> _savePostpartumMilestoneLocally(Map<String, dynamic> milestone) async {
    try {
      final List<Map<String, dynamic>> milestones = await getPostpartumMilestones();
      milestones.insert(0, milestone);
      
      await _storageService.setString('postpartum_milestones', 
          milestones.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getPostpartumMilestones({int limit = 20}) async {
    try {
      final user = _supabase.auth.currentUser;
      print('[PostpartumService] getPostpartumMilestones called. User ID: ${user?.id}');
      
      if (user != null) {
        final response = await _supabase
            .from('postpartum_milestones')
            .select()
            .eq('user_id', user.id)
            .order('achieved_date', ascending: false)
            .limit(limit);

        print('[PostpartumService] Supabase milestones response: ${response.length} milestones');
        if (response.isNotEmpty) {
          print('[PostpartumService] First milestone: ${response.first}');
          return List<Map<String, dynamic>>.from(response);
        }
      }

      print('[PostpartumService] No Supabase milestones, checking local');
      return await _getPostpartumMilestonesLocally();
    } catch (e) {
      print('[PostpartumService] Error fetching milestones: $e');
      return await _getPostpartumMilestonesLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getPostpartumMilestonesLocally() async {
    try {
      final milestonesStr = await _storageService.getString('postpartum_milestones');
      if (milestonesStr != null) {
        // Parse milestones - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPostpartumStats() async {
    try {
      final entries = await getPostpartumEntries(limit: 100);
      final milestones = await getPostpartumMilestones();
      
      if (entries.isEmpty) {
        return {
          'totalEntries': 0,
          'averageMoodRating': 0.0,
          'recoveryProgress': 0.0,
          'totalMilestones': milestones.length,
          'lastEntryDate': null,
        };
      }

      double totalMoodRating = 0.0;
      int moodEntryCount = 0;
      double totalPainLevel = 0.0;
      int painEntryCount = 0;
      
      for (final entry in entries) {
        final mood = entry['mood_rating'] as double?;
        if (mood != null) {
          totalMoodRating += mood;
          moodEntryCount++;
        }
        
        final pain = entry['pain_level'] as double?;
        if (pain != null) {
          totalPainLevel += pain;
          painEntryCount++;
        }
      }

      // Calculate recovery progress based on decreasing pain levels over time
      double recoveryProgress = 0.0;
      if (entries.length >= 2 && painEntryCount >= 2) {
        final latestPain = entries[0]['pain_level'] as double? ?? 0.0;
        final oldestPain = entries[entries.length - 1]['pain_level'] as double? ?? 0.0;
        
        if (oldestPain > 0) {
          recoveryProgress = ((oldestPain - latestPain) / oldestPain).clamp(0.0, 1.0);
        }
      }

      return {
        'totalEntries': entries.length,
        'averageMoodRating': moodEntryCount > 0 ? totalMoodRating / moodEntryCount : 0.0,
        'averagePainLevel': painEntryCount > 0 ? totalPainLevel / painEntryCount : 0.0,
        'recoveryProgress': recoveryProgress,
        'totalMilestones': milestones.length,
        'lastEntryDate': entries.isNotEmpty ? entries.first['entry_date'] : null,
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'averageMoodRating': 0.0,
        'recoveryProgress': 0.0,
        'totalMilestones': 0,
        'lastEntryDate': null,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getEntriesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('postpartum_entries')
            .select()
            .eq('user_id', user.id)
            .gte('entry_date', startDate.toIso8601String())
            .lte('entry_date', endDate.toIso8601String())
            .order('entry_date', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      }

      // Filter local entries by date range
      final allEntries = await _getPostpartumEntriesLocally();
      return allEntries.where((entry) {
        final entryDate = DateTime.parse(entry['date'] ?? entry['entry_date']);
        return entryDate.isAfter(startDate) && entryDate.isBefore(endDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deletePostpartumEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('postpartum_entries')
            .delete()
            .eq('entry_id', entryId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deletePostpartumMilestone(String milestoneId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('postpartum_milestones')
            .delete()
            .eq('milestone_id', milestoneId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
