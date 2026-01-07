import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/pregnancy_tools/providers/nutrition_planning_providers.dart';
import 'package:safemama/core/widgets/custom_button.dart';

class NutritionPlanningScreen extends ConsumerStatefulWidget {
  const NutritionPlanningScreen({super.key});

  @override
  ConsumerState<NutritionPlanningScreen> createState() => _NutritionPlanningScreenState();
}

class _NutritionPlanningScreenState extends ConsumerState<NutritionPlanningScreen> 
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
    final state = ref.watch(nutritionPlanningProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Planning'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Plans', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(state),
                _buildPlansTab(state),
                _buildHistoryTab(state),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab(NutritionPlanningState state) {
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
            _buildDailyStatsCard(state),
            const SizedBox(height: 24),
            _buildNutritionGoalsProgress(state),
            const SizedBox(height: 24),
            _buildTodaysMeals(state),
            const SizedBox(height: 24),
            _buildRecommendations(state),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStatsCard(NutritionPlanningState state) {
    final stats = state.dailyStats;
    final totalCalories = stats['totalCalories'] as double? ?? 0.0;
    final protein = stats['protein'] as double? ?? 0.0;
    final carbs = stats['carbs'] as double? ?? 0.0;
    final fat = stats['fat'] as double? ?? 0.0;

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
                  'Today\'s Nutrition',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${totalCalories.toInt()} kcal',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientColumn('Protein', protein, 'g', Colors.red),
                _buildNutrientColumn('Carbs', carbs, 'g', Colors.orange),
                _buildNutrientColumn('Fat', fat, 'g', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientColumn(String name, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}$unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionGoalsProgress(NutritionPlanningState state) {
    final progress = ref.read(nutritionPlanningProvider.notifier).getNutritionGoalProgress();
    
    if (progress.isEmpty || state.currentPlan == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.track_changes, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No nutrition plan active'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showCreatePlanDialog(),
                child: const Text('Create Plan'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Goals Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...progress.entries.map((entry) => 
              _buildProgressBar(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String nutrient, double progress) {
    final color = _getNutrientColor(nutrient);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getNutrientDisplayName(nutrient),
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

  Widget _buildTodaysMeals(NutritionPlanningState state) {
    final todayEntries = state.todayEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Meals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showAddEntryDialog(),
              child: const Text('Add Meal'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (todayEntries.isEmpty)
          _buildEmptyMealsCard()
        else
          ...todayEntries.map((entry) => _buildMealCard(entry)),
      ],
    );
  }

  Widget _buildEmptyMealsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No meals logged today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking your nutrition by adding your first meal',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddEntryDialog(),
              child: const Text('Add First Meal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> entry) {
    final mealType = entry['mealType'] as String;
    final calories = entry['calories'] as double;
    final foodItems = entry['foodItems'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMealTypeColor(mealType),
          child: Icon(
            _getMealTypeIcon(mealType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _getMealTypeDisplayName(mealType),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${calories.toInt()} calories'),
            const SizedBox(height: 4),
            Text(
              foodItems.map((item) => item['name']).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMealAction(entry, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showMealDetails(entry),
      ),
    );
  }

  Widget _buildRecommendations(NutritionPlanningState state) {
    final recommendations = ref.read(nutritionPlanningProvider.notifier).getNutritionRecommendations();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Recommendations',
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

  Widget _buildPlansTab(NutritionPlanningState state) {
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
                  'Nutrition Plans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreatePlanDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Plan'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.currentPlan != null)
              _buildCurrentPlanCard(state.currentPlan!),
            const SizedBox(height: 24),
            if (state.nutritionPlans.isEmpty)
              _buildEmptyPlansCard()
            else
              ...state.nutritionPlans.map((plan) => _buildPlanCard(plan)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(Map<String, dynamic> plan) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Current Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan['name'] ?? 'Nutrition Plan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Week ${plan['pregnancyWeek']} • ${plan['calorieTarget']?.toInt()} kcal/day',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Dietary restrictions: ${(plan['dietaryRestrictions'] as List<dynamic>?)?.join(', ') ?? 'None'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlansCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No nutrition plans yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a personalized nutrition plan based on your pregnancy needs',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreatePlanDialog(),
              child: const Text('Create First Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final createdAt = DateTime.parse(plan['createdAt']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.restaurant_menu),
        ),
        title: Text(
          plan['name'] ?? 'Nutrition Plan',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Week ${plan['pregnancyWeek']} • ${plan['calorieTarget']?.toInt()} kcal/day'),
            Text(
              'Created ${_formatDate(createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePlanAction(plan, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'activate', child: Text('Activate')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showPlanDetails(plan),
      ),
    );
  }

  Widget _buildHistoryTab(NutritionPlanningState state) {
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
            _buildOverallStatsCard(state),
            const SizedBox(height: 24),
            _buildNutritionHistory(state),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard(NutritionPlanningState state) {
    final stats = state.overallStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Entries',
                    '${stats['totalEntries'] ?? 0}',
                    Icons.restaurant,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Daily Calories',
                    '${(stats['averageDailyCalories'] as double? ?? 0.0).toInt()}',
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
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
        ),
      ],
    );
  }

  Widget _buildNutritionHistory(NutritionPlanningState state) {
    final entries = state.nutritionEntries;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          _buildEmptyHistoryCard()
        else
          ...entries.take(20).map((entry) => _buildHistoryCard(entry)),
      ],
    );
  }

  Widget _buildEmptyHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No nutrition history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your logged meals will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final date = DateTime.parse(entry['date'] ?? entry['entry_date']);
    final mealType = entry['mealType'] as String;
    final calories = entry['calories'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMealTypeColor(mealType),
          radius: 16,
          child: Icon(
            _getMealTypeIcon(mealType),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          _getMealTypeDisplayName(mealType),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${calories.toInt()} kcal • ${_formatDate(date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleHistoryAction(entry, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getNutrientColor(String nutrient) {
    switch (nutrient) {
      case 'protein':
        return Colors.red;
      case 'carbs':
        return Colors.orange;
      case 'fat':
        return Colors.green;
      case 'fiber':
        return Colors.brown;
      case 'calcium':
        return Colors.blue;
      case 'iron':
        return Colors.purple;
      case 'folate':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getNutrientDisplayName(String nutrient) {
    switch (nutrient) {
      case 'protein':
        return 'Protein';
      case 'carbs':
        return 'Carbohydrates';
      case 'fat':
        return 'Fat';
      case 'fiber':
        return 'Fiber';
      case 'calcium':
        return 'Calcium';
      case 'iron':
        return 'Iron';
      case 'folate':
        return 'Folate';
      default:
        return nutrient;
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  String _getMealTypeDisplayName(String mealType) {
    return mealType.substring(0, 1).toUpperCase() + mealType.substring(1);
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
  void _showAddEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddMealEntrySheet(),
    );
  }

  void _showCreatePlanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreatePlanSheet(),
    );
  }

  void _showMealDetails(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MealDetailsSheet(meal: entry),
    );
  }

  void _showPlanDetails(Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PlanDetailsSheet(plan: plan),
    );
  }

  void _handleMealAction(Map<String, dynamic> entry, String action) {
    switch (action) {
      case 'edit':
        // Show edit dialog
        break;
      case 'duplicate':
        // Duplicate entry
        break;
      case 'delete':
        _deleteMealEntry(entry);
        break;
    }
  }

  void _handlePlanAction(Map<String, dynamic> plan, String action) {
    switch (action) {
      case 'activate':
        // Set as current plan
        break;
      case 'edit':
        // Show edit dialog
        break;
      case 'duplicate':
        // Duplicate plan
        break;
      case 'delete':
        _deletePlan(plan);
        break;
    }
  }

  void _handleHistoryAction(Map<String, dynamic> entry, String action) {
    switch (action) {
      case 'view':
        _showMealDetails(entry);
        break;
      case 'delete':
        _deleteMealEntry(entry);
        break;
    }
  }

  void _deleteMealEntry(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this meal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(nutritionPlanningProvider.notifier)
                 .deleteNutritionEntry(entry['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(nutritionPlanningProvider.notifier)
                 .deleteNutritionPlan(plan['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Additional sheets would go here (AddMealEntrySheet, CreatePlanSheet, etc.)
class _AddMealEntrySheet extends ConsumerStatefulWidget {
  const _AddMealEntrySheet();

  @override
  ConsumerState<_AddMealEntrySheet> createState() => _AddMealEntrySheetState();
}

class _AddMealEntrySheetState extends ConsumerState<_AddMealEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMealType = 'breakfast';
  final List<Map<String, dynamic>> _foodItems = [];
  double _totalCalories = 0.0;
  final Map<String, double> _nutrients = {
    'protein': 0.0,
    'carbs': 0.0,
    'fat': 0.0,
    'fiber': 0.0,
    'calcium': 0.0,
    'iron': 0.0,
    'folate': 0.0,
  };

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
                  'Add Meal',
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
                  DropdownButtonFormField<String>(
                    value: _selectedMealType,
                    decoration: const InputDecoration(
                      labelText: 'Meal Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                      DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                      DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                      DropdownMenuItem(value: 'snack', child: Text('Snack')),
                    ],
                    onChanged: (value) => setState(() => _selectedMealType = value!),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Food Items',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _addFoodItem,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Food'),
                              ),
                            ],
                          ),
                          if (_foodItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No food items added yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ..._foodItems.map((item) => ListTile(
                              title: Text(item['name']),
                              subtitle: Text('${item['calories']} kcal'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeFoodItem(item),
                              ),
                            )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nutrition Summary',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Total Calories: ${_totalCalories.toInt()} kcal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Protein: ${_nutrients['protein']!.toInt()}g'),
                          Text('Carbs: ${_nutrients['carbs']!.toInt()}g'),
                          Text('Fat: ${_nutrients['fat']!.toInt()}g'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomElevatedButton(
                    onPressed: _foodItems.isNotEmpty ? _saveMealEntry : null,
                    text: 'Save Meal',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addFoodItem() {
    // This would show a food search dialog
    // For now, add a sample item
    setState(() {
      _foodItems.add({
        'name': 'Sample Food Item',
        'calories': 100.0,
        'protein': 5.0,
        'carbs': 15.0,
        'fat': 3.0,
      });
      _updateNutritionTotals();
    });
  }

  void _removeFoodItem(Map<String, dynamic> item) {
    setState(() {
      _foodItems.remove(item);
      _updateNutritionTotals();
    });
  }

  void _updateNutritionTotals() {
    _totalCalories = _foodItems.fold(0.0, (sum, item) => sum + (item['calories'] as double));
    
    for (final nutrient in _nutrients.keys) {
      _nutrients[nutrient] = _foodItems.fold(0.0, (sum, item) => 
          sum + (item[nutrient] as double? ?? 0.0));
    }
  }

  void _saveMealEntry() {
    if (_formKey.currentState?.validate() != true || _foodItems.isEmpty) return;

    ref.read(nutritionPlanningProvider.notifier).logNutritionEntry(
      mealType: _selectedMealType,
      foodItems: _foodItems,
      totalCalories: _totalCalories,
      nutrients: _nutrients,
    );

    Navigator.of(context).pop();
  }
}

class _CreatePlanSheet extends StatefulWidget {
  const _CreatePlanSheet();

  @override
  State<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends State<_CreatePlanSheet> {
  // Implementation would go here
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Create Plan Sheet - Implementation needed'),
      ),
    );
  }
}

class _MealDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> meal;

  const _MealDetailsSheet({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Meal Details Sheet - Implementation needed'),
      ),
    );
  }
}

class _PlanDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> plan;

  const _PlanDetailsSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Plan Details Sheet - Implementation needed'),
      ),
    );
  }
}
