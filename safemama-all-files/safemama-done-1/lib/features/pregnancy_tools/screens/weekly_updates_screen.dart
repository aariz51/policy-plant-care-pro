import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/pregnancy_tools/providers/weekly_updates_providers.dart';
import 'package:safemama/core/widgets/custom_button.dart';

class WeeklyUpdatesScreen extends ConsumerStatefulWidget {
  const WeeklyUpdatesScreen({super.key});

  @override
  ConsumerState<WeeklyUpdatesScreen> createState() => _WeeklyUpdatesScreenState();
}

class _WeeklyUpdatesScreenState extends ConsumerState<WeeklyUpdatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weeklyUpdatesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Updates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => _showWeekSelector(),
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Week',
          ),
          IconButton(
            onPressed: () => _showNotificationSettings(),
            icon: Icon(
              ref.read(weeklyUpdatesProvider.notifier).notificationsEnabled ? Icons.notifications : Icons.notifications_off,
            ),
            tooltip: 'Notification Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'This Week', icon: Icon(Icons.today)),
            Tab(text: 'Reflections', icon: Icon(Icons.note)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyUpdateTab(state),
                _buildReflectionsTab(state),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _addReflection(),
              icon: const Icon(Icons.add),
              label: const Text('Add Reflection'),
            )
          : null,
    );
  }

  Widget _buildWeeklyUpdateTab(WeeklyUpdatesState state) {
    if (state.currentWeekUpdate == null) {
      return _buildNoUpdateAvailable();
    }

    final update = state.currentWeekUpdate!;
    final week = state.selectedWeek;
    
    return RefreshIndicator(
      onRefresh: () async {
        // Reload current week update
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekHeader(week, update),
            const SizedBox(height: 24),
            _buildWeekNavigation(state),
            const SizedBox(height: 24),
            _buildBabyDevelopment(update),
            const SizedBox(height: 24),
            _buildMomChanges(update),
            const SizedBox(height: 24),
            _buildWeeklyTips(update),
            const SizedBox(height: 24),
            _buildNutritionFocus(update),
            const SizedBox(height: 24),
            _buildWeeklyMilestones(update),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUpdateAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No update available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Weekly update for this week is not available yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader(int week, Map<String, dynamic> update) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    '$week',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week $week of Pregnancy',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        update['title'] ?? 'Your pregnancy journey continues',
                        style: TextStyle(
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (update['summary'] != null) ...[
              const SizedBox(height: 16),
              Text(
                update['summary'],
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNavigation(WeeklyUpdatesState state) {
    final availableWeeks = ref.read(weeklyUpdatesProvider.notifier).getAvailableWeekNumbers();
    final currentWeek = state.selectedWeek;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Browse Weeks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: PageView.builder(
                controller: _pageController,
                itemCount: (availableWeeks.length / 7).ceil(),
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * 7;
                  final endIndex = (startIndex + 7).clamp(0, availableWeeks.length);
                  final pageWeeks = availableWeeks.sublist(startIndex, endIndex);
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: pageWeeks.map((week) => GestureDetector(
                      onTap: () => _selectWeek(week),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: week == currentWeek ? Colors.blue : Colors.grey[200],
                          border: Border.all(
                            color: week == currentWeek ? Colors.blue : Colors.grey[300]!,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$week',
                            style: TextStyle(
                              color: week == currentWeek ? Colors.white : Colors.black,
                              fontWeight: week == currentWeek ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  );
                },
              ),
            ),
            if (availableWeeks.length > 7)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_pageController.page! > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_pageController.page! < (availableWeeks.length / 7).ceil() - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyDevelopment(Map<String, dynamic> update) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.child_care, color: Colors.pink),
                const SizedBox(width: 8),
                const Text(
                  'Baby Development',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              update['baby_development'] ?? 'Your baby is developing rapidly this week.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomChanges(Map<String, dynamic> update) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'What\'s Happening to You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              update['mom_changes'] ?? 'You may notice changes in your body this week.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTips(Map<String, dynamic> update) {
    final tips = update['tips'] as List<dynamic>? ?? [];
    final recommendations = ref.read(weeklyUpdatesProvider.notifier)
        .getRecommendationsForWeek(ref.read(weeklyUpdatesProvider).selectedWeek);
    
    final allTips = [...tips.map((t) => t.toString()), ...recommendations];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'This Week\'s Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...allTips.take(5).map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionFocus(Map<String, dynamic> update) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Nutrition Focus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              update['nutrition_focus'] ?? 'Focus on balanced nutrition this week.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMilestones(Map<String, dynamic> update) {
    final milestones = update['milestones'] as List<dynamic>? ?? [];
    
    if (milestones.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Milestones This Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...milestones.map((milestone) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star_border, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(milestone.toString(), style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionsTab(WeeklyUpdatesState state) {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload reflections
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressSummary(state),
            const SizedBox(height: 24),
            _buildReflectionsList(state),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(WeeklyUpdatesState state) {
    final summary = ref.read(weeklyUpdatesProvider.notifier).getProgressSummary();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressStatItem(
                    'Weeks Viewed',
                    '${summary['viewedWeeks']}/${summary['totalWeeks']}',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildProgressStatItem(
                    'Reflections',
                    '${summary['completedReflections']}',
                    Icons.note,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: summary['progressPercentage'] as double,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              '${((summary['progressPercentage'] as double) * 100).toInt()}% Complete',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReflectionsList(WeeklyUpdatesState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Reflections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _addReflection(),
              child: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.reflections.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.note_add, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No reflections yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start reflecting on your pregnancy journey by adding your first weekly reflection',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _addReflection(),
                    child: const Text('Add First Reflection'),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.reflections.map((reflection) => _buildReflectionCard(reflection)),
      ],
    );
  }

  Widget _buildReflectionCard(Map<String, dynamic> reflection) {
    final week = reflection['pregnancy_week'] as int;
    final createdAt = DateTime.parse(reflection['created_at']);
    final moodRating = reflection['mood_rating'] as double? ?? 0.0;
    final energyLevel = reflection['energy_level'] as double? ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewReflection(reflection),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Week $week Reflection',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDate(createdAt),
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
                  _buildReflectionStat('Mood', moodRating, 5, Colors.blue),
                  const SizedBox(width: 24),
                  _buildReflectionStat('Energy', energyLevel, 5, Colors.green),
                ],
              ),
              if (reflection['highlights'] != null && reflection['highlights'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Highlights: ${reflection['highlights']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (reflection['symptoms'] != null)
                    Text(
                      '${(reflection['symptoms'] as List).length} symptoms',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleReflectionAction(reflection, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('View Details')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReflectionStat(String label, double value, double maxValue, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12),
        ),
        ...List.generate(maxValue.toInt(), (index) {
          return Icon(
            index < value ? Icons.star : Icons.star_border,
            size: 16,
            color: color,
          );
        }),
      ],
    );
  }

  // Helper methods
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
  void _selectWeek(int week) {
    ref.read(weeklyUpdatesProvider.notifier).setSelectedWeek(week);
  }

  void _showWeekSelector() {
    final availableWeeks = ref.read(weeklyUpdatesProvider.notifier).getAvailableWeekNumbers();
    final currentWeek = ref.read(weeklyUpdatesProvider).selectedWeek;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Week'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableWeeks.length,
            itemBuilder: (context, index) {
              final week = availableWeeks[index];
              final isSelected = week == currentWeek;
              
              return GestureDetector(
                onTap: () {
                  _selectWeek(week);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$week',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    final state = ref.read(weeklyUpdatesProvider);
    final prefs = state.notificationPreferences;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _NotificationSettingsSheet(
        currentPreferences: prefs,
        onSave: (pushEnabled, emailEnabled, preferredTime) {
          ref.read(weeklyUpdatesProvider.notifier).updateNotificationPreferences(
            enablePush: pushEnabled,
            enableEmail: emailEnabled,
            preferredTime: preferredTime,
          );
        },
      ),
    );
  }

  void _addReflection() {
    final currentWeek = ref.read(weeklyUpdatesProvider).selectedWeek;
    ref.read(weeklyUpdatesProvider.notifier).startNewReflection(currentWeek);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _WeeklyReflectionSheet(),
    );
  }

  void _viewReflection(Map<String, dynamic> reflection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReflectionDetailsSheet(reflection: reflection),
    );
  }

  void _handleReflectionAction(Map<String, dynamic> reflection, String action) {
    switch (action) {
      case 'view':
        _viewReflection(reflection);
        break;
      case 'edit':
        // Edit reflection
        break;
      case 'delete':
        _deleteReflection(reflection);
        break;
    }
  }

  void _deleteReflection(Map<String, dynamic> reflection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reflection'),
        content: Text('Are you sure you want to delete your Week ${reflection['pregnancy_week']} reflection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(weeklyUpdatesProvider.notifier)
                 .deleteReflection(reflection['pregnancy_week']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Additional sheets (simplified implementations)
class _NotificationSettingsSheet extends StatefulWidget {
  final Map<String, dynamic>? currentPreferences;
  final Function(bool, bool, String) onSave;

  const _NotificationSettingsSheet({
    this.currentPreferences,
    required this.onSave,
  });

  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  late bool _pushEnabled;
  late bool _emailEnabled;
  late String _preferredTime;

  @override
  void initState() {
    super.initState();
    _pushEnabled = widget.currentPreferences?['push_enabled'] ?? false;
    _emailEnabled = widget.currentPreferences?['email_enabled'] ?? false;
    _preferredTime = widget.currentPreferences?['preferred_time'] ?? '09:00';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                  'Notification Settings',
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Get notified about new weekly updates'),
                  value: _pushEnabled,
                  onChanged: (value) => setState(() => _pushEnabled = value),
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive weekly updates via email'),
                  value: _emailEnabled,
                  onChanged: (value) => setState(() => _emailEnabled = value),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Preferred Time'),
                  subtitle: Text('Receive notifications at $_preferredTime'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.parse(_preferredTime.split(':')[0]),
                        minute: int.parse(_preferredTime.split(':')[1]),
                      ),
                    );
                    if (time != null) {
                      setState(() {
                        _preferredTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                CustomElevatedButton(
                  onPressed: () {
                    widget.onSave(_pushEnabled, _emailEnabled, _preferredTime);
                    Navigator.of(context).pop();
                  },
                  text: 'Save Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyReflectionSheet extends StatefulWidget {
  const _WeeklyReflectionSheet();

  @override
  State<_WeeklyReflectionSheet> createState() => _WeeklyReflectionSheetState();
}

class _WeeklyReflectionSheetState extends State<_WeeklyReflectionSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Weekly Reflection Sheet - Implementation needed'),
      ),
    );
  }
}

class _ReflectionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> reflection;

  const _ReflectionDetailsSheet({required this.reflection});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Reflection Details Sheet - Implementation needed'),
      ),
    );
  }
}
