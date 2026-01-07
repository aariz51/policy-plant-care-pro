import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/pregnancy_tools/providers/community_qna_providers.dart';
import 'package:safemama/core/widgets/custom_button.dart';

class CommunityQnaScreen extends ConsumerStatefulWidget {
  const CommunityQnaScreen({super.key});

  @override
  ConsumerState<CommunityQnaScreen> createState() => _CommunityQnaScreenState();
}

class _CommunityQnaScreenState extends ConsumerState<CommunityQnaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityQnaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Q&A'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => _showCategoryFilter(),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by category',
          ),
          IconButton(
            onPressed: () => _showSortOptions(),
            icon: const Icon(Icons.sort),
            tooltip: 'Sort options',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Questions', icon: Icon(Icons.forum)),
            Tab(text: 'My Questions', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryChips(state),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllQuestionsTab(state),
                      _buildMyQuestionsTab(state),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _askNewQuestion(),
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
      ),
    );
  }

  Widget _buildCategoryChips(CommunityQnaState state) {
    final categories = ref.read(communityQnaProvider.notifier).getAvailableCategories();
    final displayNames = ref.read(communityQnaProvider.notifier).getCategoryDisplayNames();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = state.selectedCategory == category;
          
          return FilterChip(
            selected: isSelected,
            label: Text(displayNames[category] ?? category),
            onSelected: (selected) {
              ref.read(communityQnaProvider.notifier).changeCategory(category);
            },
            selectedColor: Colors.blue.withOpacity(0.2),
            checkmarkColor: Colors.blue,
          );
        },
      ),
    );
  }

  Widget _buildAllQuestionsTab(CommunityQnaState state) {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload questions
      },
      child: state.questions.isEmpty
          ? _buildEmptyQuestionsState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildQuestionCard(state.questions[index]);
              },
            ),
    );
  }

  Widget _buildMyQuestionsTab(CommunityQnaState state) {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload user questions
      },
      child: state.userQuestions.isEmpty
          ? _buildEmptyMyQuestionsState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.userQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildQuestionCard(state.userQuestions[index], isMyQuestion: true);
              },
            ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, {bool isMyQuestion = false}) {
    final createdAt = DateTime.parse(question['created_at']);
    final votes = question['votes'] as int? ?? 0;
    final answerCount = question['answer_count'] as int? ?? 0;
    final views = question['views'] as int? ?? 0;
    final isResolved = question['status'] == 'resolved';
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _openQuestion(question),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question['title'] ?? 'Question',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isResolved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Resolved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question['description'] ?? '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuestionStat(Icons.thumb_up, votes.toString()),
                  const SizedBox(width: 16),
                  _buildQuestionStat(Icons.comment, answerCount.toString()),
                  const SizedBox(width: 16),
                  _buildQuestionStat(Icons.visibility, views.toString()),
                  const Spacer(),
                  if (isMyQuestion)
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleMyQuestionAction(question, action),
                      itemBuilder: (context) => [
                        if (!isResolved)
                          const PopupMenuItem(value: 'resolve', child: Text('Mark Resolved')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(question['category']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getCategoryColor(question['category']).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getCategoryDisplayName(question['category']),
                      style: TextStyle(
                        color: _getCategoryColor(question['category']),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyQuestionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to ask a question in this community!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _askNewQuestion(),
              icon: const Icon(Icons.add),
              label: const Text('Ask First Question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMyQuestionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'You haven\'t asked any questions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your first question to get help from the community',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _askNewQuestion(),
              icon: const Icon(Icons.add),
              label: const Text('Ask Question'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'general':
        return Colors.blue;
      case 'symptoms':
        return Colors.orange;
      case 'nutrition':
        return Colors.green;
      case 'exercise':
        return Colors.purple;
      case 'mental_health':
        return Colors.pink;
      case 'labor_delivery':
        return Colors.red;
      case 'postpartum':
        return Colors.teal;
      case 'baby_development':
        return Colors.indigo;
      case 'breastfeeding':
        return Colors.amber;
      case 'sleep':
        return Colors.deepPurple;
      case 'safety':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryDisplayName(String? category) {
    final displayNames = ref.read(communityQnaProvider.notifier).getCategoryDisplayNames();
    return displayNames[category] ?? category ?? 'General';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  // Action methods
  void _askNewQuestion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AskQuestionSheet(),
    );
  }

  void _openQuestion(Map<String, dynamic> question) {
    // Load answers for this question
    ref.read(communityQnaProvider.notifier).loadAnswers(question['id']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionDetailSheet(question: question),
    );
  }

  void _showCategoryFilter() {
    final categories = ref.read(communityQnaProvider.notifier).getAvailableCategories();
    final displayNames = ref.read(communityQnaProvider.notifier).getCategoryDisplayNames();
    final currentCategory = ref.read(communityQnaProvider).selectedCategory;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) => ListTile(
              leading: Icon(
                Icons.circle,
                color: _getCategoryColor(category),
                size: 12,
              ),
              title: Text(displayNames[category] ?? category),
              trailing: currentCategory == category ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(communityQnaProvider.notifier).changeCategory(category);
                Navigator.of(context).pop();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    final currentSort = ref.read(communityQnaProvider).sortBy;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Most Recent'),
              trailing: currentSort == 'recent' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(communityQnaProvider.notifier).changeSortBy('recent');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Most Popular'),
              trailing: currentSort == 'popular' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(communityQnaProvider.notifier).changeSortBy('popular');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Unanswered'),
              trailing: currentSort == 'unanswered' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(communityQnaProvider.notifier).changeSortBy('unanswered');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMyQuestionAction(Map<String, dynamic> question, String action) {
    final notifier = ref.read(communityQnaProvider.notifier);
    
    switch (action) {
      case 'resolve':
        notifier.markQuestionResolved(question['id']);
        break;
      case 'edit':
        // Show edit dialog
        break;
      case 'delete':
        _showDeleteQuestionConfirmation(question);
        break;
    }
  }

  void _showDeleteQuestionConfirmation(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text('Are you sure you want to delete "${question['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(communityQnaProvider.notifier)
                 .deleteQuestion(question['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AskQuestionSheet extends ConsumerStatefulWidget {
  const _AskQuestionSheet();

  @override
  ConsumerState<_AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends ConsumerState<_AskQuestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isAnonymous = false;
  final List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ask a Question',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Question Title *',
                      hintText: 'What would you like to ask?',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: ref.read(communityQnaProvider.notifier)
                        .getAvailableCategories()
                        .where((cat) => cat != 'all')
                        .map((category) {
                      final displayNames = ref.read(communityQnaProvider.notifier)
                          .getCategoryDisplayNames();
                      return DropdownMenuItem(
                        value: category,
                        child: Text(displayNames[category] ?? category),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Provide more details about your question...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
                    maxLines: 6,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tags (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...ref.read(communityQnaProvider.notifier)
                          .getPopularTags()
                          .map((tag) => FilterChip(
                            label: Text(tag.replaceAll('_', ' ')),
                            selected: _selectedTags.contains(tag),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ask anonymously'),
                    subtitle: const Text('Your name won\'t be shown with this question'),
                    value: _isAnonymous,
                    onChanged: (value) => setState(() => _isAnonymous = value),
                  ),
                  const SizedBox(height: 24),
                  CustomElevatedButton(
                    onPressed: _submitQuestion,
                    text: 'Submit Question',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitQuestion() {
    if (_formKey.currentState?.validate() != true) return;

    ref.read(communityQnaProvider.notifier).startNewQuestion(
      category: _selectedCategory,
      pregnancyWeek: null, // Could get from user profile
    );

    ref.read(communityQnaProvider.notifier).updateCurrentQuestion({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'tags': _selectedTags,
      'isAnonymous': _isAnonymous,
    });

    ref.read(communityQnaProvider.notifier).submitQuestion();
    Navigator.of(context).pop();
  }
}

class _QuestionDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;

  const _QuestionDetailSheet({required this.question});

  @override
  ConsumerState<_QuestionDetailSheet> createState() => _QuestionDetailSheetState();
}

class _QuestionDetailSheetState extends ConsumerState<_QuestionDetailSheet> {
  final _answerController = TextEditingController();
  bool _showAnswerForm = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityQnaProvider);
    final createdAt = DateTime.parse(widget.question['created_at']);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Question & Answers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Question Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.question['title'] ?? 'Question',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.question['description'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _voteQuestion(true),
                              icon: const Icon(Icons.thumb_up, size: 16),
                              label: Text('${widget.question['votes'] ?? 0}'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(80, 32),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Asked ${_formatTimeAgo(createdAt)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getCategoryDisplayName(widget.question['category']),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Answer Form
                if (_showAnswerForm)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Answer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _answerController,
                            decoration: const InputDecoration(
                              hintText: 'Share your knowledge and experience...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _submitAnswer,
                                child: const Text('Submit Answer'),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () => setState(() => _showAnswerForm = false),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showAnswerForm = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Write an Answer'),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Answers Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Answers (${state.answers.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (state.answers.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No answers yet'),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first to help answer this question!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...state.answers.map((answer) => _buildAnswerCard(answer)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(Map<String, dynamic> answer) {
    final createdAt = DateTime.parse(answer['created_at']);
    final helpfulVotes = answer['helpful_votes'] as int? ?? 0;
    final isExpert = answer['is_expert_answer'] as bool? ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isExpert)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Expert Answer',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              answer['answer_text'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _voteAnswer(answer['id'], true),
                  icon: const Icon(Icons.thumb_up, size: 16),
                  label: Text('Helpful ($helpfulVotes)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 32),
                  ),
                ),
                const Spacer(),
                Text(
                  'Answered ${_formatTimeAgo(createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String? category) {
    final displayNames = ref.read(communityQnaProvider.notifier).getCategoryDisplayNames();
    return displayNames[category] ?? category ?? 'General';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _voteQuestion(bool isUpvote) {
    ref.read(communityQnaProvider.notifier)
       .voteOnQuestion(widget.question['id'], isUpvote);
  }

  void _voteAnswer(String answerId, bool isHelpful) {
    ref.read(communityQnaProvider.notifier)
       .voteOnAnswer(answerId, isHelpful);
  }

  void _submitAnswer() {
    if (_answerController.text.trim().isEmpty) return;

    ref.read(communityQnaProvider.notifier).startNewAnswer(widget.question['id']);
    ref.read(communityQnaProvider.notifier).updateCurrentAnswer({
      'answerText': _answerController.text.trim(),
    });
    ref.read(communityQnaProvider.notifier).submitAnswer();
    
    setState(() {
      _answerController.clear();
      _showAnswerForm = false;
    });
  }
}
