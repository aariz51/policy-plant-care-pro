import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/pregnancy_tools/providers/mental_health_providers.dart';
import 'package:safemama/core/widgets/custom_button.dart';

class MentalHealthAssessmentScreen extends ConsumerStatefulWidget {
  const MentalHealthAssessmentScreen({super.key});

  @override
  ConsumerState<MentalHealthAssessmentScreen> createState() => _MentalHealthAssessmentScreenState();
}

class _MentalHealthAssessmentScreenState extends ConsumerState<MentalHealthAssessmentScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentalHealthProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.currentAssessment != null
              ? _buildAssessmentView(state)
              : _buildMainView(state),
    );
  }

  Widget _buildMainView(MentalHealthState state) {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload data
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(state),
            const SizedBox(height: 24),
            _buildQuickAssessmentSection(),
            const SizedBox(height: 24),
            _buildLatestAssessment(state),
            const SizedBox(height: 24),
            _buildAssessmentHistory(state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(MentalHealthState state) {
    final stats = state.stats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Mental Health Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Assessments',
                '${stats['totalAssessments'] ?? 0}',
                Icons.assessment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Average Score',
                '${(stats['averageScore'] as double? ?? 0.0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        if (stats['riskTrend'] != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTrendColor(stats['riskTrend']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getTrendColor(stats['riskTrend']).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _getTrendIcon(stats['riskTrend']),
                  color: _getTrendColor(stats['riskTrend']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trend: ${_getTrendText(stats['riskTrend'])}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getTrendColor(stats['riskTrend']),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTrendDescription(stats['riskTrend']),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAssessmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Take Assessment',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAssessmentTypeCard(
              'Anxiety',
              'GAD-7 Assessment',
              Icons.psychology,
              Colors.orange,
              'anxiety',
            ),
            _buildAssessmentTypeCard(
              'Depression',
              'PHQ-9 Assessment',
              Icons.mood,
              Colors.purple,
              'depression',
            ),
            _buildAssessmentTypeCard(
              'Stress',
              'Stress Level Check',
              Icons.spa, // stress_management doesn't exist, using spa as alternative
              Colors.red,
              'stress',
            ),
            _buildAssessmentTypeCard(
              'General',
              'Overall Wellbeing',
              Icons.favorite,
              Colors.pink,
              'general',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssessmentTypeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String type,
  ) {
    return InkWell(
      onTap: () => _startAssessment(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestAssessment(MentalHealthState state) {
    if (state.latestAssessment == null) {
      return _buildEmptyState(
        'No assessments yet',
        'Take your first mental health assessment to track your wellbeing',
        Icons.psychology,
      );
    }

    final assessment = state.latestAssessment!;
    final riskLevel = assessment['riskLevel'] as String;
    final score = assessment['score'] as double;
    final date = DateTime.parse(assessment['completedAt'] ?? assessment['createdAt']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Assessment',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getRiskLevelColor(riskLevel).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getRiskLevelColor(riskLevel).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${assessment['type']} Assessment'.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRiskLevelColor(riskLevel),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getRiskLevelColor(riskLevel),
                    radius: 24,
                    child: Text(
                      '${score.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getRiskLevelText(riskLevel)} Risk Level',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRiskLevelColor(riskLevel),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRiskLevelDescription(riskLevel),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (assessment['recommendations'] != null)
                ..._buildRecommendations(assessment['recommendations']),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRecommendations(List<dynamic> recommendations) {
    return [
      const SizedBox(height: 16),
      const Text(
        'Recommendations:',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      ...recommendations.take(3).map((rec) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 12))),
          ],
        ),
      )),
    ];
  }

  Widget _buildAssessmentHistory(MentalHealthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assessment History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.assessmentHistory.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to full history
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.assessmentHistory.isEmpty)
          _buildEmptyState(
            'No assessment history',
            'Complete assessments to track your mental health progress',
            Icons.history,
          )
        else
          ...state.assessmentHistory.take(5).map((assessment) => 
            _buildHistoryCard(assessment)),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> assessment) {
    final date = DateTime.parse(assessment['completedAt'] ?? assessment['createdAt']);
    final riskLevel = assessment['riskLevel'] as String;
    final score = assessment['score'] as double;
    final type = assessment['type'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRiskLevelColor(riskLevel),
          child: Text(
            '${score.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        title: Text(
          '${type.substring(0, 1).toUpperCase()}${type.substring(1)} Assessment',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(date)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRiskLevelColor(riskLevel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_getRiskLevelText(riskLevel)} Risk',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleHistoryAction(assessment, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showAssessmentDetails(assessment),
      ),
    );
  }

  Widget _buildAssessmentView(MentalHealthState state) {
    final assessment = state.currentAssessment!;
    final questions = assessment['questions'] as List<Map<String, dynamic>>;
    final responses = assessment['responses'] as Map<String, dynamic>;
    final currentQuestionIndex = responses.length;
    
    if (currentQuestionIndex >= questions.length) {
      return _buildAssessmentComplete(state);
    }

    final currentQuestion = questions[currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProgressIndicator(state),
          const SizedBox(height: 24),
          Expanded(
            child: _buildQuestionCard(currentQuestion, currentQuestionIndex + 1, questions.length),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(MentalHealthState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${state.currentAssessment!['type']} Assessment'.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            IconButton(
              onPressed: () => _cancelAssessment(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: state.assessmentProgress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          '${(state.assessmentProgress * 100).toInt()}% Complete',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int current, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $current of $total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildAnswerOptions(question),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(Map<String, dynamic> question) {
    final scale = question['scale'] as List<String>;
    
    return ListView.separated(
      itemCount: scale.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => _answerQuestion(question['id'], index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    scale[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssessmentComplete(MentalHealthState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Assessment Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thank you for completing the assessment. Your responses will help track your mental health journey.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          CustomElevatedButton(
            onPressed: () => _submitAssessment(),
            text: 'Submit Assessment',
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _cancelAssessment(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return Colors.green;
      case 'mild':
        return Colors.yellow[700]!;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRiskLevelText(String riskLevel) {
    return riskLevel.substring(0, 1).toUpperCase() + riskLevel.substring(1);
  }

  String _getRiskLevelDescription(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return 'You\'re doing well with your mental health';
      case 'mild':
        return 'Some signs of stress or concern, but manageable';
      case 'moderate':
        return 'Consider talking to a healthcare provider';
      case 'high':
        return 'Please reach out for professional support';
      default:
        return '';
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      case 'declining':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'stable':
        return Icons.trending_flat;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.help;
    }
  }

  String _getTrendText(String trend) {
    return trend.substring(0, 1).toUpperCase() + trend.substring(1);
  }

  String _getTrendDescription(String trend) {
    switch (trend) {
      case 'improving':
        return 'Your mental health scores are improving';
      case 'stable':
        return 'Your mental health scores remain consistent';
      case 'declining':
        return 'Consider additional support';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  // Action methods
  void _startAssessment(String type) {
    ref.read(mentalHealthProvider.notifier).startNewAssessment(type);
  }

  void _answerQuestion(String questionId, int answerIndex) {
    ref.read(mentalHealthProvider.notifier).answerQuestion(questionId, answerIndex);
  }

  void _submitAssessment() {
    ref.read(mentalHealthProvider.notifier).submitAssessment();
  }

  void _cancelAssessment() {
    ref.read(mentalHealthProvider.notifier).clearCurrentAssessment();
  }

  void _handleHistoryAction(Map<String, dynamic> assessment, String action) {
    switch (action) {
      case 'view':
        _showAssessmentDetails(assessment);
        break;
      case 'delete':
        _showDeleteConfirmation(assessment);
        break;
    }
  }

  void _showAssessmentDetails(Map<String, dynamic> assessment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AssessmentDetailsSheet(assessment: assessment),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: const Text('Are you sure you want to delete this assessment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(mentalHealthProvider.notifier)
                 .deleteAssessment(assessment['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AssessmentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> assessment;

  const _AssessmentDetailsSheet({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(assessment['completedAt'] ?? assessment['createdAt']);
    final riskLevel = assessment['riskLevel'] as String;
    final score = assessment['score'] as double;
    final recommendations = assessment['recommendations'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Assessment Details',
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Assessment Type', '${assessment['type']}'.toUpperCase()),
                  _buildDetailRow('Date', _formatDate(date)),
                  _buildDetailRow('Score', '${score.toStringAsFixed(1)}%'),
                  _buildDetailRow('Risk Level', _getRiskLevelText(riskLevel)),
                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Recommendations:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(rec.toString())),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _getRiskLevelText(String riskLevel) {
    return riskLevel.substring(0, 1).toUpperCase() + riskLevel.substring(1);
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
