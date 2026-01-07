// lib/services/pregnancy_tools_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PregnancyToolsService {
  static const String baseUrl = 'YOUR_BACKEND_URL/api/pregnancy-tools';
  
  // Free Tools
  static Future<Map<String, dynamic>> calculateLMP({
    required String lastMenstrualPeriod,
    required int cycleLength,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lmp-calculator'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lastMenstrualPeriod': lastMenstrualPeriod,
          'cycleLength': cycleLength,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate LMP');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> saveKickCounterSession({
    required String userId,
    required int kickCount,
    required int sessionDuration,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kick-counter'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'kickCount': kickCount,
          'sessionDuration': sessionDuration,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save kick counter session');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Premium Tools
  static Future<Map<String, dynamic>> generateBabyNames({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/baby-name-generator'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'preferences': preferences['style'],
          'gender': preferences['gender'],
          'origin': preferences['origin'],
          'meaning': preferences['meaning'],
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        throw PremiumRequiredException(errorData['error']);
      } else {
        throw Exception('Backend may be experiencing issues. Please try again later.');
      }
    } catch (e) {
      if (e is PremiumRequiredException) rethrow;
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> analyzeWeightGain({
    required String userId,
    required double currentWeight,
    required double prePregnancyWeight,
    required int currentWeek,
    required double height,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/weight-gain-tracker'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'currentWeight': currentWeight,
          'prePregnancyWeight': prePregnancyWeight,
          'currentWeek': currentWeek,
          'height': height,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        throw PremiumRequiredException(errorData['error']);
      } else {
        throw Exception('AI analysis is currently unavailable');
      }
    } catch (e) {
      if (e is PremiumRequiredException) rethrow;
      throw Exception('Network error: $e');
    }
  }
}

class PremiumRequiredException implements Exception {
  final String message;
  PremiumRequiredException(this.message);
}
