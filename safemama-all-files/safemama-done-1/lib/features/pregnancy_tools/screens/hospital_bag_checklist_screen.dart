import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/features/pregnancy_tools/screens/streaming_ai_result_screen.dart';
import 'package:safemama/core/utils/share_helper.dart';

class HospitalBagChecklistScreen extends ConsumerStatefulWidget {
  const HospitalBagChecklistScreen({super.key});

  @override
  ConsumerState<HospitalBagChecklistScreen> createState() => _HospitalBagChecklistScreenState();
}

class _HospitalBagChecklistScreenState extends ConsumerState<HospitalBagChecklistScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _progressAnimationController;
  bool _isLoadingAI = false;

  final Map<String, List<Map<String, dynamic>>> checklistData = {
    'essentials': [
      {'item': 'Insurance cards & ID', 'category': 'Documents', 'checked': false, 'priority': 'high'},
      {'item': 'Birth plan copies', 'category': 'Documents', 'checked': false, 'priority': 'medium'},
      {'item': 'Hospital registration papers', 'category': 'Documents', 'checked': false, 'priority': 'high'},
      {'item': 'Phone & charger', 'category': 'Electronics', 'checked': false, 'priority': 'high'},
      {'item': 'Camera', 'category': 'Electronics', 'checked': false, 'priority': 'medium'},
      {'item': 'Comfortable going-home outfit', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
    ],
    'mom': [
      {'item': 'Comfortable nightgowns', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Nursing bras (2-3)', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Comfortable underwear', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Slippers with grip', 'category': 'Footwear', 'checked': false, 'priority': 'high'},
      {'item': 'Robe', 'category': 'Clothing', 'checked': false, 'priority': 'medium'},
      {'item': 'Maternity pads', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'item': 'Nursing pads', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'item': 'Toiletries', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'item': 'Hair ties', 'category': 'Personal Care', 'checked': false, 'priority': 'medium'},
      {'item': 'Lip balm', 'category': 'Personal Care', 'checked': false, 'priority': 'low'},
      {'item': 'Snacks', 'category': 'Food', 'checked': false, 'priority': 'medium'},
    ],
    'baby': [
      {'item': 'Going-home outfit (2 sizes)', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Onesies (newborn & 0-3 months)', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Sleep gowns or sleepers', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Socks or booties', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Hat', 'category': 'Clothing', 'checked': false, 'priority': 'medium'},
      {'item': 'Swaddle blankets', 'category': 'Bedding', 'checked': false, 'priority': 'high'},
      {'item': 'Car seat (installed)', 'category': 'Safety', 'checked': false, 'priority': 'high'},
      {'item': 'Burp cloths', 'category': 'Feeding', 'checked': false, 'priority': 'medium'},
      {'item': 'Diapers (if preferred brand)', 'category': 'Care', 'checked': false, 'priority': 'low'},
    ],
    'partner': [
      {'item': 'Change of clothes', 'category': 'Clothing', 'checked': false, 'priority': 'high'},
      {'item': 'Toiletries', 'category': 'Personal Care', 'checked': false, 'priority': 'high'},
      {'item': 'Snacks & drinks', 'category': 'Food', 'checked': false, 'priority': 'medium'},
      {'item': 'Pillow from home', 'category': 'Comfort', 'checked': false, 'priority': 'medium'},
      {'item': 'Entertainment (books, tablet)', 'category': 'Entertainment', 'checked': false, 'priority': 'low'},
      {'item': 'Comfortable shoes', 'category': 'Footwear', 'checked': false, 'priority': 'medium'},
      {'item': 'Cash for parking/vending', 'category': 'Practical', 'checked': false, 'priority': 'medium'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadChecklistData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _loadChecklistData() {
    // Load saved checklist state from storage
    // For now, we'll use the default data
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = checklistData.values.expand((list) => list).length;
    final completedItems = checklistData.values
        .expand((list) => list)
        .where((item) => item['checked'] == true)
        .length;
    final progressPercentage = totalItems > 0 ? (completedItems / totalItems) : 0.0;
    
    return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Hospital Bag Checklist'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(),
              tooltip: 'How to use',
            ),
            IconButton(
              icon: _isLoadingAI 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              onPressed: _isLoadingAI ? null : _getAISuggestions,
              tooltip: 'AI Packing Suggestions',
            ),
            IconButton(
              onPressed: _resetChecklist,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: _shareChecklist,
              icon: const Icon(Icons.share),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Essentials', icon: Icon(Icons.star)),
              Tab(text: 'For Mom', icon: Icon(Icons.pregnant_woman)),
              Tab(text: 'For Baby', icon: Icon(Icons.child_care)),
              Tab(text: 'For Partner', icon: Icon(Icons.person)),
            ],
            indicatorColor: AppTheme.primaryPurple,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: Column(
          children: [
            // Progress Header
            Container(
              margin: const EdgeInsets.all(20),
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
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        size: 32,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hospital Bag Ready?',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '$completedItems of $totalItems items packed',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progressPercentage,
                              strokeWidth: 6,
                              backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressPercentage >= 0.8 
                                    ? AppTheme.safeGreen
                                    : progressPercentage >= 0.5
                                        ? AppTheme.warningOrange
                                        : AppTheme.primaryPurple,
                              ),
                            ),
                            Text(
                              '${(progressPercentage * 100).toInt()}%',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (progressPercentage >= 0.8) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.safeGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.safeGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Great job! Your hospital bag is almost ready!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.safeGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Pack your bag around 35-36 weeks. Better to be prepared!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            
            // Checklist Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChecklistTab('essentials'),
                  _buildChecklistTab('mom'),
                  _buildChecklistTab('baby'),
                  _buildChecklistTab('partner'),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addCustomItem,
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
    );
  }

  Widget _buildChecklistTab(String tabKey) {
    final items = checklistData[tabKey] ?? [];
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    
    // Group items by category
    for (final item in items) {
      final category = item['category'] as String;
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final category = groupedItems.keys.elementAt(index);
        final categoryItems = groupedItems[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              margin: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ),
            
            // Category Items
            ...categoryItems.map((item) => _buildChecklistItem(item, tabKey)),
          ],
        );
      },
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item, String tabKey) {
    final isChecked = item['checked'] as bool;
    final priority = item['priority'] as String;
    
    Color priorityColor;
    IconData priorityIcon;
    switch (priority) {
      case 'high':
        priorityColor = AppTheme.dangerRed;
        priorityIcon = Icons.priority_high;
        break;
      case 'medium':
        priorityColor = AppTheme.warningOrange;
        priorityIcon = Icons.remove;
        break;
      case 'low':
        priorityColor = AppTheme.safeGreen;
        priorityIcon = Icons.expand_more;
        break;
      default:
        priorityColor = AppTheme.textSecondary;
        priorityIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isChecked ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isChecked 
              ? AppTheme.safeGreen.withOpacity(0.05)
              : Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: GestureDetector(
            onTap: () => _toggleItem(item, tabKey),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? AppTheme.safeGreen : Colors.transparent,
                border: Border.all(
                  color: isChecked ? AppTheme.safeGreen : AppTheme.textSecondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isChecked
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          title: Text(
            item['item'] as String,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isChecked ? TextDecoration.lineThrough : null,
              color: isChecked 
                  ? AppTheme.textSecondary
                  : AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  priorityIcon,
                  size: 16,
                  color: priorityColor,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showItemOptions(item, tabKey),
                icon: const Icon(Icons.more_vert),
                iconSize: 16,
              ),
            ],
          ),
          onTap: () => _toggleItem(item, tabKey),
        ),
      ),
    );
  }

  void _toggleItem(Map<String, dynamic> item, String tabKey) {
    setState(() {
      item['checked'] = !(item['checked'] as bool);
    });
    
    // Animate progress if item was checked
    if (item['checked'] as bool) {
      _progressAnimationController.forward().then((_) {
        _progressAnimationController.reverse();
      });
    }
    
    // Save to storage
    _saveChecklistData();
  }

  void _showItemOptions(Map<String, dynamic> item, String tabKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item'] as String,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.edit, color: AppTheme.primaryPurple),
                      title: const Text('Edit Item'),
                      onTap: () {
                        Navigator.pop(context);
                        _editItem(item, tabKey);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.note_add, color: AppTheme.accentColor),
                      title: const Text('Add Note'),
                      onTap: () {
                        Navigator.pop(context);
                        _addNoteToItem(item);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete, color: AppTheme.dangerRed),
                      title: const Text('Remove Item'),
                      onTap: () {
                        Navigator.pop(context);
                        _removeItem(item, tabKey);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addCustomItem() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController itemController = TextEditingController();
        String selectedTab = 'essentials';
        String selectedPriority = 'medium';
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Custom Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: itemController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTab,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'essentials', child: Text('Essentials')),
                    DropdownMenuItem(value: 'mom', child: Text('For Mom')),
                    DropdownMenuItem(value: 'baby', child: Text('For Baby')),
                    DropdownMenuItem(value: 'partner', child: Text('For Partner')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedTab = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('High Priority')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                    DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedPriority = value!);
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
                  if (itemController.text.isNotEmpty) {
                    // Use setState of the parent widget
                    this.setState(() {
                      checklistData[selectedTab]!.add({
                        'item': itemController.text,
                        'category': 'Custom',
                        'checked': false,
                        'priority': selectedPriority,
                      });
                    });
                    _saveChecklistData();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editItem(Map<String, dynamic> item, String tabKey) {
    // Implementation for editing item
  }

  void _addNoteToItem(Map<String, dynamic> item) {
    // Implementation for adding notes to item
  }

  void _removeItem(Map<String, dynamic> item, String tabKey) {
    setState(() {
      checklistData[tabKey]!.remove(item);
    });
    _saveChecklistData();
  }

  void _resetChecklist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Checklist'),
        content: const Text('This will uncheck all items. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (final category in checklistData.values) {
                  for (final item in category) {
                    item['checked'] = false;
                  }
                }
              });
              _saveChecklistData();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _shareChecklist() async {
    try {
      final totalItems = checklistData.values.expand((list) => list).length;
      final completedItems = checklistData.values
          .expand((list) => list)
          .where((item) => item['checked'] == true)
          .length;

      await ShareHelper.shareHospitalBag(
        completedItems: completedItems,
        totalItems: totalItems,
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

  void _saveChecklistData() {
    // Save checklist state to local storage
    // Implementation would use SharedPreferences or similar
  }

  Future<void> _getAISuggestions() async {
    try {
      // Get packed and unpacked items
      final packedItems = checklistData.values
          .expand((list) => list)
          .where((item) => item['checked'] == true)
          .map((item) => item['item'] as String)
          .toList();
      
      final missingItems = checklistData.values
          .expand((list) => list)
          .where((item) => item['checked'] == false)
          .map((item) => item['item'] as String)
          .toList();

      // Create streaming response
      final stream = ref.read(apiServiceProvider).hospitalBagAIStream(
        packedItems: packedItems,
        missingItems: missingItems,
      );

      // Navigate to streaming AI result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreamingAIResultScreen(
            title: 'Hospital Bag Suggestions',
            icon: Icons.local_hospital,
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
                'How to Use Hospital Bag Checklist',
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
                  'Prepare for your hospital stay with this comprehensive checklist organized by category.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoItem('1️⃣', 'Browse through the four tabs: Essentials, For Mom, For Baby, and For Partner.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'Tap on any item to check it off as you pack it.'),
                const SizedBox(height: 12),
                _buildInfoItem('3️⃣', 'Add custom items if needed using the + button.'),
                const SizedBox(height: 12),
                _buildInfoItem('4️⃣', 'Use the share button to send your checklist to your partner or family.'),
                const SizedBox(height: 12),
                _buildInfoItem('📅', 'Start packing 2-3 weeks before your due date to avoid last-minute stress.'),
                const SizedBox(height: 12),
                _buildInfoItem('💡', 'Items are organized by priority (high, medium, low) to help you focus on essentials first.'),
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
