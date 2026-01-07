import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/utils/share_helper.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/features/pregnancy_tools/providers/baby_name_providers.dart';
import 'package:safemama/core/providers/app_providers.dart';

class BabyNameGeneratorScreen extends ConsumerStatefulWidget {
  const BabyNameGeneratorScreen({super.key});

  @override
  ConsumerState<BabyNameGeneratorScreen> createState() => _BabyNameGeneratorScreenState();
}

class _BabyNameGeneratorScreenState extends ConsumerState<BabyNameGeneratorScreen> 
    with TickerProviderStateMixin {
  String selectedGender = 'Any';
  String selectedOrigin = 'Any';
  String selectedMeaning = 'Any';
  List<String> favoriteNames = [];
  late AnimationController _shimmerController;
  late AnimationController _cardController;

  final List<String> genderOptions = ['Any', 'Boy', 'Girl', 'Unisex'];
  final List<String> originOptions = [
    'Any', 'American', 'Arabic', 'Chinese', 'English', 'French', 'German', 
    'Greek', 'Hebrew', 'Hindi', 'Irish', 'Italian', 'Japanese', 'Latin', 
    'Russian', 'Sanskrit', 'Spanish', 'Turkish'
  ];
  final List<String> meaningOptions = [
    'Any', 'Strong', 'Beautiful', 'Wise', 'Brave', 'Kind', 'Noble', 
    'Peaceful', 'Joyful', 'Blessed', 'Light', 'Love', 'Hope'
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1500));
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // ✅ FIX: Check premium status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPremiumAccess();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // ✅ FIX: Premium check method
  void _checkPremiumAccess() {
    final userProfile = ref.read(userProfileNotifierProvider);
    final isPremium = userProfile.userProfile?.isPremiumUser ?? false;

    if (!isPremium) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomPaywallDialog(
          title: 'Premium Feature',
          message: 'Baby Name Generator is a premium feature. Upgrade to access AI-powered name suggestions tailored to your preferences.',
          icon: Icons.child_care,
          iconColor: AppTheme.accentColor,
          type: PaywallType.upgrade,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileNotifierProvider);
    final babyNameState = ref.watch(babyNameGeneratorProvider);
    final isPremium = userProfile.userProfile?.isPremiumUser ?? false;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Baby Name Generator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareBabyNames,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'How to use',
          ),
          IconButton(
            onPressed: () => _showFavoriteNames(),
            icon: Stack(
              children: [
                const Icon(Icons.favorite),
                if (favoriteNames.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${favoriteNames.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
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
                    AppTheme.accentColor.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.child_care,
                    size: 48,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find the Perfect Name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-powered suggestions based on your preferences',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isPremium) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.newPremiumGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.newPremiumGold,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, 
                            color: AppTheme.newPremiumGold, 
                            size: 16
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Premium Feature',
                            style: TextStyle(
                              color: AppTheme.newPremiumGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Filters Section
            Text(
              'Customize Your Search',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Gender Selection
            _buildFilterCard(
              title: 'Gender',
              icon: Icons.wc,
              color: AppTheme.primaryPurple,
              child: Wrap(
                spacing: 8,
                children: genderOptions.map((gender) {
                  final isSelected = selectedGender == gender;
                  return FilterChip(
                    label: Text(gender),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedGender = gender);
                    },
                    selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryPurple,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Origin Selection
            _buildFilterCard(
              title: 'Origin/Culture',
              icon: Icons.public,
              color: AppTheme.accentColor,
              child: Wrap(
                spacing: 8,
                children: originOptions.take(8).map((origin) {
                  final isSelected = selectedOrigin == origin;
                  return FilterChip(
                    label: Text(origin),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedOrigin = origin);
                    },
                    selectedColor: AppTheme.accentColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.accentColor,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Meaning Selection
            _buildFilterCard(
              title: 'Meaning',
              icon: Icons.psychology,
              color: AppTheme.safeGreen,
              child: Wrap(
                spacing: 8,
                children: meaningOptions.take(8).map((meaning) {
                  final isSelected = selectedMeaning == meaning;
                  return FilterChip(
                    label: Text(meaning),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedMeaning = meaning);
                    },
                    selectedColor: AppTheme.safeGreen.withOpacity(0.2),
                    checkmarkColor: AppTheme.safeGreen,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (babyNameState.isLoading || !isPremium) ? null : _generateNames,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? AppTheme.accentColor : AppTheme.textSecondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: babyNameState.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Generating...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isPremium ? Icons.auto_awesome : Icons.lock),
                          const SizedBox(width: 8),
                          Text(
                            isPremium ? 'Generate Names' : 'Premium Required',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            if (babyNameState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.dangerRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.dangerRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        babyNameState.error!,
                        style: TextStyle(color: AppTheme.dangerRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (babyNameState.suggestions.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildNameSuggestions(babyNameState.suggestions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildNameSuggestions(List<Map<String, dynamic>> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name Suggestions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final name = suggestion['name'] as String;
            final meaning = suggestion['meaning'] as String;
            final origin = suggestion['origin'] as String;
            final gender = suggestion['gender'] as String? ?? 'Any';
            final isFavorite = favoriteNames.contains(name);

            return AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                final animationValue = Curves.easeOutBack.transform(
                  (((_cardController.value * suggestions.length) - index) / 1)
                      .clamp(0.0, 1.0),
                );

                return Transform.translate(
                  offset: Offset(0, 50 * (1 - animationValue)),
                  child: Opacity(
                    opacity: animationValue,
                    child: _buildNameCard(
                      name: name,
                      meaning: meaning,
                      origin: origin,
                      gender: gender,
                      isFavorite: isFavorite,
                      onFavoriteToggle: () => _toggleFavorite(name),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNameCard({
    required String name,
    required String meaning,
    required String origin,
    required String gender,
    required bool isFavorite,
    required VoidCallback onFavoriteToggle,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppTheme.primaryPurple.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppTheme.accentColor : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Meaning: $meaning',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildInfoChip(origin, AppTheme.safeGreen),
                const SizedBox(width: 8),
                _buildInfoChip(gender, AppTheme.primaryPurple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _generateNames() {
    final isPremium = ref.read(userProfileNotifierProvider).userProfile?.isPremiumUser ?? false;
    
    if (!isPremium) {
      showDialog(
        context: context,
        builder: (context) => const CustomPaywallDialog(
          title: 'Premium Feature',
          message: 'Baby Name Generator requires a premium subscription. Upgrade now to access AI-powered name suggestions!',
          icon: Icons.child_care,
          iconColor: AppTheme.accentColor,
          type: PaywallType.upgrade,
        ),
      );
      return;
    }

    ref.read(babyNameGeneratorProvider.notifier).generateNames(
      gender: selectedGender,
      origin: selectedOrigin,
      meaning: selectedMeaning,
    );
    _cardController.forward(from: 0.0);
  }

  void _toggleFavorite(String name) {
    setState(() {
      if (favoriteNames.contains(name)) {
        favoriteNames.remove(name);
      } else {
        favoriteNames.add(name);
      }
    });
  }

  void _showFavoriteNames() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: AppTheme.accentColor),
                  const SizedBox(width: 12),
                  Text(
                    'Favorite Names',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favoriteNames.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorite names yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: favoriteNames.length,
                      itemBuilder: (context, index) {
                        final name = favoriteNames[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(Icons.favorite, color: AppTheme.accentColor),
                            title: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () => _toggleFavorite(name),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareBabyNames() async {
    final babyNameState = ref.read(babyNameGeneratorProvider);
    
    if (babyNameState.suggestions.isEmpty) {
      await ShareHelper.shareToolOutput(
        toolName: 'Baby Name Generator',
        catchyHook: '👶 Discover the perfect name for your baby with SafeMama!',
      );
      return;
    }

    // Extract names from suggestions
    final generatedNames = babyNameState.suggestions
        .map((suggestion) => suggestion['name'] as String)
        .toList();

    await ShareHelper.shareBabyNameGenerator(
      generatedNames: generatedNames,
      gender: selectedGender,
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.accentColor),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'How to Use Baby Name Generator',
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
                  'Discover unique baby names powered by AI based on your preferences and cultural background.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoItem('1️⃣', 'Select gender, origin, and style preferences for name suggestions.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'Enter keywords or themes you\'d like the names to reflect.'),
                const SizedBox(height: 12),
                _buildInfoItem('3️⃣', 'Generate personalized name suggestions with meanings.'),
                const SizedBox(height: 12),
                _buildInfoItem('4️⃣', 'Save your favorite names to review later with your partner.'),
                const SizedBox(height: 12),
                _buildInfoItem('💡', 'Try different combinations of preferences to discover more name options.'),
                const SizedBox(height: 12),
                _buildInfoItem('⚠️', 'Name suggestions are generated by AI. Always verify meanings and cultural significance.'),
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
}
