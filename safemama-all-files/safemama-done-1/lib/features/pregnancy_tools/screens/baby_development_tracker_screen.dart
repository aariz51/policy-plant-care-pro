import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/pregnancy_tools/providers/baby_development_tracker_providers.dart';

class BabyDevelopmentTrackerScreen extends ConsumerStatefulWidget {
  const BabyDevelopmentTrackerScreen({super.key});

  @override
  ConsumerState<BabyDevelopmentTrackerScreen> createState() => _BabyDevelopmentTrackerScreenState();
}

class _BabyDevelopmentTrackerScreenState extends ConsumerState<BabyDevelopmentTrackerScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final state = ref.watch(babyDevelopmentTrackerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baby Development'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => _showBabyAgeDialog(),
            icon: const Icon(Icons.cake),
            tooltip: 'Update Baby Age',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Milestones', icon: Icon(Icons.star)),
            Tab(text: 'Growth', icon: Icon(Icons.height)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMilestonesTab(state),
                _buildGrowthTab(state),
                _buildProgressTab(state),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMilestonesTab(BabyDevelopmentTrackerState state) {
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
            _buildBabyAgeCard(state),
            const SizedBox(height: 24),
            _buildUpcomingMilestones(state),
            const SizedBox(height: 24),
            _buildMilestonesByType(state),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyAgeCard(BabyDevelopmentTrackerState state) {
    final ageWeeks = state.currentBabyAgeWeeks;
    final months = (ageWeeks / 4.33).floor();
    final weeks = ageWeeks % 4;
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.child_care,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Baby',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    months > 0 ? '$months months, $weeks weeks old' : '$ageWeeks weeks old',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showBabyAgeDialog(),
              icon: const Icon(Icons.edit, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMilestones(BabyDevelopmentTrackerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Milestones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _addPredefinedMilestones(),
              child: const Text('Add Common'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.upcomingMilestones.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No upcoming milestones'),
                  const SizedBox(height: 8),
                  const Text(
                    'Add milestones to track your baby\'s development',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.upcomingMilestones.map((milestone) => 
            _buildUpcomingMilestoneCard(milestone)),
      ],
    );
  }

  Widget _buildUpcomingMilestoneCard(Map<String, dynamic> milestone) {
    final expectedWeeks = milestone['expectedAgeWeeks'] as int;
    final currentWeeks = ref.read(babyDevelopmentTrackerProvider).currentBabyAgeWeeks;
    final weeksToGo = expectedWeeks - currentWeeks;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMilestoneTypeColor(milestone['type']),
          child: Icon(
            _getMilestoneTypeIcon(milestone['type']),
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
            Text(milestone['description']),
            const SizedBox(height: 4),
            Text(
              weeksToGo > 0 
                  ? 'Expected in $weeksToGo weeks' 
                  : weeksToGo == 0 
                      ? 'Expected this week!' 
                      : '${-weeksToGo} weeks overdue',
              style: TextStyle(
                fontSize: 12,
                color: weeksToGo <= 0 ? Colors.orange : Colors.grey[600],
                fontWeight: weeksToGo <= 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _markMilestoneAchieved(milestone),
          child: const Text('Achieved'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(60, 30),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestonesByType(BabyDevelopmentTrackerState state) {
    final types = ['motor', 'social', 'language', 'cognitive'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Development Areas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...types.map((type) => _buildMilestoneTypeSection(state, type)),
      ],
    );
  }

  Widget _buildMilestoneTypeSection(BabyDevelopmentTrackerState state, String type) {
    final milestones = ref.read(babyDevelopmentTrackerProvider.notifier)
        .getMilestonesByType(type);
    final achieved = milestones.where((m) => m['isAchieved'] == true).length;
    final total = milestones.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getMilestoneTypeColor(type),
          child: Icon(
            _getMilestoneTypeIcon(type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _getMilestoneTypeDisplayName(type),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$achieved of $total achieved'),
        trailing: total > 0 
            ? CircularProgressIndicator(
                value: achieved / total,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(_getMilestoneTypeColor(type)),
              )
            : null,
        children: [
          if (milestones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No milestones in this category yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...milestones.map((milestone) => _buildMilestoneListTile(milestone)),
        ],
      ),
    );
  }

  Widget _buildMilestoneListTile(Map<String, dynamic> milestone) {
    final isAchieved = milestone['isAchieved'] as bool;
    final expectedWeeks = milestone['expectedAgeWeeks'] as int;
    
    return ListTile(
      leading: Icon(
        isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isAchieved ? Colors.green : Colors.grey,
      ),
      title: Text(
        milestone['title'],
        style: TextStyle(
          decoration: isAchieved ? TextDecoration.lineThrough : null,
          color: isAchieved ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(milestone['description']),
          Text(
            'Expected at $expectedWeeks weeks',
            style: const TextStyle(fontSize: 12),
          ),
          if (isAchieved && milestone['achievedAgeWeeks'] != null)
            Text(
              'Achieved at ${milestone['achievedAgeWeeks']} weeks',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      trailing: !isAchieved
          ? IconButton(
              onPressed: () => _markMilestoneAchieved(milestone),
              icon: const Icon(Icons.check),
              tooltip: 'Mark as achieved',
            )
          : null,
      onTap: () => _showMilestoneDetails(milestone),
    );
  }

  Widget _buildGrowthTab(BabyDevelopmentTrackerState state) {
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
            _buildAddGrowthEntryCard(),
            const SizedBox(height: 24),
            _buildGrowthChart(state),
            const SizedBox(height: 24),
            _buildGrowthHistory(state),
          ],
        ),
      ),
    );
  }

  Widget _buildAddGrowthEntryCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.height, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Track Growth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Record your baby\'s weight, height, and head circumference to track healthy growth patterns.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addGrowthEntry(),
              icon: const Icon(Icons.add),
              label: const Text('Add Growth Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthChart(BabyDevelopmentTrackerState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Growth Chart',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Growth Chart',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chart showing weight, height, and head circumference over time',
                      textAlign: TextAlign.center,
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

  Widget _buildGrowthHistory(BabyDevelopmentTrackerState state) {
    final growthEntries = state.growthEntries;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Growth History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (growthEntries.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to full history
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (growthEntries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.height, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No growth entries yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Add measurements to track your baby\'s growth',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...growthEntries.take(5).map((entry) => _buildGrowthEntryCard(entry)),
      ],
    );
  }

  Widget _buildGrowthEntryCard(Map<String, dynamic> entry) {
    final date = DateTime.parse(entry['measurementDate']);
    final ageWeeks = entry['babyAgeWeeks'] as int;
    final weight = entry['weightGrams'] as double;
    final height = entry['heightCm'] as double;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.height, color: Colors.white, size: 20),
        ),
        title: Text(
          '$ageWeeks weeks old',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight: ${(weight / 1000).toStringAsFixed(2)} kg'),
            Text('Height: ${height.toStringAsFixed(1)} cm'),
            Text(_formatDate(date)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleGrowthEntryAction(entry, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showGrowthEntryDetails(entry),
      ),
    );
  }

  Widget _buildProgressTab(BabyDevelopmentTrackerState state) {
    final progress = ref.read(babyDevelopmentTrackerProvider.notifier).getDevelopmentProgress();
    final stats = state.stats;
    
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
            _buildOverallProgress(progress, stats),
            const SizedBox(height: 24),
            _buildDevelopmentAreas(progress),
            const SizedBox(height: 24),
            _buildRecommendations(state),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress(Map<String, dynamic> progress, Map<String, dynamic> stats) {
    final overallProgress = progress['overallProgress'] as double? ?? 0.0;
    final totalMilestones = stats['totalMilestones'] as int? ?? 0;
    final achievedMilestones = stats['achievedMilestones'] as int? ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Development',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: overallProgress,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation(Colors.blue),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(overallProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text(
                                'Complete',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$achievedMilestones of $totalMilestones milestones achieved',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevelopmentAreas(Map<String, dynamic> progress) {
    final areas = ['motorProgress', 'socialProgress', 'languageProgress', 'cognitiveProgress'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Development Areas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...areas.map((area) => _buildProgressBar(area, progress[area] as double? ?? 0.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String area, double progress) {
    final displayName = area.replaceAll('Progress', '');
    final color = _getMilestoneTypeColor(displayName);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMilestoneTypeDisplayName(displayName),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BabyDevelopmentTrackerState state) {
    final recommendations = ref.read(babyDevelopmentTrackerProvider.notifier)
        .getDevelopmentRecommendations();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Development Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => Padding(
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

  // Helper methods
  Color _getMilestoneTypeColor(String type) {
    switch (type) {
      case 'motor':
        return Colors.blue;
      case 'social':
        return Colors.green;
      case 'language':
        return Colors.purple;
      case 'cognitive':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMilestoneTypeIcon(String type) {
    switch (type) {
      case 'motor':
        return Icons.directions_run;
      case 'social':
        return Icons.face;
      case 'language':
        return Icons.record_voice_over;
      case 'cognitive':
        return Icons.psychology;
      default:
        return Icons.star;
    }
  }

  String _getMilestoneTypeDisplayName(String type) {
    switch (type) {
      case 'motor':
        return 'Motor Skills';
      case 'social':
        return 'Social & Emotional';
      case 'language':
        return 'Language & Communication';
      case 'cognitive':
        return 'Cognitive Development';
      default:
        return type;
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
  void _showBabyAgeDialog() {
    showDialog(
      context: context,
      builder: (context) => _BabyAgeDialog(
        currentAge: ref.read(babyDevelopmentTrackerProvider).currentBabyAgeWeeks,
        onAgeChanged: (newAge) {
          ref.read(babyDevelopmentTrackerProvider.notifier).updateBabyAge(newAge);
        },
      ),
    );
  }

  void _addPredefinedMilestones() {
    ref.read(babyDevelopmentTrackerProvider.notifier).addPredefinedMilestones();
  }

  void _markMilestoneAchieved(Map<String, dynamic> milestone) {
    showDialog(
      context: context,
      builder: (context) => _MilestoneAchievedDialog(
        milestone: milestone,
        onConfirm: (notes) {
          ref.read(babyDevelopmentTrackerProvider.notifier)
             .markMilestoneAchieved(
               milestoneId: milestone['id'],
               notes: notes,
             );
        },
      ),
    );
  }

  void _addGrowthEntry() {
    ref.read(babyDevelopmentTrackerProvider.notifier).startNewGrowthEntry();
    _showGrowthEntryForm();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Development Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Add Custom Milestone'),
              onTap: () {
                Navigator.of(context).pop();
                _addCustomMilestone();
              },
            ),
            ListTile(
              leading: const Icon(Icons.height),
              title: const Text('Add Growth Measurement'),
              onTap: () {
                Navigator.of(context).pop();
                _addGrowthEntry();
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_add),
              title: const Text('Add Common Milestones'),
              onTap: () {
                Navigator.of(context).pop();
                _addPredefinedMilestones();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomMilestone() {
    ref.read(babyDevelopmentTrackerProvider.notifier).startNewMilestone(
      milestoneType: 'custom',
      title: '',
      description: '',
      expectedAgeWeeks: ref.read(babyDevelopmentTrackerProvider).currentBabyAgeWeeks,
    );
    _showMilestoneForm();
  }

  void _showMilestoneForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MilestoneFormSheet(),
    );
  }

  void _showGrowthEntryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GrowthEntryFormSheet(),
    );
  }

  void _showMilestoneDetails(Map<String, dynamic> milestone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MilestoneDetailsSheet(milestone: milestone),
    );
  }

  void _showGrowthEntryDetails(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GrowthEntryDetailsSheet(entry: entry),
    );
  }

  void _handleGrowthEntryAction(Map<String, dynamic> entry, String action) {
    switch (action) {
      case 'edit':
        // Edit entry
        break;
      case 'delete':
        _deleteGrowthEntry(entry);
        break;
    }
  }

  void _deleteGrowthEntry(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Growth Entry'),
        content: const Text('Are you sure you want to delete this growth entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(babyDevelopmentTrackerProvider.notifier)
                 .deleteGrowthEntry(entry['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Dialog and sheet implementations
class _BabyAgeDialog extends StatefulWidget {
  final int currentAge;
  final ValueChanged<int> onAgeChanged;

  const _BabyAgeDialog({
    required this.currentAge,
    required this.onAgeChanged,
  });

  @override
  State<_BabyAgeDialog> createState() => _BabyAgeDialogState();
}

class _BabyAgeDialogState extends State<_BabyAgeDialog> {
  late int _selectedAge;

  @override
  void initState() {
    super.initState();
    _selectedAge = widget.currentAge;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Baby\'s Age'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current age: $_selectedAge weeks'),
          const SizedBox(height: 16),
          Slider(
            value: _selectedAge.toDouble(),
            min: 0,
            max: 104, // 2 years
            divisions: 104,
            label: '$_selectedAge weeks',
            onChanged: (value) {
              setState(() {
                _selectedAge = value.toInt();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onAgeChanged(_selectedAge);
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _MilestoneAchievedDialog extends StatefulWidget {
  final Map<String, dynamic> milestone;
  final ValueChanged<String> onConfirm;

  const _MilestoneAchievedDialog({
    required this.milestone,
    required this.onConfirm,
  });

  @override
  State<_MilestoneAchievedDialog> createState() => _MilestoneAchievedDialogState();
}

class _MilestoneAchievedDialogState extends State<_MilestoneAchievedDialog> {
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Milestone Achieved! 🎉'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Congratulations! "${widget.milestone['title']}" has been achieved.',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any notes about this milestone...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_notesController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// Form sheets (simplified implementations)
class _MilestoneFormSheet extends StatefulWidget {
  const _MilestoneFormSheet();

  @override
  State<_MilestoneFormSheet> createState() => _MilestoneFormSheetState();
}

class _MilestoneFormSheetState extends State<_MilestoneFormSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Milestone Form Sheet - Implementation needed'),
      ),
    );
  }
}

class _GrowthEntryFormSheet extends StatefulWidget {
  const _GrowthEntryFormSheet();

  @override
  State<_GrowthEntryFormSheet> createState() => _GrowthEntryFormSheetState();
}

class _GrowthEntryFormSheetState extends State<_GrowthEntryFormSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Growth Entry Form Sheet - Implementation needed'),
      ),
    );
  }
}

class _MilestoneDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> milestone;

  const _MilestoneDetailsSheet({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Milestone Details Sheet - Implementation needed'),
      ),
    );
  }
}

class _GrowthEntryDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _GrowthEntryDetailsSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Growth Entry Details Sheet - Implementation needed'),
      ),
    );
  }
}
