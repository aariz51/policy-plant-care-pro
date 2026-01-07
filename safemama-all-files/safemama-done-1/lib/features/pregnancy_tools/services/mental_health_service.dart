import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class MentalHealthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> saveMentalHealthAssessment(Map<String, dynamic> assessment) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _saveAssessmentLocally(assessment);
        return;
      }

      final assessmentData = {
        'user_id': user.id,
        'assessment_id': assessment['id'],
        'assessment_type': assessment['type'],
        'responses': assessment['responses'],
        'score': assessment['score'],
        'risk_level': assessment['riskLevel'],
        'recommendations': assessment['recommendations'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('mental_health_assessments')
          .insert(assessmentData);

      await _saveAssessmentLocally(assessment);
    } catch (e) {
      await _saveAssessmentLocally(assessment);
      rethrow;
    }
  }

  Future<void> _saveAssessmentLocally(Map<String, dynamic> assessment) async {
    try {
      final List<Map<String, dynamic>> assessments = await getMentalHealthAssessments();
      assessments.insert(0, assessment);
      
      // Keep only last 20 assessments locally
      if (assessments.length > 20) {
        assessments.removeRange(20, assessments.length);
      }

      await _storageService.setString('mental_health_assessments', 
          assessments.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getMentalHealthAssessments({int limit = 10}) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('mental_health_assessments')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(limit);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getMentalHealthAssessmentsLocally();
    } catch (e) {
      return await _getMentalHealthAssessmentsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getMentalHealthAssessmentsLocally() async {
    try {
      final assessmentsStr = await _storageService.getString('mental_health_assessments');
      if (assessmentsStr != null) {
        // Parse assessments - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestAssessment() async {
    try {
      final assessments = await getMentalHealthAssessments(limit: 1);
      return assessments.isNotEmpty ? assessments.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getMentalHealthStats() async {
    try {
      final assessments = await getMentalHealthAssessments(limit: 100);
      
      if (assessments.isEmpty) {
        return {
          'totalAssessments': 0,
          'averageScore': 0.0,
          'riskTrend': 'unknown',
          'lastAssessmentDate': null,
        };
      }

      double totalScore = 0.0;
      final riskLevels = <String, int>{};
      
      for (final assessment in assessments) {
        totalScore += (assessment['score'] as double? ?? 0.0);
        final riskLevel = assessment['risk_level'] as String? ?? 'unknown';
        riskLevels[riskLevel] = (riskLevels[riskLevel] ?? 0) + 1;
      }

      // Determine trend (simplified)
      String riskTrend = 'stable';
      if (assessments.length >= 2) {
        final latestScore = assessments[0]['score'] as double? ?? 0.0;
        final previousScore = assessments[1]['score'] as double? ?? 0.0;
        
        if (latestScore > previousScore) {
          riskTrend = 'improving';
        } else if (latestScore < previousScore) {
          riskTrend = 'declining';
        }
      }

      return {
        'totalAssessments': assessments.length,
        'averageScore': assessments.length > 0 ? totalScore / assessments.length : 0.0,
        'riskTrend': riskTrend,
        'riskLevels': riskLevels,
        'lastAssessmentDate': assessments.isNotEmpty ? assessments.first['created_at'] : null,
      };
    } catch (e) {
      return {
        'totalAssessments': 0,
        'averageScore': 0.0,
        'riskTrend': 'unknown',
        'lastAssessmentDate': null,
      };
    }
  }

  Future<void> deleteMentalHealthAssessment(String assessmentId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('mental_health_assessments')
            .delete()
            .eq('assessment_id', assessmentId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
