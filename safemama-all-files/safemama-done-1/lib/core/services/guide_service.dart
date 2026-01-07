// lib/core/services/guide_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safemama/core/constants/app_constants.dart';
import 'package:safemama/core/models/guide_model.dart';
import 'package:safemama/core/models/user_profile.dart';
// Add this import at the top of the file
import 'package:safemama/features/guide/data/static_guides_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuideService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final String _guidesTableName = 'guides';
  final String _yourBackendBaseUrl = AppConstants.yourBackendBaseUrl;

  // REPLACE the old fetchGuides function with this one.
  Future<List<Guide>> fetchGuides({
    required String languageCode,
    int? targetTrimester,
    bool isUserPremium = false,
  }) async {
    print("[GuideService] Fetching STATIC guides from LOCAL data. Lang: $languageCode, Trimester: $targetTrimester, Premium: $isUserPremium");
    
    // Using a try-catch is still good practice even for local data.
    try {
      // 1. Get all guides from our local static data file.
      List<Guide> guides = getAllStaticGuides();
  
      // 2. Filter by language (important for the future if you add more languages)
      guides = guides.where((g) => g.languageCode == languageCode).toList();
  
      // 3. If the user is NOT premium, filter out premium-only guides.
      if (!isUserPremium) {
        guides = guides.where((g) => !g.isPremiumOnly).toList();
        print("[GuideService] Applied filter: is_premium_only = false");
      }
  
      // 4. If a trimester is specified, filter for that trimester.
      if (targetTrimester != null) {
        guides = guides.where((guide) {
          // A guide is relevant if it has no specific trimester OR it includes the user's trimester.
          bool matches = guide.targetTrimesters == null ||
              guide.targetTrimesters!.isEmpty ||
              guide.targetTrimesters!.contains(targetTrimester);
          return matches;
        }).toList();
      }
      
      print("[GuideService] Fetched ${guides.length} static guides AFTER all filters.");
      return guides;
      
    } catch (e, s) {
      print("[GuideService] Error fetching static guides from local data: $e");
      print("[GuideService] Stacktrace: $s");
      // This is unlikely to fail, but it's a good safeguard.
      throw Exception("Failed to load local guides.");
    }
  }

  Future<Guide> fetchAiPoweredGuideContent({
    required String topic,
    required String languageCode,
    required UserProfile userProfile,
  }) async {
    print("[GuideService] Fetching AI-Powered Guide for Topic: '$topic'");

    // --- THIS IS THE FIX ---
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('User not authenticated.');

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    // --- END OF FIX ---

    final Map<String, dynamic> userContext = {
      'trimester': userProfile.selectedTrimester,
      'allergies': userProfile.knownAllergies,
      'dietaryPreference': userProfile.dietaryPreference,
    };
  
    try {
      final response = await http.post(
        Uri.parse('$_yourBackendBaseUrl/api/generate-guide'),
        headers: headers, // Use the new headers object
        body: jsonEncode({
          'topic': topic,
          'languageCode': languageCode,
          'userContext': userContext,
        }),
      );
  
      if (response.statusCode == 200) {
        return Guide.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? 'Unknown server error';
        print("[GuideService] Server returned error ${response.statusCode}: $errorMessage");
        throw Exception('Server Error: $errorMessage');
      }
    } catch (e, stackTrace) {
      print("[GuideService] CATCH BLOCK: Error fetching AI-powered guide: $e");
      print("[GuideService] Stacktrace: $stackTrace");
      rethrow;
    }
  }
}