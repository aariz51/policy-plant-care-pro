import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class CommunityQnaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> submitQuestion(Map<String, dynamic> question) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final questionData = {
        'user_id': user.id,
        'question_id': question['id'],
        'title': question['title'],
        'description': question['description'],
        'category': question['category'],
        'tags': question['tags'],
        'is_anonymous': question['isAnonymous'] ?? false,
        'priority_level': question['priorityLevel'] ?? 'normal',
        'pregnancy_week': question['pregnancyWeek'],
        'status': 'pending',
        'votes': 0,
        'views': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('community_questions')
          .insert(questionData);

      // Save locally for offline viewing
      await _saveQuestionLocally(question);
    } catch (e) {
      await _saveQuestionLocally(question);
      rethrow;
    }
  }

  Future<void> _saveQuestionLocally(Map<String, dynamic> question) async {
    try {
      final List<Map<String, dynamic>> questions = await getUserQuestions();
      questions.insert(0, question);
      
      // Keep only last 20 questions locally
      if (questions.length > 20) {
        questions.removeRange(20, questions.length);
      }

      await _storageService.setString('community_questions', 
          questions.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> submitAnswer(Map<String, dynamic> answer) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final answerData = {
        'user_id': user.id,
        'answer_id': answer['id'],
        'question_id': answer['questionId'],
        'answer_text': answer['answerText'],
        'is_expert_answer': answer['isExpertAnswer'] ?? false,
        'expert_credentials': answer['expertCredentials'],
        'helpful_votes': 0,
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('community_answers')
          .insert(answerData);

      // Update question answer count
      await _supabase.rpc('increment_answer_count', 
          params: {'question_id': answer['questionId']});

    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityQuestions({
    String? category,
    String? sortBy = 'recent',
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('community_questions')
          .select('''
            *,
            community_answers!inner(count),
            profiles!inner(full_name, membership_tier)
          ''');

      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }

      final PostgrestTransformBuilder finalQuery;
      switch (sortBy) {
        case 'popular':
          finalQuery = query.order('votes', ascending: false);
          break;
        case 'recent':
          finalQuery = query.order('created_at', ascending: false);
          break;
        case 'unanswered':
          finalQuery = query.eq('answer_count', 0).order('created_at', ascending: false);
          break;
        default:
          finalQuery = query.order('created_at', ascending: false);
      }

      final response = await finalQuery.limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return await _getCommunityQuestionsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getCommunityQuestionsLocally() async {
    try {
      final questionsStr = await _storageService.getString('community_questions_cache');
      if (questionsStr != null) {
        // Parse questions - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserQuestions({int limit = 20}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('community_questions')
          .select('''
            *,
            community_answers(count)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return await _getUserQuestionsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getUserQuestionsLocally() async {
    try {
      final questionsStr = await _storageService.getString('community_questions');
      if (questionsStr != null) {
        // Parse questions - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getQuestionAnswers(String questionId) async {
    try {
      final response = await _supabase
          .from('community_answers')
          .select('''
            *,
            profiles!inner(full_name, membership_tier)
          ''')
          .eq('question_id', questionId)
          .order('helpful_votes', ascending: false)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> voteQuestion(String questionId, bool isUpvote) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already voted
      final existingVote = await _supabase
          .from('question_votes')
          .select()
          .eq('user_id', user.id)
          .eq('question_id', questionId)
          .maybeSingle();

      if (existingVote != null) {
        // Update existing vote
        await _supabase
            .from('question_votes')
            .update({
              'is_upvote': isUpvote,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id)
            .eq('question_id', questionId);
      } else {
        // Create new vote
        await _supabase
            .from('question_votes')
            .insert({
              'user_id': user.id,
              'question_id': questionId,
              'is_upvote': isUpvote,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      // Update question vote count
      await _supabase.rpc('update_question_votes', 
          params: {'question_id': questionId});

    } catch (e) {
      rethrow;
    }
  }

  Future<void> voteAnswer(String answerId, bool isHelpful) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already voted
      final existingVote = await _supabase
          .from('answer_votes')
          .select()
          .eq('user_id', user.id)
          .eq('answer_id', answerId)
          .maybeSingle();

      if (existingVote == null) {
        // Create new vote
        await _supabase
            .from('answer_votes')
            .insert({
              'user_id': user.id,
              'answer_id': answerId,
              'is_helpful': isHelpful,
              'created_at': DateTime.now().toIso8601String(),
            });

        // Update answer helpful votes
        if (isHelpful) {
          await _supabase.rpc('increment_answer_helpful_votes', 
              params: {'answer_id': answerId});
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final user = _supabase.auth.currentUser;
      final userQuestions = user != null ? await getUserQuestions() : [];
      
      // Get general community stats - FIXED: Using proper count syntax
      final totalQuestionsResponse = await _supabase
          .from('community_questions')
          .select()
          .count(CountOption.exact);
      
      final totalAnswersResponse = await _supabase
          .from('community_answers')
          .select()
          .count(CountOption.exact);

      final totalQuestions = totalQuestionsResponse.count;
      final totalAnswers = totalAnswersResponse.count;

      return {
        'totalQuestions': totalQuestions,
        'totalAnswers': totalAnswers,
        'userQuestions': userQuestions.length,
        'averageResponseTime': '2-4 hours', // This would be calculated from actual data
        'expertAnswerRate': 0.75, // This would be calculated from actual data
      };
    } catch (e) {
      return {
        'totalQuestions': 0,
        'totalAnswers': 0,
        'userQuestions': 0,
        'averageResponseTime': 'Unknown',
        'expertAnswerRate': 0.0,
      };
    }
  }

  Future<void> markQuestionResolved(String questionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('community_questions')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('question_id', questionId)
          .eq('user_id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reportContent({
    required String contentId,
    required String contentType, // 'question' or 'answer'
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('content_reports')
          .insert({
            'reporter_user_id': user.id,
            'content_id': contentId,
            'content_type': contentType,
            'report_reason': reason,
            'additional_info': additionalInfo ?? '',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('community_questions')
          .delete()
          .eq('question_id', questionId)
          .eq('user_id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAnswer(String answerId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('community_answers')
          .delete()
          .eq('answer_id', answerId)
          .eq('user_id', user.id);
    } catch (e) {
      rethrow;
    }
  }
}
