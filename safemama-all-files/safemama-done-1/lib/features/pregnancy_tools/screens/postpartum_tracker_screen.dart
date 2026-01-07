// lib/features/pregnancy_tools/screens/postpartum_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/providers/postpartum_tracker_providers.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/features/pregnancy_tools/screens/streaming_ai_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/utils/share_helper.dart';

class PostpartumTrackerScreen extends ConsumerStatefulWidget {
  const PostpartumTrackerScreen({super.key});

  @override
  ConsumerState<PostpartumTrackerScreen> createState() => _PostpartumTrackerScreenState();
}

class _PostpartumTrackerScreenState extends ConsumerState<PostpartumTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingAI = false;
  bool _hasCheckedFirstTime = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postpartumTrackerProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isPremium = userProfile.userProfile?.isPremiumUser ?? false;

    // Check if this is first-time user (only once per screen load)
    if (!_hasCheckedFirstTime && !state.isLoading) {
      _hasCheckedFirstTime = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkFirstTimeUser(state);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postpartum Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'How to use',
          ),
          if (isPremium && state.postpartumEntries.isNotEmpty)
            IconButton(
              icon: _isLoadingAI
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              onPressed: _isLoadingAI ? null : _getAIGuidance,
              tooltip: 'Get AI Guidance',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePostpartumProgress,
            tooltip: 'Share Progress',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showQuickActions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Today'),
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.star), text: 'Milestones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(state),
          _buildProgressTab(state),
          _buildMilestonesTab(state),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewEntry(),
        icon: const Icon(Icons.add),
        label: const Text('Log Entry'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }

  Widget _buildTodayTab(PostpartumTrackerState state) {
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
            _buildQuickMoodCheck(state),
            const SizedBox(height: 24),
            _buildTodayEntry(state),
            const SizedBox(height: 24),
            _buildQuickTrackingButtons(),
            const SizedBox(height: 24),
            _buildRecommendations(state),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMoodCheck(PostpartumTrackerState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMoodButton('😢', 'Struggling', 1.0, Colors.red),
                _buildMoodButton('😟', 'Difficult', 2.0, Colors.orange),
                _buildMoodButton('😐', 'Okay', 3.0, Colors.yellow[700]!),
                _buildMoodButton('🙂', 'Good', 4.0, Colors.green),
                _buildMoodButton('😊', 'Great', 5.0, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String label, double value, Color color) {
    return GestureDetector(
      onTap: () => _logQuickMood(value),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayEntry(PostpartumTrackerState state) {
    if (state.todayEntry == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No entry for today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your recovery progress by logging today\'s entry',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _startNewEntry(),
                child: const Text('Log Today\'s Entry'),
              ),
            ],
          ),
        ),
      );
    }

    final entry = state.todayEntry!;
    final moodValue = entry['moodRating'] as double? ?? 3.0;
    final mood = moodValue < 1.0 ? 3.0 : moodValue; // Ensure mood is at least 1.0 for slider
    final pain = entry['painLevel'] as double? ?? 0.0;
    final symptoms = entry['physicalSymptoms'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Entry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _editTodayEntry(entry),
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Mood', '${mood.toInt()}/5', _getMoodColor(mood)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Pain', '${pain.toInt()}/10', _getPainColor(pain)),
                ),
              ],
            ),
            if (symptoms.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Physical Symptoms:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: symptoms.map((symptom) => Chip(
                      label: Text(symptom.toString()),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTrackingButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Tracking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildQuickTrackCard(
              'Physical Recovery',
              Icons.healing,
              Colors.blue,
              () => _startNewEntry('physical'),
            ),
            _buildQuickTrackCard(
              'Feeding Session',
              Icons.baby_changing_station,
              Colors.green,
              () => _startNewEntry('feeding'),
            ),
            _buildQuickTrackCard(
              'Sleep Log',
              Icons.bedtime,
              Colors.purple,
              () => _startNewEntry('sleep'),
            ),
            _buildQuickTrackCard(
              'Baby Update',
              Icons.child_care,
              Colors.orange,
              () => _startNewEntry('baby'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTrackCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(PostpartumTrackerState state) {
    final recommendations = ref.read(postpartumTrackerProvider.notifier).getRecoveryRecommendations();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recovery Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.take(4).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab(PostpartumTrackerState state) {
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
            _buildStatsOverview(state),
            const SizedBox(height: 24),
            _buildRecoveryChart(state),
            const SizedBox(height: 24),
            _buildRecentEntries(state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(PostpartumTrackerState state) {
    final stats = state.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recovery Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Entries',
                '${stats['totalEntries'] ?? 0}',
                Icons.notes,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'Avg Mood',
                '${(stats['averageMoodRating'] as double? ?? 0.0).toStringAsFixed(1)}/5',
                Icons.mood,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Recovery Progress',
                '${((stats['recoveryProgress'] as double? ?? 0.0) * 100).toInt()}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'Milestones',
                '${stats['totalMilestones'] ?? 0}',
                Icons.star,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryChart(PostpartumTrackerState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Progress Chart',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chart visualization would go here',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(PostpartumTrackerState state) {
    final entries = state.postpartumEntries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full history
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No entries yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Start tracking your postpartum recovery',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...entries.map((entry) => _buildEntryCard(entry)),
      ],
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final date = DateTime.parse(entry['date'] ?? entry['entry_date']);
    final mood = entry['moodRating'] as double? ?? 0.0;
    final type = entry['type'] as String? ?? 'general';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEntryTypeColor(type),
          child: Icon(
            _getEntryTypeIcon(type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _getEntryTypeDisplayName(type),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mood: ${mood.toInt()}/5 • ${_formatDate(date)}'),
            if (entry['notes'] != null && entry['notes'].isNotEmpty)
              Text(
                entry['notes'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleEntryAction(entry, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showEntryDetails(entry),
      ),
    );
  }

  Widget _buildMilestonesTab(PostpartumTrackerState state) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recovery Milestones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addMilestone(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.milestones.isEmpty)
              _buildEmptyMilestonesCard()
            else
              ...state.milestones.map((milestone) => _buildMilestoneCard(milestone)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMilestonesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.star_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No milestones yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Celebrate your recovery journey by adding milestones',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addMilestone(),
              child: const Text('Add First Milestone'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final date = DateTime.parse(milestone['achievedDate']);
    final week = milestone['weekPostpartum'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMilestoneTypeColor(milestone['type']),
          child: const Icon(
            Icons.star,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          milestone['title'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Week $week postpartum • ${_formatDate(date)}'),
            if (milestone['description'] != null && milestone['description'].isNotEmpty)
              Text(
                milestone['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMilestoneAction(milestone, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getMoodColor(double mood) {
    if (mood <= 2) return Colors.red;
    if (mood <= 3) return Colors.orange;
    if (mood <= 4) return Colors.yellow[700]!;
    return Colors.green;
  }

  Color _getPainColor(double pain) {
    if (pain <= 3) return Colors.green;
    if (pain <= 6) return Colors.orange;
    return Colors.red;
  }

  Color _getEntryTypeColor(String type) {
    switch (type) {
      case 'mood':
        return Colors.purple;
      case 'physical':
        return Colors.blue;
      case 'feeding':
        return Colors.green;
      case 'sleep':
        return Colors.indigo;
      case 'baby':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEntryTypeIcon(String type) {
    switch (type) {
      case 'mood':
        return Icons.mood;
      case 'physical':
        return Icons.healing;
      case 'feeding':
        return Icons.baby_changing_station;
      case 'sleep':
        return Icons.bedtime;
      case 'baby':
        return Icons.child_care;
      default:
        return Icons.notes;
    }
  }

  String _getEntryTypeDisplayName(String type) {
    switch (type) {
      case 'mood':
        return 'Mood Entry';
      case 'physical':
        return 'Physical Recovery';
      case 'feeding':
        return 'Feeding Session';
      case 'sleep':
        return 'Sleep Log';
      case 'baby':
        return 'Baby Update';
      default:
        return 'General Entry';
    }
  }

  Color _getMilestoneTypeColor(String? type) {
    switch (type) {
      case 'recovery':
        return Colors.blue;
      case 'baby_first':
        return Colors.orange;
      case 'medical':
        return Colors.green;
      default:
        return Colors.purple;
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
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  // Action methods
  void _logQuickMood(double mood) {
    ref.read(postpartumTrackerProvider.notifier).logQuickMood(
          moodRating: mood,
          notes: 'Quick mood check',
        );
  }

  void _startNewEntry([String? type]) {
    try {
      ref.read(postpartumTrackerProvider.notifier).startNewEntry(
            entryType: type ?? 'general',
          );
      _showEntryForm();
    } catch (e) {
      print('[PostpartumTracker] Error starting new entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _editTodayEntry(Map<String, dynamic> entry) {
    // Set current entry and show form
    _showEntryForm();
  }

  void _addMilestone() {
    _showMilestoneForm();
  }

  Future<void> _checkFirstTimeUser(PostpartumTrackerState state) async {
    // Check if user has any data (entries or milestones)
    final hasEntries = state.postpartumEntries.isNotEmpty;
    final hasMilestones = state.milestones.isNotEmpty;
    
    // Check if delivery date is set in BOTH UserProfileProvider AND SharedPreferences
    final userProfile = ref.read(userProfileProvider);
    bool hasDeliveryDate = userProfile.userProfile?.deliveryDate != null;
    
    // Also check SharedPreferences (where we store delivery date)
    if (!hasDeliveryDate) {
      final prefs = await SharedPreferences.getInstance();
      final deliveryDateStr = prefs.getString('delivery_date');
      hasDeliveryDate = deliveryDateStr != null;
      print('[PostpartumTracker] Delivery date check - UserProfile: ${userProfile.userProfile?.deliveryDate}, SharedPrefs: $deliveryDateStr');
    }
    
    // If user has NO data and NO delivery date, show first-time welcome
    if (!hasEntries && !hasMilestones && !hasDeliveryDate) {
      if (mounted) {
        _showFirstTimeWelcome();
      }
    }
  }

  void _showFirstTimeWelcome() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to take action
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.waving_hand, color: AppTheme.primaryPurple, size: 28),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Welcome to Postpartum Tracker!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To get started and receive personalized guidance, please set your delivery date first.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightPurpleBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppTheme.primaryPurple, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Why we need this:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Track your recovery timeline accurately\n• Get AI guidance tailored to your recovery stage\n• Monitor milestones based on weeks postpartum',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // User can explore without setting date, but will be prompted again for AI
            },
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeliveryDatePicker();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Set Delivery Date'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeliveryDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 7)), // Default to 1 week ago
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: 'Select Your Delivery Date',
      confirmText: 'Set',
    );

    if (pickedDate != null) {
      // Save delivery date to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('delivery_date', pickedDate.toIso8601String());
      
      final daysPostpartum = now.difference(pickedDate).inDays;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery date set: ${DateFormat('MMM dd, yyyy').format(pickedDate)} ($daysPostpartum days postpartum)'),
            backgroundColor: AppTheme.safeGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _getAIGuidance() async {
    final state = ref.read(postpartumTrackerProvider);

    print('[PostpartumTracker] _getAIGuidance called. Entries count: ${state.postpartumEntries.length}');

    // Calculate days postpartum from stored delivery date
    int? daysPostpartum;
    final prefs = await SharedPreferences.getInstance();
    final deliveryDateStr = prefs.getString('delivery_date');
    
    if (deliveryDateStr != null) {
      final deliveryDate = DateTime.parse(deliveryDateStr);
      daysPostpartum = DateTime.now().difference(deliveryDate).inDays;
      print('[PostpartumTracker] Days postpartum (from delivery date): $daysPostpartum');
    } else if (state.postpartumEntries.isNotEmpty) {
      // Fallback: estimate from first entry
      final firstEntry = state.postpartumEntries.last; // oldest entry
      final firstDate = DateTime.parse(firstEntry['date'] as String);
      daysPostpartum = DateTime.now().difference(firstDate).inDays;
      print('[PostpartumTracker] Days postpartum (estimated from first entry): $daysPostpartum');
    }

    // Collect symptoms from recent entries
    final symptoms = <String>[];
    for (final entry in state.postpartumEntries.take(5)) {
      final entrySymptoms = entry['physicalSymptoms'] as List<dynamic>? ?? [];
      symptoms.addAll(entrySymptoms.map((s) => s.toString()));
    }
    final symptomsSummary = symptoms.isNotEmpty ? symptoms.join(', ') : 'No specific symptoms reported';
    print('[PostpartumTracker] Symptoms summary: $symptomsSummary');

    if (daysPostpartum == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Delivery Date'),
          content: const Text('To get accurate AI guidance, please set your delivery date first. This helps us calculate how many days postpartum you are.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeliveryDatePicker();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
              child: const Text('Set Date'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      print('[PostpartumTracker] Creating AI stream...');
      // Create streaming response
      final stream = ref.read(apiServiceProvider).postpartumTrackerAIStream(
        symptoms: symptomsSummary,
        daysPostpartum: daysPostpartum,
      );

      // Navigate to streaming AI result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreamingAIResultScreen(
            title: 'Postpartum Guidance',
            icon: Icons.healing,
            color: AppTheme.warningOrange,
            responseStream: stream,
          ),
        ),
      );
    } catch (e) {
      print('[PostpartumTracker] Error getting AI guidance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryPurple),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'How to Use Postpartum Tracker',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Track your postpartum recovery journey with this tool.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildInfoStep('1️⃣', 'Quick Mood Check', 'Tap any emoji to quickly log how you\'re feeling today.'),
              const SizedBox(height: 12),
              _buildInfoStep('2️⃣', 'Log Entry', 'Tap "Log Entry" button below to record detailed information about your recovery, including mood, pain, symptoms, and sleep.'),
              const SizedBox(height: 12),
              _buildInfoStep('3️⃣', 'Track Progress', 'Switch to the "Progress" tab to see your recovery trends over time.'),
              const SizedBox(height: 12),
              _buildInfoStep('4️⃣', 'Milestones', 'Use the "Milestones" tab to celebrate important recovery achievements.'),
              const SizedBox(height: 12),
              _buildInfoStep('✨', 'AI Guidance', 'For premium users: Tap the ✨ icon after logging entries to get personalized AI recommendations.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sharePostpartumProgress() async {
    try {
      final state = ref.read(postpartumTrackerProvider);
      
      // Calculate days postpartum
      int? daysPostpartum;
      final prefs = await SharedPreferences.getInstance();
      final deliveryDateStr = prefs.getString('delivery_date');
      
      if (deliveryDateStr != null) {
        final deliveryDate = DateTime.parse(deliveryDateStr);
        daysPostpartum = DateTime.now().difference(deliveryDate).inDays;
      } else if (state.postpartumEntries.isNotEmpty) {
        // Fallback: estimate from first entry
        final firstEntry = state.postpartumEntries.last;
        final firstDate = DateTime.parse(firstEntry['date'] as String);
        daysPostpartum = DateTime.now().difference(firstDate).inDays;
      }

      if (daysPostpartum == null) {
        // No data yet - share invitation to use the tool
        await ShareHelper.shareToolOutput(
          toolName: 'Postpartum Tracker',
          catchyHook: '🌸 Track your postpartum recovery journey with SafeMama!',
        );
        return;
      }

      await ShareHelper.sharePostpartumTracker(
        daysPostpartum: daysPostpartum,
        entriesCount: state.postpartumEntries.length,
        milestonesCount: state.milestones.length,
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

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Log Recovery Entry'),
              onTap: () {
                Navigator.of(context).pop();
                _startNewEntry();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Add Milestone'),
              onTap: () {
                Navigator.of(context).pop();
                _addMilestone();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mood),
              title: const Text('Quick Mood Check'),
              onTap: () {
                Navigator.of(context).pop();
                // Show mood picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: AppTheme.primaryPurple),
              title: const Text('Set Delivery Date'),
              subtitle: const Text('Used to calculate days postpartum'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeliveryDatePicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PostpartumEntryFormSheet(),
    );
  }

  void _showMilestoneForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MilestoneFormSheet(),
    );
  }

  void _showEntryDetails(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EntryDetailsSheet(entry: entry),
    );
  }

  void _handleEntryAction(Map<String, dynamic> entry, String action) {
    switch (action) {
      case 'view':
        _showEntryDetails(entry);
        break;
      case 'edit':
        // Edit entry
        break;
      case 'delete':
        _deleteEntry(entry);
        break;
    }
  }

  void _handleMilestoneAction(Map<String, dynamic> milestone, String action) {
    switch (action) {
      case 'edit':
        // Edit milestone
        break;
      case 'delete':
        _deleteMilestone(milestone);
        break;
    }
  }

  void _deleteEntry(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(postpartumTrackerProvider.notifier).deleteEntry(entry['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteMilestone(Map<String, dynamic> milestone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: const Text('Are you sure you want to delete this milestone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(postpartumTrackerProvider.notifier).deleteMilestone(milestone['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PostpartumEntryFormSheet extends ConsumerStatefulWidget {
  const _PostpartumEntryFormSheet();

  @override
  ConsumerState<_PostpartumEntryFormSheet> createState() => _PostpartumEntryFormSheetState();
}

class _PostpartumEntryFormSheetState extends ConsumerState<_PostpartumEntryFormSheet> {
  late TextEditingController notesController;
  double mood = 3.0;
  double pain = 0.0;
  List<String> symptoms = [];

  @override
  void initState() {
    super.initState();
    notesController = TextEditingController();
    
    // ✅ FIXED: Access currentEntry from state, not notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentEntry = ref.read(postpartumTrackerProvider).currentEntry;
      if (currentEntry != null) {
        setState(() {
          final moodValue = currentEntry['moodRating'] as double? ?? 3.0;
          mood = moodValue < 1.0 ? 3.0 : moodValue; // Ensure mood is at least 1.0
          pain = currentEntry['painLevel'] as double? ?? 0.0;
          notesController.text = currentEntry['notes'] as String? ?? '';
          symptoms = List<String>.from(currentEntry['physicalSymptoms'] as List<dynamic>? ?? []);
        });
      }
    });
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(postpartumTrackerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Log Postpartum Entry',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              
              // Mood Slider
              Text(
                'Mood (${mood.toInt()}/5)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: mood,
                min: 1.0,
                max: 5.0,
                divisions: 4,
                label: mood.toInt().toString(),
                onChanged: (v) => setState(() => mood = v),
                activeColor: AppTheme.primaryPurple,
              ),
              const SizedBox(height: 16),
              
              // Pain Level Slider
              Text(
                'Pain Level (${pain.toInt()}/10)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: pain,
                min: 0.0,
                max: 10.0,
                divisions: 10,
                label: pain.toInt().toString(),
                onChanged: (v) => setState(() => pain = v),
                activeColor: AppTheme.dangerRed,
              ),
              const SizedBox(height: 16),
              
              // Notes TextField
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'How are you feeling today?',
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    provider.updateCurrentEntry({
                      'moodRating': mood,
                      'painLevel': pain,
                      'notes': notesController.text,
                      'physicalSymptoms': symptoms,
                      'date': DateTime.now().toIso8601String(),
                    });
                    provider.saveCurrentEntry();
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Entry saved successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                  ),
                  child: const Text('Save Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneFormSheet extends ConsumerStatefulWidget {
  const _MilestoneFormSheet();

  @override
  ConsumerState<_MilestoneFormSheet> createState() => _MilestoneFormSheetState();
}

class _MilestoneFormSheetState extends ConsumerState<_MilestoneFormSheet> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  String selectedType = 'recovery';
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Milestone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              
              // Title TextField
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Milestone Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., First walk outside',
                ),
              ),
              const SizedBox(height: 16),
              
              // Description TextField
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Type Dropdown
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Milestone Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'recovery', child: Text('Recovery')),
                  DropdownMenuItem(value: 'baby_first', child: Text('Baby First')),
                  DropdownMenuItem(value: 'medical', child: Text('Medical')),
                ],
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }
                    
                    setState(() => _isSaving = true);
                    
                    try {
                      // Calculate weeks postpartum (for now, estimate from first entry)
                      final state = ref.read(postpartumTrackerProvider);
                      int weeksPostpartum = 0;
                      
                      if (state.postpartumEntries.isNotEmpty) {
                        final firstEntry = state.postpartumEntries.last; // oldest entry
                        final firstDate = DateTime.parse(firstEntry['date'] as String);
                        weeksPostpartum = DateTime.now().difference(firstDate).inDays ~/ 7;
                      }
                      
                      await ref.read(postpartumTrackerProvider.notifier).addMilestone(
                        milestoneType: selectedType,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        weekPostpartum: weeksPostpartum,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Milestone added!'), backgroundColor: AppTheme.safeGreen),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                  ),
                  child: _isSaving 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Add Milestone'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _EntryDetailsSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(entry['date'] ?? entry['entry_date']);
    final mood = entry['moodRating'] as double? ?? 0.0;
    final pain = entry['painLevel'] as double? ?? 0.0;
    final notes = entry['notes'] as String? ?? '';
    final symptoms = entry['physicalSymptoms'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entry Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Date:', _formatDate(date)),
              _buildDetailRow('Mood:', '${mood.toInt()}/5'),
              _buildDetailRow('Pain Level:', '${pain.toInt()}/10'),
              if (notes.isNotEmpty) _buildDetailRow('Notes:', notes),
              if (symptoms.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Physical Symptoms:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: symptoms.map((symptom) => Chip(
                        label: Text(symptom.toString()),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
