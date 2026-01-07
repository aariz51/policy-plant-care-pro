import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/premium_feature_wrapper.dart';
import 'package:safemama/features/pregnancy_tools/providers/vaccine_tracker_providers.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/features/pregnancy_tools/screens/streaming_ai_result_screen.dart';
import 'package:safemama/core/utils/share_helper.dart';

class VaccineTrackerScreen extends ConsumerStatefulWidget {
  const VaccineTrackerScreen({super.key});

  @override
  ConsumerState<VaccineTrackerScreen> createState() => _VaccineTrackerScreenState();
}

class _VaccineTrackerScreenState extends ConsumerState<VaccineTrackerScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingAI = false;
  int? _babyAgeMonths;
  List<String> _completedVaccines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVaccineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVaccineData() async {
    try {
      // Load from local storage or initialize empty
      setState(() {
        _babyAgeMonths = 0;  // Default value
        _completedVaccines = [];
      });
    } catch (e) {
      print('Error loading vaccine data: $e');
      setState(() {
        _babyAgeMonths = 0;
        _completedVaccines = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final profile = userProfile.userProfile;
    final isPremium = profile?.isPremiumUser ?? false;

    return PremiumFeatureWrapper(
      isPremiumUser: isPremium,
      onTapWhenFree: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Premium Feature'),
            content: const Text('Vaccine Tracker with AI insights is a premium feature. Upgrade to access this tool.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to upgrade - will be handled by PremiumFeatureWrapper
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
      },
      featureName: 'Vaccine Tracker',
      currentCount: 0,
      limit: -1,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Vaccine Tracker'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(),
              tooltip: 'How to use',
            ),
            if (isPremium)
              IconButton(
                icon: _isLoadingAI 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                onPressed: _isLoadingAI ? null : _getAIRecommendations,
                tooltip: 'AI Insights',
              ),
            IconButton(
              onPressed: _shareVaccineProgress,
              icon: const Icon(Icons.share),
              tooltip: 'Share Progress',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Schedule', icon: Icon(Icons.calendar_today)),
              Tab(text: 'History', icon: Icon(Icons.history)),
              Tab(text: 'AI Insights', icon: Icon(Icons.auto_awesome)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildScheduleTab(),
            _buildHistoryTab(),
            _buildAIInsightsTab(),
          ],
        ),
        floatingActionButton: isPremium
            ? FloatingActionButton.extended(
                onPressed: () => _addVaccineRecord(),
                backgroundColor: AppTheme.primaryPurple,
                icon: const Icon(Icons.add),
                label: const Text('Add Record'),
              )
            : null,
      ),
    );
  }

  Widget _buildScheduleTab() {
    final state = ref.watch(vaccineTrackerProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(vaccineTrackerProvider.notifier).loadVaccines();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildBabyAgeInput(),
            const SizedBox(height: 24),
            _buildUpcomingVaccines(state),
            const SizedBox(height: 24),
            _buildVaccineSchedule(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vaccines,
                size: 32,
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Child Vaccine Tracker',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your child\'s vaccination schedule',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBabyAgeInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Baby\'s Age',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age in months',
                hintText: 'Enter baby\'s age',
                border: OutlineInputBorder(),
                suffixText: 'months',
              ),
              onChanged: (value) {
                setState(() {
                  _babyAgeMonths = int.tryParse(value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingVaccines(VaccineTrackerState state) {
    final upcoming = state.upcomingVaccines;
    
    if (upcoming.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: AppTheme.safeGreen),
              const SizedBox(height: 16),
              Text(
                'All Upcoming Vaccines Scheduled',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Vaccines',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...upcoming.take(5).map((vaccine) => _buildVaccineCard(vaccine, isUpcoming: true)),
      ],
    );
  }

  Widget _buildVaccineSchedule(VaccineTrackerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Schedule',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...state.vaccineSchedule.map((vaccine) => _buildVaccineCard(vaccine, isUpcoming: false)),
      ],
    );
  }

  Widget _buildVaccineCard(Map<String, dynamic> vaccine, {required bool isUpcoming}) {
    final name = vaccine['name'] as String? ?? 'Unknown Vaccine';
    final dueDate = vaccine['dueDate'];
    final completed = vaccine['completed'] as bool? ?? false;
    DateTime? date;
    
    // Safe date parsing with error handling
    if (dueDate != null) {
      try {
        date = DateTime.parse(dueDate as String);
      } catch (e) {
        print('Error parsing date: $e');
        date = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: completed 
              ? AppTheme.safeGreen.withOpacity(0.2)
              : isUpcoming
                  ? AppTheme.warningOrange.withOpacity(0.2)
                  : AppTheme.textSecondary.withOpacity(0.2),
          child: Icon(
            completed ? Icons.check_circle : Icons.vaccines,
            color: completed 
                ? AppTheme.safeGreen
                : isUpcoming
                    ? AppTheme.warningOrange
                    : AppTheme.textSecondary,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: date != null
            ? Text(DateFormat('MMM dd, yyyy').format(date))
            : const Text('Date TBD'),
        trailing: isUpcoming && !completed
            ? TextButton(
                onPressed: () => _markAsCompleted(vaccine),
                child: const Text('Mark Done'),
              )
            : null,
        onTap: () {
          if (!completed && !_completedVaccines.contains(name)) {
            setState(() {
              _completedVaccines.add(name);
            });
          }
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    final state = ref.watch(vaccineTrackerProvider);
    
    if (state.completedVaccines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No completed vaccines yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.completedVaccines.length,
      itemBuilder: (context, index) {
        final vaccine = state.completedVaccines[index];
        return _buildVaccineCard(vaccine, isUpcoming: false);
      },
    );
  }

  Widget _buildAIInsightsTab() {
    final state = ref.watch(vaccineTrackerProvider);
    
    if (!state.hasAIInsights) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: AppTheme.primaryPurple),
            const SizedBox(height: 16),
            Text(
              'Get AI-Powered Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI will analyze your child\'s vaccination\nhistory and provide personalized recommendations',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoadingAI ? null : _getAIRecommendations,
              icon: _isLoadingAI 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoadingAI ? 'Generating...' : 'Generate AI Insights'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.aiInsights != null) ...[
            _buildInsightCard(
              'Vaccination Status',
              state.aiInsights!['status'] ?? 'Analysis in progress...',
              Icons.health_and_safety,
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              'Recommendations',
              state.aiInsights!['recommendations'] ?? 'No recommendations available.',
              Icons.lightbulb,
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              'Next Steps',
              state.aiInsights!['nextSteps'] ?? 'Continue following the schedule.',
              Icons.navigate_next,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String content, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryPurple),
            SizedBox(width: 12),
            Flexible(child: Text('Vaccine Tracker Guide')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track your child\'s vaccination schedule and get AI-powered insights.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoItem('1️⃣', 'View upcoming vaccines and due dates.'),
              const SizedBox(height: 12),
              _buildInfoItem('2️⃣', 'Mark vaccines as completed when administered.'),
              const SizedBox(height: 12),
              _buildInfoItem('3️⃣', 'Get AI insights on vaccination status and recommendations.'),
              const SizedBox(height: 12),
              _buildInfoItem('4️⃣', 'Track complete vaccination history.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _getAIRecommendations() async {
    if (_babyAgeMonths == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter baby\'s age')),
      );
      return;
    }

    try {
      // Create streaming response
      final stream = ref.read(apiServiceProvider).vaccineTrackerAIStream(
        babyAgeMonths: _babyAgeMonths!,
        completedVaccines: _completedVaccines,
      );

      // Navigate to streaming AI result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreamingAIResultScreen(
            title: 'Vaccine Recommendations',
            icon: Icons.vaccines,
            color: AppTheme.primaryPurple,
            responseStream: stream,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _addVaccineRecord() {
    // TODO: Implement add vaccine record dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add vaccine record feature coming soon!')),
    );
  }

  Future<void> _shareVaccineProgress() async {
    try {
      final state = ref.read(vaccineTrackerProvider);
      
      // Count completed vaccines from state
      final totalVaccines = state.vaccineSchedule.length;
      final completedVaccines = state.vaccineSchedule
          .where((v) => v['isCompleted'] == true)
          .length;

      await ShareHelper.shareVaccineTracker(
        completedVaccines: completedVaccines,
        totalVaccines: totalVaccines,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to share: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _markAsCompleted(Map<String, dynamic> vaccine) {
    final name = vaccine['name'] as String? ?? 'Unknown';
    setState(() {
      if (!_completedVaccines.contains(name)) {
        _completedVaccines.add(name);
      }
    });
    ref.read(vaccineTrackerProvider.notifier).markVaccineAsCompleted(vaccine['id'] as String);
  }
}

// AIResultScreen widget (add this if it doesn't exist)
class AIResultScreen extends StatelessWidget {
  final String title;
  final String analysis;
  final IconData icon;
  final Color color;

  const AIResultScreen({
    Key? key,
    required this.title,
    required this.analysis,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 20),
            Text(
              analysis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
