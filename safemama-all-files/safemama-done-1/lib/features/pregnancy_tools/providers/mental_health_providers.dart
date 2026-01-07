import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/mental_health_service.dart';

class MentalHealthState {
  final Map<String, dynamic>? currentAssessment;
  final List<Map<String, dynamic>> assessmentHistory;
  final Map<String, dynamic>? latestAssessment;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;
  final double assessmentProgress;

  const MentalHealthState({
    this.currentAssessment,
    this.assessmentHistory = const [],
    this.latestAssessment,
    this.stats = const {},
    this.isLoading = false,
    this.error,
    this.assessmentProgress = 0.0,
  });

  MentalHealthState copyWith({
    Map<String, dynamic>? currentAssessment,
    List<Map<String, dynamic>>? assessmentHistory,
    Map<String, dynamic>? latestAssessment,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
    double? assessmentProgress,
  }) {
    return MentalHealthState(
      currentAssessment: currentAssessment ?? this.currentAssessment,
      assessmentHistory: assessmentHistory ?? this.assessmentHistory,
      latestAssessment: latestAssessment ?? this.latestAssessment,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      assessmentProgress: assessmentProgress ?? this.assessmentProgress,
    );
  }
}

class MentalHealthNotifier extends StateNotifier<MentalHealthState> {
  final MentalHealthService _service;

