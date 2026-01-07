import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/navigation/app_router.dart';

class PregnancyToolsHubScreen extends ConsumerStatefulWidget {
  const PregnancyToolsHubScreen({super.key});

  @override
  ConsumerState<PregnancyToolsHubScreen> createState() => _PregnancyToolsHubScreenState();
}

class _PregnancyToolsHubScreenState extends ConsumerState<PregnancyToolsHubScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> calculatorTools = [
    {
      'title': 'LMP Calculator',
      'subtitle': 'Calculate pregnancy from last period',
      'icon': Icons.calendar_today,
      'color': AppTheme.primaryPurple,
      'route': '/pregnancy-tools/lmp-calculator',
      'isPremium': false,
    },
    {
      'title': 'Due Date Calculator',
      'subtitle': 'Multiple calculation methods',
      'icon': Icons.event,
      'color': const Color(0xFF64B5F6), // Light blue color
      'route': '/pregnancy-tools/due-date-calculator',
      'isPremium': false, // Free tool, always colored
    },
    {
      'title': 'TTC Tracker',
      'subtitle': 'Track fertility and ovulation',
      'icon': Icons.favorite,
      'color': AppTheme.safeGreen,
      'route': '/fertility/ttc-tracker',
      'isPremium': false,
    },
    {
      'title': 'Baby Name Generator',
      'subtitle': 'AI-powered name suggestions',
      'icon': Icons.child_care,
      'color': AppTheme.warningOrange,
      'route': '/pregnancy-tools/baby-name-generator',
      'isPremium': true,
    },
  ];

  final List<Map<String, dynamic>> monitoringTools = [
    {
      'title': 'Kick Counter',
      'subtitle': 'Track baby movements',
      'icon': Icons.baby_changing_station,
      'color': AppTheme.safeGreen,
      'route': '/pregnancy-tools/kick-counter',
      'isPremium': false,
    },
    {
      'title': 'Contraction Timer',
      'subtitle': 'Time labor contractions',
      'icon': Icons.timer,
      'color': AppTheme.dangerRed,
      'route': '/pregnancy-tools/contraction-timer',
      'isPremium': false,
    },
    {
      'title': 'Weight Gain Tracker',
      'subtitle': 'Monitor healthy weight gain',
      'icon': Icons.monitor_weight,
      'color': const Color(0xFFFFB74D), // Light orange color
      'route': '/pregnancy-tools/weight-gain-tracker',
      'isPremium': true,
    },
  ];

  final List<Map<String, dynamic>> preparationTools = [
    {
      'title': 'Hospital Bag Checklist',
      'subtitle': 'Essential items for delivery',
      'icon': Icons.local_hospital,
      'color': AppTheme.primaryPurple,
      'route': '/pregnancy-tools/hospital-bag-checklist',
      'isPremium': false,
    },
    {
      'title': 'Baby Shopping List',
      'subtitle': 'Complete newborn essentials',
      'icon': Icons.shopping_cart,
      'color': const Color(0xFF4DD0E1), // Light teal/cyan color
      'route': '/pregnancy-tools/baby-shopping-list',
      'isPremium': true, // Premium tool with PRO badge
    },
    {
      'title': 'Birth Plan Creator',
      'subtitle': 'Plan your ideal delivery',
      'icon': Icons.assignment,
      'color': AppTheme.safeGreen,
      'route': '/pregnancy-tools/birth-plan',
      'isPremium': true,
    },
    {
      'title': 'Postpartum Tracker',
      'subtitle': 'Recovery and baby care tracking',
      'icon': Icons.healing,
      'color': AppTheme.warningOrange,
      'route': '/pregnancy-tools/postpartum-tracker',
      'isPremium': true,
    },
    {
      'title': 'Vaccine Tracker',
      'subtitle': 'Track your child\'s vaccinations',
      'icon': Icons.vaccines,
      'color': AppTheme.primaryPurple,
      'route': '/pregnancy-tools/vaccine-tracker',
      'isPremium': true,
    },
  ];

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
    final userProfile = ref.watch(userProfileProvider);
    final profile = userProfile.userProfile;
    final isPremiumUser = profile?.isPremiumUser ?? (profile?.isPremium ?? false);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Pregnancy Tools'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calculators', icon: Icon(Icons.calculate)),
            Tab(text: 'Monitoring', icon: Icon(Icons.monitor_heart)),
            Tab(text: 'Preparation', icon: Icon(Icons.checklist)),
          ],
          indicatorColor: AppTheme.primaryPurple,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildToolsGrid(calculatorTools, isPremiumUser),
          _buildToolsGrid(monitoringTools, isPremiumUser),
          _buildToolsGrid(preparationTools, isPremiumUser),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(List<Map<String, dynamic>> tools, bool isPremiumUser) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(
          title: tool['title'] as String,
          description: tool['subtitle'] as String,
          icon: tool['icon'] as IconData,
          onTap: () => context.push(tool['route'] as String),
          color: tool['color'] as Color,
          isPremium: tool['isPremium'] as bool,
        );
      },
    );
  }

  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    bool isPremium = false,
  }) {
    final userProfile = ref.watch(userProfileProvider);
    final bool isPremiumUser = userProfile.userProfile?.isPremiumUser ?? 
                              (userProfile.userProfile?.isPremium ?? false);

    // Determine if this tool is accessible (free tools or premium user)
    final bool isAccessible = !isPremium || isPremiumUser;

    // Fix card color logic:
    // Free tools always show original color (colored for both free and premium users).
    // Premium tools show color only for premium users, or black/dark gray for free users.
    final Color displayColor = isPremium
        ? (isPremiumUser ? color : Colors.grey.shade900)
        : color;

    return GestureDetector(
      onTap: isAccessible ? onTap : () => _showUpgradeDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: displayColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: displayColor,
                    size: 22,
                  ),
                ),
                const Spacer(),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPremiumUser 
                          ? AppTheme.newPremiumGold.withOpacity(0.2) 
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: isPremiumUser 
                              ? AppTheme.newPremiumGold 
                              : Colors.grey.shade600,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isPremiumUser 
                                ? AppTheme.newPremiumGold 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isAccessible ? Colors.black87 : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isAccessible ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Open Tool',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: displayColor,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: displayColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'This tool is available for premium members only. Upgrade to access all pregnancy tools and features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRouter.upgradePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.newPremiumGold,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
