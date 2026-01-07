import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/community_qna_service.dart';

class CommunityQnaState {
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> userQuestions;
  final List<Map<String, dynamic>> answers;
  final Map<String, dynamic>? currentQuestion;
  final Map<String, dynamic>? currentAnswer;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;
  final String selectedCategory;
  final String sortBy;

  const CommunityQnaState({
    this.questions = const [],
    this.userQuestions = const [],
    this.answers = const [],
    this.currentQuestion,
    this.currentAnswer,
    this.stats = const {},
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'all',
    this.sortBy = 'recent',
  });

  CommunityQnaState copyWith({
    List<Map<String, dynamic>>? questions,
    List<Map<String, dynamic>>? userQuestions,
    List<Map<String, dynamic>>? answers,
    Map<String, dynamic>? currentQuestion,
    Map<String, dynamic>? currentAnswer,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? sortBy,
  }) {
    return CommunityQnaState(
      questions: questions ?? this.questions,
      userQuestions: userQuestions ?? this.userQuestions,
      answers: answers ?? this.answers,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      currentAnswer: currentAnswer ?? this.currentAnswer,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class CommunityQnaNotifier extends StateNotifier<CommunityQnaState> {
  final CommunityQnaService _service;

  CommunityQnaNotifier(this._service) : super(const CommunityQnaState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final questions = await _service.getCommunityQuestions(
        category: state.selectedCategory != 'all' ? state.selectedCategory : null,
        sortBy: state.sortBy,
      );
      final userQuestions = await _service.getUserQuestions();
      final stats = await _service.getCommunityStats();

      state = state.copyWith(
        questions: questions,
        userQuestions: userQuestions,
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

  Future<void> loadAnswers(String questionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final answers = await _service.getQuestionAnswers(questionId);
      state = state.copyWith(
        answers: answers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startNewQuestion({
    required String category,
    int? pregnancyWeek,
  }) {
    final question = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': '',
      'description': '',
      'category': category,
      'tags': <String>[],
      'isAnonymous': false,
      'priorityLevel': 'normal',
      'pregnancyWeek': pregnancyWeek,
    };

    state = state.copyWith(currentQuestion: question, error: null);
  }

  void startNewAnswer(String questionId) {
    final answer = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'questionId': questionId,
      'answerText': '',
      'isExpertAnswer': false,
      'expertCredentials': null,
    };

    state = state.copyWith(currentAnswer: answer, error: null);
  }

  void updateCurrentQuestion(Map<String, dynamic> updates) {
    if (state.currentQuestion == null) return;

    final updatedQuestion = {...state.currentQuestion!, ...updates};
    state = state.copyWith(currentQuestion: updatedQuestion);
  }

  void updateCurrentAnswer(Map<String, dynamic> updates) {
    if (state.currentAnswer == null) return;

    final updatedAnswer = {...state.currentAnswer!, ...updates};
    state = state.copyWith(currentAnswer: updatedAnswer);
  }

  void addTagToCurrentQuestion(String tag) {
    if (state.currentQuestion == null) return;

    final currentTags = List<String>.from(state.currentQuestion!['tags'] ?? []);
    if (!currentTags.contains(tag)) {
      currentTags.add(tag);
      updateCurrentQuestion({'tags': currentTags});
    }
  }

  void removeTagFromCurrentQuestion(String tag) {
    if (state.currentQuestion == null) return;

    final currentTags = List<String>.from(state.currentQuestion!['tags'] ?? []);
    currentTags.remove(tag);
    updateCurrentQuestion({'tags': currentTags});
  }

  Future<void> submitQuestion() async {
    if (state.currentQuestion == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.submitQuestion(state.currentQuestion!);
      
      state = state.copyWith(
        currentQuestion: null,
        isLoading: false,
      );
      
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> submitAnswer() async {
    if (state.currentAnswer == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.submitAnswer(state.currentAnswer!);
      
      final questionId = state.currentAnswer!['questionId'] as String;
      
      state = state.copyWith(
        currentAnswer: null,
        isLoading: false,
      );
      
      // Reload answers for the question
      await loadAnswers(questionId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> voteOnQuestion(String questionId, bool isUpvote) async {
    try {
      await _service.voteQuestion(questionId, isUpvote);
      await _loadData(); // Reload to show updated vote counts
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> voteOnAnswer(String answerId, bool isHelpful) async {
    try {
      await _service.voteAnswer(answerId, isHelpful);
      // Reload the current question's answers
      if (state.answers.isNotEmpty) {
        final questionId = state.answers.first['question_id'] as String;
        await loadAnswers(questionId);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void changeCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _loadData();
  }

  void changeSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _loadData();
  }

  Future<void> markQuestionResolved(String questionId) async {
    try {
      await _service.markQuestionResolved(questionId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      await _service.reportContent(
        contentId: contentId,
        contentType: contentType,
        reason: reason,
        additionalInfo: additionalInfo,
      );
      
      // Show success message (you might want to add this to state)
      // For now, we'll just clear any errors
      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _service.deleteQuestion(questionId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAnswer(String answerId) async {
    try {
      await _service.deleteAnswer(answerId);
      // Reload the current question's answers
      if (state.answers.isNotEmpty) {
        final questionId = state.answers.first['question_id'] as String;
        await loadAnswers(questionId);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<String> getAvailableCategories() {
    return [
      'all',
      'general',
      'symptoms',
      'nutrition',
      'exercise',
      'mental_health',
      'labor_delivery',
      'postpartum',
      'baby_development',
      'breastfeeding',
      'sleep',
      'safety',
    ];
  }

  List<String> getPopularTags() {
    return [
      'first_trimester',
      'second_trimester',
      'third_trimester',
      'high_risk',
      'twins',
      'morning_sickness',
      'weight_gain',
      'prenatal_vitamins',
      'exercise',
      'travel',
      'work',
      'partner_support',
    ];
  }

  Map<String, String> getCategoryDisplayNames() {
    return {
      'all': 'All Categories',
      'general': 'General Questions',
      'symptoms': 'Symptoms & Changes',
      'nutrition': 'Nutrition & Diet',
      'exercise': 'Exercise & Fitness',
      'mental_health': 'Mental Health',
      'labor_delivery': 'Labor & Delivery',
      'postpartum': 'Postpartum',
      'baby_development': 'Baby Development',
      'breastfeeding': 'Breastfeeding',
      'sleep': 'Sleep',
      'safety': 'Safety & Concerns',
    };
  }

  void cancelCurrentQuestion() {
    state = state.copyWith(currentQuestion: null, error: null);
  }

  void cancelCurrentAnswer() {
    state = state.copyWith(currentAnswer: null, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearAnswers() {
    state = state.copyWith(answers: []);
  }
}

// Providers
final communityQnaServiceProvider = Provider<CommunityQnaService>((ref) {
  return CommunityQnaService();
});

final communityQnaProvider = StateNotifierProvider<CommunityQnaNotifier, CommunityQnaState>((ref) {
  final service = ref.watch(communityQnaServiceProvider);
  return CommunityQnaNotifier(service);
});