  MentalHealthNotifier(this._service) : super(const MentalHealthState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final history = await _service.getMentalHealthAssessments();
      final latestAssessment = await _service.getLatestAssessment();
      final stats = await _service.getMentalHealthStats();

      state = state.copyWith(
        assessmentHistory: history,
        latestAssessment: latestAssessment,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startNewAssessment(String assessmentType) {
    final questions = _getAssessmentQuestions(assessmentType);
    
    state = state.copyWith(
      currentAssessment: {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': assessmentType,
        'questions': questions,
        'responses': <String, dynamic>{},
        'startedAt': DateTime.now().toIso8601String(),
      },
      assessmentProgress: 0.0,
      error: null,
    );
  }

  List<Map<String, dynamic>> _getAssessmentQuestions(String assessmentType) {
    switch (assessmentType) {
      case 'anxiety':
        return _getAnxietyQuestions();
      case 'depression':
        return _getDepressionQuestions();
      case 'stress':
        return _getStressQuestions();
      case 'general':
        return _getGeneralMentalHealthQuestions();
      default:
        return _getGeneralMentalHealthQuestions();
    }
  }

  List<Map<String, dynamic>> _getAnxietyQuestions() {
    return [
      {
        'id': 'anxiety_1',
        'question': 'Over the last 2 weeks, how often have you felt nervous, anxious, or on edge?',
        'type': 'scale',
        'scale': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
        'scores': [0, 1, 2, 3],
      },
      {
        'id': 'anxiety_2',
        'question': 'Over the last 2 weeks, how often have you not been able to stop or control worrying?',
        'type': 'scale',
        'scale': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
        'scores': [0, 1, 2, 3],
      },
      {
        'id': 'anxiety_3',
        'question': 'Over the last 2 weeks, how often have you had trouble relaxing?',
        'type': 'scale',
        'scale': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
        'scores': [0, 1, 2, 3],
      },
      {
        'id': 'anxiety_4',
        'question': 'How would you rate your anxiety related to pregnancy?',
        'type': 'scale',
        'scale': ['None', 'Mild', 'Moderate', 'Severe'],
        'scores': [0, 1, 2, 3],
      },
    ];
  }

  List<Map<String, dynamic>> _getDepressionQuestions() {
    return [
      {
        'id': 'depression_1',
        'question': 'Over the last 2 weeks, how often have you had little interest or pleasure in doing things?',
        'type': 'scale',
        'scale': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
        'scores': [0, 1, 2, 3],
      },
      {
        'id': 'depression_2',
        'question': 'Over the last 2 weeks, how often have you felt down, depressed, or hopeless?',
        'type': 'scale',
        'scale': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
        'scores': [0, 1, 2, 3],
      },
      {
        'id': 'depression_3',
        'question': 'Over the last 2 weeks, how often have you had trouble sleeping or sleeping too much?',
        'type': 'scale',
        'scale': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
        'scores': [0, 1, 2, 3],
      },
      {
        'id': 'depression_4',
        'question': 'How has pregnancy affected your mood overall?',
        'type': 'scale',
        'scale': ['Very positive', 'Somewhat positive', 'No change', 'Somewhat negative', 'Very negative'],
        'scores': [0, 1, 2, 3, 4],
      },
    ];
  }

  List<Map<String, dynamic>> _getStressQuestions() {
    return [
      {
        'id': 'stress_1',
        'question': 'How often have you felt overwhelmed by stress in the past week?',
        'type': 'scale',
        'scale': ['Never', 'Rarely', 'Sometimes', 'Often', 'Very often'],
        'scores': [0, 1, 2, 3, 4],
      },
      {
        'id': 'stress_2',
        'question': 'How well do you feel you are coping with pregnancy-related changes?',
        'type': 'scale',
        'scale': ['Very well', 'Well', 'Okay', 'Poorly', 'Very poorly'],
        'scores': [0, 1, 2, 3, 4],
      },
      {
        'id': 'stress_3',
        'question': 'How often do you worry about your baby\'s health?',
        'type': 'scale',
        'scale': ['Never', 'Rarely', 'Sometimes', 'Often', 'Constantly'],
        'scores': [0, 1, 2, 3, 4],
      },
    ];
  }

  List<Map<String, dynamic>> _getGeneralMentalHealthQuestions() {
    return [
      {
        'id': 'general_1',
        'question': 'How would you rate your overall mental health today?',
        'type': 'scale',
        'scale': ['Excellent', 'Very good', 'Good', 'Fair', 'Poor'],
        'scores': [4, 3, 2, 1, 0],
      },
      {
        'id': 'general_2',
        'question': 'How satisfied are you with your support system during pregnancy?',
        'type': 'scale',
        'scale': ['Very satisfied', 'Satisfied', 'Neutral', 'Dissatisfied', 'Very dissatisfied'],
        'scores': [4, 3, 2, 1, 0],
      },
    ];
  }

  void answerQuestion(String questionId, dynamic answer) {
    if (state.currentAssessment == null) return;

    final currentAssessment = Map<String, dynamic>.from(state.currentAssessment!);
    final responses = Map<String, dynamic>.from(currentAssessment['responses']);
    responses[questionId] = answer;
    currentAssessment['responses'] = responses;

    // Calculate progress
    final questions = currentAssessment['questions'] as List;
    final progress = responses.length / questions.length;

    state = state.copyWith(
      currentAssessment: currentAssessment,
      assessmentProgress: progress,
    );
  }

  Future<void> submitAssessment() async {
    if (state.currentAssessment == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final assessment = Map<String, dynamic>.from(state.currentAssessment!);
      
      // Calculate score and risk level
      final result = _calculateAssessmentResult(assessment);
      assessment['score'] = result['score'];
      assessment['riskLevel'] = result['riskLevel'];
      assessment['recommendations'] = result['recommendations'];
      assessment['completedAt'] = DateTime.now().toIso8601String();

      // Save assessment
      await _service.saveMentalHealthAssessment(assessment);

      // Reload data
      await _loadData();

      // Clear current assessment
      state = state.copyWith(
        currentAssessment: null,
        assessmentProgress: 0.0,
        isLoading: false,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Map<String, dynamic> _calculateAssessmentResult(Map<String, dynamic> assessment) {
    final responses = assessment['responses'] as Map<String, dynamic>;
    final questions = assessment['questions'] as List<Map<String, dynamic>>;
    
    double totalScore = 0.0;
    int totalQuestions = questions.length;
    
    for (final question in questions) {
      final questionId = question['id'];
      final response = responses[questionId];
      
      if (response != null && question['scores'] != null) {
        final scores = question['scores'] as List<int>;
        if (response is int && response < scores.length) {
          totalScore += scores[response];
        }
      }
    }
    
    // Calculate percentage score
    final maxPossibleScore = questions.fold<int>(0, (sum, q) {
      final scores = q['scores'] as List<int>?;
      return sum + (scores?.reduce((a, b) => a > b ? a : b) ?? 0);
    });
    
    final percentageScore = maxPossibleScore > 0 ? (totalScore / maxPossibleScore) * 100 : 0.0;
    
    // Determine risk level and recommendations
    String riskLevel;
    List<String> recommendations;
    
    if (percentageScore <= 25) {
      riskLevel = 'low';
      recommendations = [
        'Continue with regular self-care practices',
        'Maintain your current support system',
        'Keep up healthy pregnancy routines',
      ];
    } else if (percentageScore <= 50) {
      riskLevel = 'mild';
      recommendations = [
        'Consider talking to a healthcare provider',
        'Practice relaxation techniques daily',
        'Reach out to friends and family for support',
        'Consider prenatal yoga or meditation',
      ];
    } else if (percentageScore <= 75) {
      riskLevel = 'moderate';
      recommendations = [
        'Speak with your healthcare provider soon',
        'Consider counseling or therapy',
        'Join a pregnancy support group',
        'Prioritize sleep and stress management',
      ];
    } else {
      riskLevel = 'high';
      recommendations = [
        'Contact your healthcare provider immediately',
        'Consider professional mental health support',
        'Reach out to pregnancy mental health resources',
        'Don\'t hesitate to ask for help from loved ones',
      ];
    }
    
    return {
      'score': percentageScore,
      'riskLevel': riskLevel,
      'recommendations': recommendations,
    };
  }

  void clearCurrentAssessment() {
    state = state.copyWith(
      currentAssessment: null,
      assessmentProgress: 0.0,
      error: null,
    );
  }

  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _service.deleteMentalHealthAssessment(assessmentId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final mentalHealthServiceProvider = Provider<MentalHealthService>((ref) {
  return MentalHealthService();
});

final mentalHealthProvider = StateNotifierProvider<MentalHealthNotifier, MentalHealthState>((ref) {
  final service = ref.watch(mentalHealthServiceProvider);
  return MentalHealthNotifier(service);
});
