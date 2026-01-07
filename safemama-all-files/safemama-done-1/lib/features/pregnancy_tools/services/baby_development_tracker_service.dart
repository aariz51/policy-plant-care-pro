import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class BabyDevelopmentTrackerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveBabyMilestone(Map<String, dynamic> milestone) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveBabyMilestoneLocally(milestone);
        return;
      }

      final milestoneData = {
        'user_id': user.id,
        'milestone_id': milestone['id'],
        'milestone_type': milestone['type'], // motor, cognitive, social, language
        'title': milestone['title'],
        'description': milestone['description'],
        'expected_age_weeks': milestone['expectedAgeWeeks'],
        'achieved_age_weeks': milestone['achievedAgeWeeks'],
        'is_achieved': milestone['isAchieved'],
        'achieved_date': milestone['achievedDate'],
        'notes': milestone['notes'],
        'photo_url': milestone['photoUrl'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('baby_development_milestones')
          .insert(milestoneData);

      await _saveBabyMilestoneLocally(milestone);
    } catch (e) {
      await _saveBabyMilestoneLocally(milestone);
      rethrow;
    }
  }

  Future<void> _saveBabyMilestoneLocally(Map<String, dynamic> milestone) async {
    try {
      final List<Map<String, dynamic>> milestones = await getBabyMilestones();
      milestones.insert(0, milestone);
      
      // Keep only last 100 milestones locally
      if (milestones.length > 100) {
        milestones.removeRange(100, milestones.length);
      }

      await _storageService.setString('baby_development_milestones', 
          milestones.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getBabyMilestones({int limit = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('baby_development_milestones')
            .select()
            .eq('user_id', user.id)
            .order('expected_age_weeks', ascending: true)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getBabyMilestonesLocally();
    } catch (e) {
      return await _getBabyMilestonesLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getBabyMilestonesLocally() async {
    try {
      final milestonesStr = await _storageService.getString('baby_development_milestones');
      if (milestonesStr != null) {
        // Parse milestones - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBabyGrowthEntry(Map<String, dynamic> growthEntry) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveBabyGrowthEntryLocally(growthEntry);
        return;
      }

      final entryData = {
        'user_id': user.id,
        'entry_id': growthEntry['id'],
        'baby_age_weeks': growthEntry['babyAgeWeeks'],
        'weight_grams': growthEntry['weightGrams'],
        'height_cm': growthEntry['heightCm'],
        'head_circumference_cm': growthEntry['headCircumferenceCm'],
        'measurement_date': growthEntry['measurementDate'],
        'notes': growthEntry['notes'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('baby_growth_entries')
          .insert(entryData);

      await _saveBabyGrowthEntryLocally(growthEntry);
    } catch (e) {
      await _saveBabyGrowthEntryLocally(growthEntry);
      rethrow;
    }
  }

  Future<void> _saveBabyGrowthEntryLocally(Map<String, dynamic> growthEntry) async {
    try {
      final List<Map<String, dynamic>> entries = await getBabyGrowthEntries();
      entries.insert(0, growthEntry);
      
      // Keep only last 100 growth entries locally
      if (entries.length > 100) {
        entries.removeRange(100, entries.length);
      }

      await _storageService.setString('baby_growth_entries', 
          entries.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getBabyGrowthEntries({int limit = 30}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('baby_growth_entries')
            .select()
            .eq('user_id', user.id)
            .order('measurement_date', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getBabyGrowthEntriesLocally();
    } catch (e) {
      return await _getBabyGrowthEntriesLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getBabyGrowthEntriesLocally() async {
    try {
      final entriesStr = await _storageService.getString('baby_growth_entries');
      if (entriesStr != null) {
        // Parse entries - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getBabyDevelopmentStats() async {
    try {
      final milestones = await getBabyMilestones();
      final growthEntries = await getBabyGrowthEntries();
      
      if (milestones.isEmpty) {
        return {
          'totalMilestones': 0,
          'achievedMilestones': 0,
          'developmentProgress': 0.0,
          'growthEntries': growthEntries.length,
          'onTrackPercentage': 0.0,
        };
      }

      int achievedCount = 0;
      int onTrackCount = 0;
      
      for (final milestone in milestones) {
        if (milestone['is_achieved'] == true) {
          achievedCount++;
          
          // Check if achieved within expected timeframe
          final expectedWeeks = milestone['expected_age_weeks'] as int? ?? 0;
          final achievedWeeks = milestone['achieved_age_weeks'] as int? ?? 0;
          
          // Consider on track if achieved within 2 weeks of expected
          if (achievedWeeks <= expectedWeeks + 2) {
            onTrackCount++;
          }
        }
      }

      final developmentProgress = milestones.length > 0 ? achievedCount / milestones.length : 0.0;
      final onTrackPercentage = achievedCount > 0 ? onTrackCount / achievedCount : 0.0;

      return {
        'totalMilestones': milestones.length,
        'achievedMilestones': achievedCount,
        'developmentProgress': developmentProgress,
        'growthEntries': growthEntries.length,
        'onTrackPercentage': onTrackPercentage,
        'milestonesByType': _groupMilestonesByType(milestones),
      };
    } catch (e) {
      return {
        'totalMilestones': 0,
        'achievedMilestones': 0,
        'developmentProgress': 0.0,
        'growthEntries': 0,
        'onTrackPercentage': 0.0,
      };
    }
  }

  Map<String, Map<String, int>> _groupMilestonesByType(List<Map<String, dynamic>> milestones) {
    final typeStats = <String, Map<String, int>>{};
    
    for (final milestone in milestones) {
      final type = milestone['milestone_type'] as String? ?? 'other';
      
      if (!typeStats.containsKey(type)) {
        typeStats[type] = {'total': 0, 'achieved': 0};
      }
      
      typeStats[type]!['total'] = (typeStats[type]!['total']! + 1);
      
      if (milestone['is_achieved'] == true) {
        typeStats[type]!['achieved'] = (typeStats[type]!['achieved']! + 1);
      }
    }
    
    return typeStats;
  }

  Future<List<Map<String, dynamic>>> getUpcomingMilestones({
    required int currentBabyAgeWeeks,
    int weeksAhead = 4,
  }) async {
    try {
      final milestones = await getBabyMilestones();
      
      return milestones.where((milestone) {
        final expectedWeeks = milestone['expected_age_weeks'] as int? ?? 0;
        final isAchieved = milestone['is_achieved'] as bool? ?? false;
        
        return !isAchieved && 
               expectedWeeks >= currentBabyAgeWeeks && 
               expectedWeeks <= currentBabyAgeWeeks + weeksAhead;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markMilestoneAchieved({
    required String milestoneId,
    required int achievedAgeWeeks,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('baby_development_milestones')
            .update({
              'is_achieved': true,
              'achieved_age_weeks': achievedAgeWeeks,
              'achieved_date': DateTime.now().toIso8601String(),
              'notes': notes ?? '',
              'photo_url': photoUrl ?? '',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('milestone_id', milestoneId)
            .eq('user_id', user.id);
      }

      // Update local storage
      // In production, implement proper local storage updates
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteBabyMilestone(String milestoneId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('baby_development_milestones')
            .delete()
            .eq('milestone_id', milestoneId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteBabyGrowthEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('baby_growth_entries')
            .delete()
            .eq('entry_id', entryId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
