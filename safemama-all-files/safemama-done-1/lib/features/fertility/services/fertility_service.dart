import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/models/ttc_tracker.dart';
import 'package:safemama/core/models/fertility_tracker.dart';

class FertilityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<TtcTracker?> getCurrentTtcCycle() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('ttc_tracking')
          .select()
          .eq('user_id', user.id)
          .eq('is_actively_ttc', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return TtcTracker.fromMap(response);
    } catch (e) {
      throw Exception('Failed to load TTC cycle: $e');
    }
  }

  Future<void> saveTtcCycle(TtcTracker cycle) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('ttc_tracking').upsert({
        ...cycle.toMap(),
        'user_id': user.id,
      });
    } catch (e) {
      throw Exception('Failed to save TTC cycle: $e');
    }
  }

  Future<List<FertilityTracker>> getFertilityData({int? days = 30}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('fertility_tracking')
          .select()
          .eq('user_id', user.id)
          .gte('record_date', DateTime.now().subtract(Duration(days: days ?? 30)).toIso8601String())
          .order('record_date', ascending: false);

      return response.map<FertilityTracker>((data) => FertilityTracker.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to load fertility data: $e');
    }
  }

  Future<void> addFertilityData(FertilityTracker data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('fertility_tracking').upsert({
        ...data.toMap(),
        'user_id': user.id,
      });
    } catch (e) {
      throw Exception('Failed to save fertility data: $e');
    }
  }

  Future<void> deleteFertilityData(String id) async {
    try {
      await _supabase.from('fertility_tracking').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete fertility data: $e');
    }
  }
}
