import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class KickCounterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveKickSession(Map<String, dynamic> session) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveKickSessionLocally(session);
        return;
      }

      final sessionData = {
        'user_id': user.id,
        'session_id': session['id'],
        'session_data': session,
        'kick_count': session['kickCount'] ?? 0,
        'session_duration': session['sessionDuration'] ?? 0,
        'pregnancy_week': session['pregnancyWeek'],
        'notes': session['notes'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('kick_counter_sessions')
          .insert(sessionData);

      await _saveKickSessionLocally(session);
    } catch (e) {
      await _saveKickSessionLocally(session);
      rethrow;
    }
  }

  Future<void> _saveKickSessionLocally(Map<String, dynamic> session) async {
    try {
      final List<Map<String, dynamic>> sessions = await _getKickSessionsLocally(); // Fixed to use _getKickSessionsLocally
      sessions.insert(0, session);
      
      // Keep only last 50 sessions locally
      if (sessions.length > 50) {
        sessions.removeRange(50, sessions.length);
      }

      await _storageService.setString('kick_counter_sessions', 
          jsonEncode(sessions)); // Fixed to use jsonEncode
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getKickSessions({int limit = 20}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('kick_counter_sessions')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getKickSessionsLocally();
    } catch (e) {
      return await _getKickSessionsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> getRecentSessions({int limit = 10}) async {
    return await getKickSessions();
  }

  Future<List<Map<String, dynamic>>> _getKickSessionsLocally() async {
    try {
      final sessionsStr = await _storageService.getString('kick_counter_sessions');
      if (sessionsStr != null && sessionsStr.isNotEmpty) {
        return List<Map<String, dynamic>>.from(jsonDecode(sessionsStr)); // Fixed to use jsonDecode
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getKickSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('kick_counter_sessions')
            .select()
            .eq('user_id', user.id)
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      }

      // Filter local sessions by date range
      final allSessions = await _getKickSessionsLocally();
      return allSessions.where((session) {
        final sessionDate = DateTime.parse(session['createdAt'] ?? session['created_at']);
        return sessionDate.isAfter(startDate) && sessionDate.isBefore(endDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteKickSession(String sessionId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('kick_counter_sessions')
            .delete()
            .eq('session_id', sessionId)
            .eq('user_id', user.id);
      }

      // Remove from local storage
      final sessions = await _getKickSessionsLocally();
      sessions.removeWhere((session) => session['id'] == sessionId);
      
      await _storageService.setString('kick_counter_sessions', 
          jsonEncode(sessions)); // Fixed to use jsonEncode
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Map<String, dynamic>?> getLatestKickSession() async {
    try {
      final sessions = await getKickSessions(limit: 1);
      return sessions.isNotEmpty ? sessions.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getKickSessionStats() async {
    try {
      final sessions = await getKickSessions(limit: 100);
      
      if (sessions.isEmpty) {
        return {
          'totalSessions': 0,
          'averageKicksPerSession': 0.0,
          'averageSessionDuration': 0.0,
          'totalKicks': 0,
          'lastSessionDate': null,
        };
      }

      int totalKicks = 0;
      int totalDuration = 0;
      
      for (final session in sessions) {
        totalKicks += (session['kick_count'] as int? ?? 0);
        totalDuration += (session['session_duration'] as int? ?? 0);
      }

      return {
        'totalSessions': sessions.length,
        'averageKicksPerSession': sessions.length > 0 ? totalKicks / sessions.length : 0.0,
        'averageSessionDuration': sessions.length > 0 ? totalDuration / sessions.length : 0.0,
        'totalKicks': totalKicks,
        'lastSessionDate': sessions.isNotEmpty ? sessions.first['created_at'] : null,
      };
    } catch (e) {
      return {
        'totalSessions': 0,
        'averageKicksPerSession': 0.0,
        'averageSessionDuration': 0.0,
        'totalKicks': 0,
        'lastSessionDate': null,
      };
    }
  }
}
