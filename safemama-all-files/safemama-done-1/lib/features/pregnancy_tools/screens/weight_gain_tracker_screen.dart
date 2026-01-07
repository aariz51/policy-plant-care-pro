import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/models/pregnancy_tools.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/premium_feature_wrapper.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/providers/app_providers.dart' as core_providers;
import 'package:safemama/features/pregnancy_tools/screens/streaming_ai_result_screen.dart';
import 'package:safemama/core/utils/share_helper.dart';

class WeightGainTrackerScreen extends ConsumerStatefulWidget {
  const WeightGainTrackerScreen({super.key});

  @override
  ConsumerState<WeightGainTrackerScreen> createState() => _WeightGainTrackerScreenState();
}

class _WeightGainTrackerScreenState extends ConsumerState<WeightGainTrackerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _prePregnancyWeightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  late AnimationController _chartAnimationController;

  double? prePregnancyWeight;
  double? currentWeight;
  double? height;
  int currentWeek = 20; // Default week
  Map<String, dynamic>? weightGainData;
  bool _isLoadingAI = false;

  List<Map<String, dynamic>> weightHistory = [
    {'date': '2024-01-15', 'weight': 65.0, 'week': 12},
    {'date': '2024-02-01', 'weight': 66.2, 'week': 15},
    {'date': '2024-02-15', 'weight': 67.8, 'week': 17},
    {'date': '2024-03-01', 'weight': 69.1, 'week': 19},
  ];

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _prePregnancyWeightController.dispose();
    _heightController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    // Load from user profile or storage
    setState(() {
      prePregnancyWeight = 65.0; // Example data
      height = 165.0; // Example data
      _prePregnancyWeightController.text = prePregnancyWeight.toString();
      _heightController.text = height.toString();
    });
    _calculateWeightGain();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    final profile = userProfile.userProfile;
    final isPremiumUser = (profile?.isPremiumUser ?? false) ||
        (profile?.isPremium ?? false);

    return PremiumFeatureWrapper(
      isPremiumUser: isPremiumUser,
      onTapWhenFree: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Premium Feature'),
            content: Text('Hospital Bag Checklist requires a premium subscription for full access.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to upgrade screen - replace with your actual route
                  // context.push('/upgrade');
                },
                child: Text('Upgrade'),
              ),
            ],
          ),
        );
      },
      featureName: 'Hospital Bag Checklist',
      currentCount: 0, // Free for all users
      limit: -1, // Unlimited
      onUsageIncrement: () {}, // No increment needed
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Weight Gain Tracker'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(),
              tooltip: 'How to use',
            ),
            if (isPremiumUser)
              IconButton(
                icon: _isLoadingAI
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                onPressed: _isLoadingAI ? null : _getAIAnalysis,
                tooltip: 'AI Analysis',
              ),
            IconButton(
              onPressed: _showWeightHistory,
              icon: const Icon(Icons.timeline),
            ),
            IconButton(
              onPressed: _shareWeightProgress,
              icon: const Icon(Icons.share),
              tooltip: 'Share Progress',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.safeGreen.withOpacity(0.1),
                      AppTheme.accentColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.safeGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.monitor_weight,
                      size: 48,
                      color: AppTheme.safeGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Weight Gain Tracker',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor your healthy weight gain throughout pregnancy',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Input Section
              Text(
                'Your Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Pre-pregnancy weight
              _buildInputCard(
                title: 'Pre-pregnancy Weight',
                controller: _prePregnancyWeightController,
                suffix: 'kg',
                icon: Icons.scale,
                color: AppTheme.primaryPurple,
                onChanged: (value) {
                  setState(() {
                    prePregnancyWeight = double.tryParse(value);
                  });
                  _calculateWeightGain();
                },
              ),

              const SizedBox(height: 16),

              // Current weight
              _buildInputCard(
                title: 'Current Weight',
                controller: _currentWeightController,
                suffix: 'kg',
                icon: Icons.monitor_weight,
                color: AppTheme.accentColor,
                onChanged: (value) {
                  setState(() {
                    currentWeight = double.tryParse(value);
                  });
                  _calculateWeightGain();
                },
              ),

              const SizedBox(height: 16),

              // Height
              _buildInputCard(
                title: 'Height',
                controller: _heightController,
                suffix: 'cm',
                icon: Icons.height,
                color: AppTheme.warningOrange,
                onChanged: (value) {
                  setState(() {
                    height = double.tryParse(value);
                  });
                  _calculateWeightGain();
                },
              ),

              const SizedBox(height: 16),

              // Current week selector
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.safeGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppTheme.safeGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Week',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Week $currentWeek of pregnancy',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (currentWeek > 1) {
                                setState(() => currentWeek--);
                                _calculateWeightGain();
                              }
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.safeGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$currentWeek',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.safeGreen,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (currentWeek < 42) {
                                setState(() => currentWeek++);
                                _calculateWeightGain();
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (weightGainData != null) ...[
                const SizedBox(height: 32),
                _buildWeightGainResults(),
              ],

              const SizedBox(height: 32),

              // Weight History Chart
              if (weightHistory.isNotEmpty) ...[
                _buildWeightChart(),
                const SizedBox(height: 32),
              ],

              // Add Weight Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _showAddWeightDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add),
                      const SizedBox(width: 8),
                      Text(
                        'Log Weight',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tips Card
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required TextEditingController controller,
    required String suffix,
    required IconData icon,
    required Color color,
    required Function(String) onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter $title',
                      suffixText: suffix,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightGainResults() {
    if (weightGainData == null) return const SizedBox.shrink();

    final currentGain = weightGainData!['currentGain'];
    final status = weightGainData!['status'];
    final category = weightGainData!['category'];
    final minTotalGain = weightGainData!['minTotalGain'];
    final maxTotalGain = weightGainData!['maxTotalGain'];

    Color statusColor;
    switch (status) {
      case 'On track':
        statusColor = AppTheme.safeGreen;
        break;
      case 'Below recommended':
        statusColor = AppTheme.warningOrange;
        break;
      case 'Above recommended':
        statusColor = AppTheme.dangerRed;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: statusColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Weight Gain Analysis',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current gain
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Weight Gain',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${currentGain.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // BMI Category & Recommendations
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Total',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '$minTotalGain - $maxTotalGain kg',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          _buildProgressBar(currentGain, minTotalGain, maxTotalGain),
        ],
      ),
    );
  }

Widget _buildProgressBar(double current, double min, double max) {
  final progress = (current / max).clamp(0.0, 1.0);
  final isInRange = current >= min && current <= max;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Progress to Healthy Range',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
      const SizedBox(height: 8),

      // ✅ Progress Bar Container
      Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // ✅ Healthy range indicator (fixed positional args)
            Positioned(
              left: (min / max) * MediaQuery.of(context).size.width * 0.7,
              right: ((max - current.clamp(min, max)) / max) *
                  MediaQuery.of(context).size.width *
                  0.7,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // ✅ Current progress
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isInRange
                      ? AppTheme.safeGreen
                      : AppTheme.warningOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 4),

      // ✅ Labels under the bar
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '0 kg',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            '${max.toStringAsFixed(0)} kg',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    ],
  );
}


  Widget _buildWeightChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight Progress Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              child: Center(
                child: Text(
                  '📊 Chart implementation would go here\n\nShowing weight progression over time with healthy range indicators',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Healthy Weight Gain Tips',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('🥗', 'Eat nutrient-dense foods'),
          _buildTipItem('🚶‍♀️', 'Stay active with safe exercises'),
          _buildTipItem('💧', 'Drink plenty of water'),
          _buildTipItem('📱', 'Weigh yourself weekly, same time'),
          _buildTipItem('👩‍⚕️', 'Discuss concerns with your healthcare provider'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _calculateWeightGain() {
    if (prePregnancyWeight != null && currentWeight != null && height != null) {
      final bmi = prePregnancyWeight! / (height! / 100 * height! / 100);

      setState(() {
        weightGainData = PregnancyCalculator.getWeightGainRecommendations(
          prePregnancyBMI: bmi,
          currentWeek: currentWeek,
          currentWeight: currentWeight!,
          prePregnancyWeight: prePregnancyWeight!,
        );
      });
    }
  }

  void _showAddWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Weight (kg)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                currentWeight = double.tryParse(value);
                _currentWeightController.text = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (currentWeight != null) {
                setState(() {
                  weightHistory.insert(0, {
                    'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'weight': currentWeight,
                    'week': currentWeek,
                  });
                });
                _calculateWeightGain();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryPurple),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'How to Use Weight Gain Tracker',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track your weight gain throughout pregnancy to ensure healthy progress.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoItem('1️⃣', 'Enter your pre-pregnancy weight and height to calculate BMI.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'Log your current weight and pregnancy week regularly.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'Log your current weight and pregnancy week regularly.'),
                const SizedBox(height: 12),
                _buildInfoItem('3️⃣', 'View your weight gain chart to track progress over time.'),
                const SizedBox(height: 12),
                _buildInfoItem('4️⃣', 'Monitor if your weight gain is within recommended ranges.'),
                const SizedBox(height: 12),
                _buildInfoItem('💡', 'Recommended weight gain varies by BMI: Normal (11-16 kg), Overweight (7-11 kg), Underweight (13-18 kg).'),
                const SizedBox(height: 12),
                _buildInfoItem('⚠️', 'Always consult your healthcare provider for personalized weight gain recommendations.'),
              ],
            ),
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

  void _showWeightHistory() {
    // Implementation for showing full weight history
  }

  Future<void> _shareWeightProgress() async {
    try {
      if (currentWeight == null || prePregnancyWeight == null || height == null) {
        // Share without data - invitation to use the tool
        await ShareHelper.shareToolOutput(
          toolName: 'Weight Gain Tracker',
          catchyHook: '⚖️ Track your healthy pregnancy weight with SafeMama!',
        );
        return;
      }

      final bmiCategory = weightGainData?['category'] ?? 'Normal';

      await ShareHelper.shareWeightGainTracker(
        currentWeight: currentWeight!,
        prePregnancyWeight: prePregnancyWeight!,
        currentWeek: currentWeek,
        bmiCategory: bmiCategory,
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

  Future<void> _getAIAnalysis() async {
    if (currentWeight == null || prePregnancyWeight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all required data first')),
      );
      return;
    }

    try {
      final bmiCategory = weightGainData?['category'] ?? 'Normal';

      // Create streaming response
      final stream = ref.read(core_providers.apiServiceProvider).weightGainTrackerAIStream(
        currentWeight: currentWeight!,
        prePregnancyWeight: prePregnancyWeight!,
        currentWeek: currentWeek,
        height: height!,
        bmi: bmiCategory,
      );

      // Navigate to streaming AI result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreamingAIResultScreen(
            title: 'Weight Gain Analysis',
            icon: Icons.monitor_weight,
            color: AppTheme.accentColor,
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
