// lib/core/services/pregnancy_details_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/models/user_pregnancy_details.dart';

class PregnancyDetailsService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'user_pregnancy_details';

  Future<UserPregnancyDetails?> getPregnancyDetails(String userId) async {
    print('[PregnancyDetailsService] getPregnancyDetails called for User: $userId');
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // Use maybeSingle if a user might not have a record yet

      print('[PregnancyDetailsService] Get response from Supabase: $response'); // Log Supabase response
      if (response == null) {
        print('[PregnancyDetailsService] No record found or error in fetching.');
        return null;
      }
      return UserPregnancyDetails.fromJson(response);
    } catch (e, s) { // Add stack trace
      print('[PregnancyDetailsService] Error fetching pregnancy details: $e\n$s');
      return null;
    }
  }

  Future<UserPregnancyDetails?> upsertPregnancyDetails({
    required String userId,
    DateTime? dueDate, // This is the date received from UserProfileProvider
  }) async {
    print('[PregnancyDetailsService] upsertPregnancyDetails called. User: $userId, DueDate from caller: $dueDate'); // Log input
    try {
      final String? dateStringForDb = dueDate?.toIso8601String().substring(0, 10);
      print('[PregnancyDetailsService] Date string for DB: $dateStringForDb'); // Log formatted date

      final Map<String, dynamic> dataToUpsert = {
        'user_id': userId,
        'due_date': dateStringForDb, // Use the formatted string or null
        // Supabase handles created_at/updated_at if defaults are set
      };
      print('[PregnancyDetailsService] Data being upserted: $dataToUpsert'); // Log data for upsert
      
      // Remove null due_date if you want it to remain unchanged if not provided
      // Or explicitly set it if that's the intent
      // For upsert, if due_date is not in dataToUpsert, it won't change existing null value.
      // If you want to set it to null, it must be in the map as 'due_date': null.

      final response = await _client
          .from(_tableName)
          .upsert(dataToUpsert, onConflict: 'user_id') // Upsert based on user_id
          .select()
          .single();

      print('[PregnancyDetailsService] Upsert response from Supabase: $response'); // Log Supabase response
      return UserPregnancyDetails.fromJson(response);
    } catch (e, s) { // Add stack trace
      print('[PregnancyDetailsService] Error upserting pregnancy details: $e\n$s');
      return null;
    }
  }
}