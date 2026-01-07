import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class ContractionTimerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveContraction(Map<String, dynamic> contraction) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveContractionLocally(contraction);
        return;
      }

      final contractionData = {
        'user_id': user.id,
        'contraction_id': contraction['id'],
        'start_time': contraction['startTime'],
        'end_time': contraction['endTime'],
        'duration': contraction['duration'],
        'intensity': contraction['intensity'],
        'is_active': contraction['isActive'],
        'notes': contraction['notes'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('contractions')
          .insert(contractionData);

      await _saveContractionLocally(contraction);
    } catch (e) {
      await _saveContractionLocally(contraction);
      rethrow;
    }
  }

  Future<void> _saveContractionLocally(Map<String, dynamic> contraction) async {
    try {
      final List<Map<String, dynamic>> contractions = await getRecentContractions();
      contractions.insert(0, contraction);
      
      // Keep only last 100 contractions locally
      if (contractions.length > 100) {
        contractions.removeRange(100, contractions.length);
      }

      await _storageService.setString('contractions', 
          contractions.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getRecentContractions({int limit = 20}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('contractions')
            .select()
            .eq('user_id', user.id)
            .order('start_time', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getContractionsLocally();
    } catch (e) {
      return await _getContractionsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getContractionsLocally() async {
    try {
      final contractionsStr = await _storageService.getString('contractions');
      if (contractionsStr != null) {
        // Parse contractions - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getContractionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('contractions')
            .select()
            .eq('user_id', user.id)
            .gte('start_time', startDate.toIso8601String())
            .lte('start_time', endDate.toIso8601String())
            .order('start_time', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      }

      // For local storage, filter by date range
      final allContractions = await _getContractionsLocally();
      return allContractions.where((contraction) {
        final startTimeStr = contraction['startTime'];
        if (startTimeStr == null || startTimeStr is! String) return false;
        try {
          final startTime = DateTime.parse(startTimeStr);
          return startTime.isAfter(startDate) && startTime.isBefore(endDate);
        } catch (e) {
          return false;
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveContractionSession(List<Map<String, dynamic>> sessionContractions) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final sessionData = {
        'user_id': user.id,
        'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'contractions_count': sessionContractions.length,
        'session_duration': _calculateSessionDuration(sessionContractions),
        'average_interval': _calculateAverageInterval(sessionContractions),
        'average_duration': _calculateAverageDuration(sessionContractions),
        'session_data': sessionContractions,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('contraction_sessions')
          .insert(sessionData);
    } catch (e) {
      // Handle error silently
    }
  }

  int _calculateSessionDuration(List<Map<String, dynamic>> contractions) {
    if (contractions.isEmpty) return 0;
    
    final lastStartTimeStr = contractions.last['startTime'] ?? contractions.last['start_time'];
    if (lastStartTimeStr == null || lastStartTimeStr is! String) return 0;
    
    try {
      final firstStart = DateTime.parse(lastStartTimeStr);
      final firstEndTimeStr = contractions.first['endTime'] ?? contractions.first['end_time'];
      final lastEnd = firstEndTimeStr != null && firstEndTimeStr is String
          ? DateTime.parse(firstEndTimeStr)
          : DateTime.now();
      
      return lastEnd.difference(firstStart).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  double _calculateAverageInterval(List<Map<String, dynamic>> contractions) {
    if (contractions.length < 2) return 0.0;
    
    double totalInterval = 0.0;
    int intervalCount = 0;

    for (int i = 1; i < contractions.length; i++) {
      final currentStartTimeStr = contractions[i]['startTime'] ?? contractions[i]['start_time'];
      final previousStartTimeStr = contractions[i - 1]['startTime'] ?? contractions[i - 1]['start_time'];
      
      if (currentStartTimeStr == null || currentStartTimeStr is! String ||
          previousStartTimeStr == null || previousStartTimeStr is! String) {
        continue;
      }
      
      try {
        final current = DateTime.parse(currentStartTimeStr);
        final previous = DateTime.parse(previousStartTimeStr);
        totalInterval += current.difference(previous).inMinutes.toDouble();
        intervalCount++;
      } catch (e) {
        continue;
      }
    }

    return intervalCount > 0 ? totalInterval / intervalCount : 0.0;
  }

  double _calculateAverageDuration(List<Map<String, dynamic>> contractions) {
    final completedContractions = contractions
        .where((c) => c['endTime'] != null)
        .toList();
    
    if (completedContractions.isEmpty) return 0.0;
    
    double totalDuration = 0.0;
    
    for (final contraction in completedContractions) {
      totalDuration += (contraction['duration'] as int).toDouble();
    }

    return totalDuration / completedContractions.length;
  }

  Future<void> deleteContraction(String contractionId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('contractions')
            .delete()
            .eq('contraction_id', contractionId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> clearAllContractions() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('contractions')
            .delete()
            .eq('user_id', user.id);
      }

      await _storageService.remove('contractions');
    } catch (e) {
      // Handle error silently
    }
  }
}
