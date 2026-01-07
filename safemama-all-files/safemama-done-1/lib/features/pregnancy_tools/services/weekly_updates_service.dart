import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class WeeklyUpdatesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>?> getWeeklyUpdate(int pregnancyWeek) async {
    try {
      final user = _supabase.auth.currentUser;
      
      // First check if user has a personalized update
      if (user != null) {
        final personalizedUpdate = await _supabase
            .from('personalized_weekly_updates')
            .select()
            .eq('user_id', user.id)
            .eq('pregnancy_week', pregnancyWeek)
            .maybeSingle();

        if (personalizedUpdate != null) {
          await _markUpdateAsViewed(pregnancyWeek);
          return Map<String, dynamic>.from(personalizedUpdate);
        }
      }

      // Fallback to general weekly updates
      final generalUpdate = await _supabase
          .from('weekly_pregnancy_updates')
          .select()
          .eq('pregnancy_week', pregnancyWeek)
          .maybeSingle();

      if (generalUpdate != null) {
        if (user != null) {
          await _markUpdateAsViewed(pregnancyWeek);
        }
        return Map<String, dynamic>.from(generalUpdate);
      }

      // Fallback to local data
      return await _getWeeklyUpdateLocally(pregnancyWeek);
    } catch (e) {
      return await _getWeeklyUpdateLocally(pregnancyWeek);
    }
  }

  Future<Map<String, dynamic>?> _getWeeklyUpdateLocally(int pregnancyWeek) async {
    try {
      final updatesStr = await _storageService.getString('weekly_updates_cache');
      if (updatesStr != null) {
        // Parse updates - use proper JSON in production
        // This would contain cached weekly updates
        return null; // Placeholder
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _markUpdateAsViewed(int pregnancyWeek) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if view record exists
      final existingView = await _supabase
          .from('weekly_update_views')
          .select()
          .eq('user_id', user.id)
          .eq('pregnancy_week', pregnancyWeek)
          .maybeSingle();

      if (existingView == null) {
        // Create new view record
        await _supabase
            .from('weekly_update_views')
            .insert({
              'user_id': user.id,
              'pregnancy_week': pregnancyWeek,
              'viewed_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableWeeks() async {
    try {
      final response = await _supabase
          .from('weekly_pregnancy_updates')
          .select('pregnancy_week, title, summary')
          .order('pregnancy_week', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return _getDefaultWeeklyUpdates();
    }
  }

  List<Map<String, dynamic>> _getDefaultWeeklyUpdates() {
    // Default weekly updates for 40 weeks
    return List.generate(40, (index) {
      final week = index + 1;
      return {
        'pregnancy_week': week,
        'title': 'Week $week of Pregnancy',
        'summary': 'Important developments and changes in week $week',
        'baby_development': 'Your baby is developing rapidly this week.',
        'mom_changes': 'You may notice changes in your body this week.',
        'tips': ['Stay hydrated', 'Get adequate rest', 'Attend prenatal appointments'],
        'milestones': [],
        'nutrition_focus': 'Focus on balanced nutrition this week.',
      };
    });
  }

  Future<void> savePersonalizedUpdate({
    required int pregnancyWeek,
    required Map<String, dynamic> personalizedContent,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = {
        'user_id': user.id,
        'pregnancy_week': pregnancyWeek,
        'personalized_content': personalizedContent,
        'generated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('personalized_weekly_updates')
          .upsert(updateData);

    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserUpdateHistory({int limit = 10}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('weekly_update_views')
          .select('''
            *,
            weekly_pregnancy_updates!inner(title, summary)
          ''')
          .eq('user_id', user.id)
          .order('viewed_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> subscribeToWeeklyNotifications({
    required bool enablePush,
    required bool enableEmail,
    String? preferredTime, // '09:00', '12:00', '18:00'
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('notification_preferences')
          .upsert({
            'user_id': user.id,
            'notification_type': 'weekly_updates',
            'push_enabled': enablePush,
            'email_enabled': enableEmail,
            'preferred_time': preferredTime ?? '09:00',
            'updated_at': DateTime.now().toIso8601String(),
          });

    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .eq('notification_type', 'weekly_updates')
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveWeeklyReflection({
    required int pregnancyWeek,
    required Map<String, dynamic> reflection,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reflectionData = {
        'user_id': user.id,
        'pregnancy_week': pregnancyWeek,
        'mood_rating': reflection['moodRating'],
        'energy_level': reflection['energyLevel'],
        'symptoms': reflection['symptoms'],
        'highlights': reflection['highlights'],
        'concerns': reflection['concerns'],
        'questions_for_doctor': reflection['questionsForDoctor'],
        'notes': reflection['notes'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('weekly_reflections')
          .insert(reflectionData);

      // Save locally as backup
      await _saveReflectionLocally(reflectionData);
    } catch (e) {
      await _saveReflectionLocally({
        'pregnancy_week': pregnancyWeek,
        'reflection': reflection,
        'created_at': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  Future<void> _saveReflectionLocally(Map<String, dynamic> reflection) async {
    try {
      final List<Map<String, dynamic>> reflections = await getWeeklyReflections();
      reflections.insert(0, reflection);
      
      // Keep only last 20 reflections locally
      if (reflections.length > 20) {
        reflections.removeRange(20, reflections.length);
      }

      await _storageService.setString('weekly_reflections', 
          reflections.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyReflections({int limit = 20}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('weekly_reflections')
            .select()
            .eq('user_id', user.id)
            .order('pregnancy_week', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getWeeklyReflectionsLocally();
    } catch (e) {
      return await _getWeeklyReflectionsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getWeeklyReflectionsLocally() async {
    try {
      final reflectionsStr = await _storageService.getString('weekly_reflections');
      if (reflectionsStr != null) {
        // Parse reflections - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getWeeklyReflection(int pregnancyWeek) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('weekly_reflections')
          .select()
          .eq('user_id', user.id)
          .eq('pregnancy_week', pregnancyWeek)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getWeeklyUpdatesStats() async {
    try {
      final user = _supabase.auth.currentUser;
      final history = user != null ? await getUserUpdateHistory(limit: 100) : [];
      final reflections = user != null ? await getWeeklyReflections(limit: 100) : [];
      
      int totalViews = history.length;
      int totalReflections = reflections.length;
      
      // Calculate engagement rate
      double engagementRate = 0.0;
      if (totalViews > 0) {
        engagementRate = totalReflections / totalViews;
      }

      // Get latest view
      String? lastViewedWeek;
      if (history.isNotEmpty) {
        lastViewedWeek = 'Week ${history.first['pregnancy_week']}';
      }

      return {
        'totalViews': totalViews,
        'totalReflections': totalReflections,
        'engagementRate': engagementRate,
        'lastViewedWeek': lastViewedWeek,
        'hasNotifications': await getNotificationPreferences() != null,
      };
    } catch (e) {
      return {
        'totalViews': 0,
        'totalReflections': 0,
        'engagementRate': 0.0,
        'lastViewedWeek': null,
        'hasNotifications': false,
      };
    }
  }

  Future<void> deleteWeeklyReflection({
    required int pregnancyWeek,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('weekly_reflections')
          .delete()
          .eq('user_id', user.id)
          .eq('pregnancy_week', pregnancyWeek);
    } catch (e) {
      // Handle error silently
    }
  }
}
