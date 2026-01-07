import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/premium_feature_wrapper.dart';
import 'package:safemama/navigation/providers/user_profile_provider.dart';
import 'package:safemama/core/utils/share_helper.dart';

class BabyShoppingListScreen extends ConsumerStatefulWidget {
  const BabyShoppingListScreen({super.key});

  @override
  ConsumerState<BabyShoppingListScreen> createState() => _BabyShoppingListScreenState();
}

class _BabyShoppingListScreenState extends ConsumerState<BabyShoppingListScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final Map<String, List<Map<String, dynamic>>> shoppingData = {
    'feeding': [
      {'item': 'Bottles (4-6)', 'price': '₹800-1200', 'checked': false, 'priority': 'high', 'note': 'BPA-free preferred'},
      {'item': 'Bottle brush', 'price': '₹200-400', 'checked': false, 'priority': 'high', 'note': ''},
      {'item': 'Burp cloths (6-8)', 'price': '₹600-1000', 'checked': false, 'priority': 'high', 'note': ''},
      {'item': 'Bibs (6-10)', 'price': '₹500-800', 'checked': false, 'priority': 'medium', 'note': 'Waterproof backing'},
      {'item': 'Breast pump', 'price': '₹3000-8000', 'checked': false, 'priority': 'medium', 'note': 'Electric recommended'},
      {'item': 'Nursing pillow', 'price': '₹1200-2500', 'checked': false, 'priority': 'medium', 'note': ''},
      {'item': 'Sterilizer', 'price': '₹2000-5000', 'checked': false, 'priority': 'high', 'note': 'Steam or UV'},
      {'item': 'Formula (if needed)', 'price': '₹800-1200', 'checked': false, 'priority': 'low', 'note': 'Consult doctor'},
    ],
    'clothing': [
      {'item': 'Onesies (8-10)', 'price': '₹1200-2000', 'checked': false, 'priority': 'high', 'note': 'Mix of NB & 0-3M'},
      {'item': 'Sleep gowns (6-8)', 'price': '₹1000-1600', 'checked': false, 'priority': 'high', 'note': 'Easy diaper access'},
      {'item': 'Pants/Leggings (6-8)', 'price': '₹800-1400', 'checked': false, 'priority': 'medium', 'note': ''},
      {'item': 'Socks (8-12 pairs)', 'price': '₹400-600', 'checked': false, 'priority': 'high', 'note': 'Stay-on design'},
      {'item': 'Hats (3-4)', 'price': '₹300-600', 'checked': false, 'priority': 'medium', 'note': 'Soft cotton'},
      {'item': 'Mittens (2-3 pairs)', 'price': '₹200-400', 'checked': false, 'priority': 'medium', 'note': 'Prevent scratching'},
      {'item': 'Swaddle blankets (4-6)', 'price': '₹1200-2400', 'checked': false, 'priority': 'high', 'note': 'Muslin preferred'},
      {'item': 'Going-home outfit', 'price': '₹800-1500', 'checked': false, 'priority': 'high', 'note': '2 sizes'},
    ],
    'bathing': [
      {'item': 'Baby bathtub', 'price': '₹800-2000', 'checked': false, 'priority': 'high', 'note': 'Non-slip bottom'},
      {'item': 'Bath towels (3-4)', 'price': '₹1200-2000', 'checked': false, 'priority': 'high', 'note': 'Hooded preferred'},
      {'item': 'Washcloths (8-10)', 'price': '₹400-800', 'checked': false, 'priority': 'high', 'note': 'Soft cotton'},
      {'item': 'Baby shampoo/body wash', 'price': '₹300-800', 'checked': false, 'priority': 'high', 'note': 'Tear-free formula'},
      {'item': 'Baby lotion', 'price': '₹200-600', 'checked': false, 'priority': 'medium', 'note': 'Hypoallergenic'},
      {'item': 'Bath thermometer', 'price': '₹200-500', 'checked': false, 'priority': 'medium', 'note': 'Digital preferred'},
      {'item': 'Bath support/seat', 'price': '₹600-1500', 'checked': false, 'priority': 'low', 'note': 'For later'},
    ],
    'diapering': [
      {'item': 'Diapers (NB & Size 1)', 'price': '₹1000-2000', 'checked': false, 'priority': 'high', 'note': 'Start with small packs'},
      {'item': 'Baby wipes', 'price': '₹400-800', 'checked': false, 'priority': 'high', 'note': 'Sensitive skin'},
      {'item': 'Diaper rash cream', 'price': '₹200-500', 'checked': false, 'priority': 'high', 'note': 'Zinc oxide based'},
      {'item': 'Changing pad', 'price': '₹800-1500', 'checked': false, 'priority': 'high', 'note': 'Waterproof'},
      {'item': 'Diaper pail', 'price': '₹1500-3000', 'checked': false, 'priority': 'medium', 'note': 'Odor control'},
      {'item': 'Baby powder', 'price': '₹150-400', 'checked': false, 'priority': 'low', 'note': 'Talc-free'},
      {'item': 'Cloth diapers (if using)', 'price': '₹2000-5000', 'checked': false, 'priority': 'low', 'note': 'Eco-friendly option'},
    ],
    'nursery': [
      {'item': 'Crib/Cot', 'price': '₹5000-15000', 'checked': false, 'priority': 'high', 'note': 'Safety certified'},
      {'item': 'Crib mattress', 'price': '₹2000-8000', 'checked': false, 'priority': 'high', 'note': 'Firm & breathable'},
      {'item': 'Fitted crib sheets (3-4)', 'price': '₹800-1600', 'checked': false, 'priority': 'high', 'note': 'Organic cotton'},
      {'item': 'Night light', 'price': '₹500-1500', 'checked': false, 'priority': 'medium', 'note': 'Dimmable'},
      {'item': 'Blackout curtains', 'price': '₹1000-3000', 'checked': false, 'priority': 'medium', 'note': 'Better sleep'},
      {'item': 'White noise machine', 'price': '₹1500-4000', 'checked': false, 'priority': 'medium', 'note': 'Sleep aid'},
      {'item': 'Mobile', 'price': '₹1000-3000', 'checked': false, 'priority': 'low', 'note': 'Visual stimulation'},
      {'item': 'Dresser/changing table', 'price': '₹8000-25000', 'checked': false, 'priority': 'medium', 'note': 'Safety straps'},
    ],
    'safety': [
      {'item': 'Car seat', 'price': '₹8000-25000', 'checked': false, 'priority': 'high', 'note': 'Infant carrier'},
      {'item': 'Stroller', 'price': '₹5000-20000', 'checked': false, 'priority': 'high', 'note': 'Travel system compatible'},
      {'item': 'Baby gates', 'price': '₹2000-5000', 'checked': false, 'priority': 'low', 'note': 'For later mobility'},
      {'item': 'Outlet covers', 'price': '₹200-500', 'checked': false, 'priority': 'low', 'note': 'Childproofing'},
      {'item': 'Corner guards', 'price': '₹300-800', 'checked': false, 'priority': 'low', 'note': 'Furniture protection'},
      {'item': 'Cabinet locks', 'price': '₹500-1200', 'checked': false, 'priority': 'low', 'note': 'Later safety'},
      {'item': 'Baby monitor', 'price': '₹3000-12000', 'checked': false, 'priority': 'medium', 'note': 'Audio/video options'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadShoppingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadShoppingData() {
    // Load saved shopping list state from storage
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final totalItems = shoppingData.values.expand((list) => list).length;
    final purchasedItems = shoppingData.values
        .expand((list) => list)
        .where((item) => item['checked'] == true)
        .length;
    final totalEstimatedCost = _calculateTotalCost();
    
    final profile = userProfile.userProfile;
    final isPremiumUser = (profile?.isPremiumUser ?? false) || 
                          (profile?.isPremium ?? false);
    
    return PremiumFeatureWrapper(
  isPremiumUser: isPremiumUser,
  onTapWhenFree: () {                                          // ← ADD THIS CALLBACK
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
          title: const Text('Baby Shopping List'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          actions: [
            IconButton(
              onPressed: _showBudgetCalculator,
              icon: const Icon(Icons.calculate),
            ),
            IconButton(
              onPressed: _shareShoppingList,
              icon: const Icon(Icons.share),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Feeding', icon: Icon(Icons.baby_changing_station)),
              Tab(text: 'Clothing', icon: Icon(Icons.checkroom)),
              Tab(text: 'Bathing', icon: Icon(Icons.bathtub)),
              Tab(text: 'Diapering', icon: Icon(Icons.child_care)),
              Tab(text: 'Nursery', icon: Icon(Icons.bed)),
              Tab(text: 'Safety', icon: Icon(Icons.security)),
            ],
            indicatorColor: AppTheme.accentColor,
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: Column(
          children: [
            // Budget Overview
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.1),
                    AppTheme.safeGreen.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 32,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$purchasedItems of $totalItems items',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Est. Budget',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        totalEstimatedCost,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Shopping Categories
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildShoppingTab('feeding', 'Feeding Essentials'),
                  _buildShoppingTab('clothing', 'Baby Clothing'),
                  _buildShoppingTab('bathing', 'Bath Time'),
                  _buildShoppingTab('diapering', 'Diaper Changes'),
                  _buildShoppingTab('nursery', 'Nursery Setup'),
                  _buildShoppingTab('safety', 'Safety First'),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddItemDialog,
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Add Item'),
        ),
      ),
    );
  }

  Widget _buildShoppingTab(String tabKey, String title) {
    final items = shoppingData[tabKey] ?? [];
    final categoryTotal = _calculateCategoryTotal(items);
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Category header with budget info
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      Text(
                        '${items.where((item) => item['checked'] == true).length} of ${items.length} items',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Category Budget',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      categoryTotal,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        
        final item = items[index - 1];
        return _buildShoppingItem(item, tabKey);
      },
    );
  }

  Widget _buildShoppingItem(Map<String, dynamic> item, String tabKey) {
    final isChecked = item['checked'] as bool;
    final priority = item['priority'] as String;
    
    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = AppTheme.dangerRed;
        break;
      case 'medium':
        priorityColor = AppTheme.warningOrange;
        break;
      case 'low':
        priorityColor = AppTheme.safeGreen;
        break;
      default:
        priorityColor = AppTheme.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isChecked ? 1 : 3,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleItem(item),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['item'] as String,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked 
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                priority.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: priorityColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.currency_rupee,
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['price'] as String,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((item['note'] as String).isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item['note'] as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showItemDetails(item, tabKey),
                    icon: const Icon(Icons.more_vert),
                    iconSize: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleItem(Map<String, dynamic> item) {
    setState(() {
      item['checked'] = !(item['checked'] as bool);
    });
    _saveShoppingData();
  }

  void _showItemDetails(Map<String, dynamic> item, String tabKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item'] as String,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.currency_rupee, color: AppTheme.accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Price Range: ${item['price']}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Shopping tips
                    Text(
                      'Shopping Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['note'] as String,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Compare prices online vs in-store\n• Look for bundle deals\n• Check reviews before purchasing\n• Consider second-hand options for some items',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _addToWishlist(item);
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Add to Wishlist'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _markAsPurchased(item);
                            },
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text('Mark Purchased'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.safeGreen,
                            ),
                          ),
                        ),
                      ],
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

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController itemController = TextEditingController();
        final TextEditingController priceController = TextEditingController();
        final TextEditingController noteController = TextEditingController();
        String selectedCategory = 'feeding';
        String selectedPriority = 'medium';
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Shopping Item'),
            content: SingleChildScrollView(
              child: Column(
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
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price Range (e.g., ₹500-800)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'feeding', child: Text('Feeding')),
                      DropdownMenuItem(value: 'clothing', child: Text('Clothing')),
                      DropdownMenuItem(value: 'bathing', child: Text('Bathing')),
                      DropdownMenuItem(value: 'diapering', child: Text('Diapering')),
                      DropdownMenuItem(value: 'nursery', child: Text('Nursery')),
                      DropdownMenuItem(value: 'safety', child: Text('Safety')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (itemController.text.isNotEmpty) {
                    setState(() {
                      shoppingData[selectedCategory]!.add({
                        'item': itemController.text,
                        'price': priceController.text.isEmpty ? '₹0-0' : priceController.text,
                        'checked': false,
                        'priority': selectedPriority,
                        'note': noteController.text,
                      });
                    });
                    _saveShoppingData();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Item'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBudgetCalculator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Calculator'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estimated Total Budget',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _calculateTotalCost(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This is an estimated range based on average prices. Actual costs may vary based on brands, quality, and location.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _calculateTotalCost() {
    int minTotal = 0;
    int maxTotal = 0;
    
    for (final category in shoppingData.values) {
      for (final item in category) {
        final priceStr = item['price'] as String;
        final prices = _extractPriceRange(priceStr);
        minTotal += prices['min']!;
        maxTotal += prices['max']!;
      }
    }
    
    return '₹${minTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} - ₹${maxTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _calculateCategoryTotal(List<Map<String, dynamic>> items) {
    int minTotal = 0;
    int maxTotal = 0;
    
    for (final item in items) {
      final priceStr = item['price'] as String;
      final prices = _extractPriceRange(priceStr);
      minTotal += prices['min']!;
      maxTotal += prices['max']!;
    }
    
    return '₹${minTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} - ₹${maxTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Map<String, int> _extractPriceRange(String priceStr) {
    final regex = RegExp(r'₹(\d+)-(\d+)');
    final match = regex.firstMatch(priceStr);
    
    if (match != null) {
      return {
        'min': int.parse(match.group(1)!),
        'max': int.parse(match.group(2)!),
      };
    }
    
    return {'min': 0, 'max': 0};
  }

  void _addToWishlist(Map<String, dynamic> item) {
    // Implementation for adding to wishlist
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['item']} added to wishlist'),
        backgroundColor: AppTheme.safeGreen,
      ),
    );
  }

  void _markAsPurchased(Map<String, dynamic> item) {
    setState(() {
      item['checked'] = true;
    });
    _saveShoppingData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['item']} marked as purchased'),
        backgroundColor: AppTheme.safeGreen,
      ),
    );
  }

  void _shareShoppingList() async {
    try {
      // Count total and purchased items
      int totalItems = 0;
      int purchasedItems = 0;
      
      for (final category in shoppingData.values) {
        totalItems += category.length;
        purchasedItems += category.where((item) => item['checked'] == true).length;
      }

      if (purchasedItems == 0 && totalItems == 0) {
        // No data - share invitation
        await ShareHelper.shareToolOutput(
          toolName: 'Baby Shopping List',
          catchyHook: '🛍️ Prepare for your little one with SafeMama\'s Baby Shopping List!',
        );
        return;
      }

      // Share with data
      final progressPercent = totalItems > 0 ? ((purchasedItems / totalItems) * 100).toStringAsFixed(0) : '0';
      
      final output = '''
🛍️ Baby Shopping Progress

✅ Purchased: $purchasedItems/$totalItems items ($progressPercent%)
${purchasedItems == totalItems ? '🎉 Shopping complete! Ready for baby!' : '📝 Still shopping...'}
''';

      await ShareHelper.shareToolOutput(
        toolName: 'Baby Shopping List',
        userOutput: output,
        catchyHook: '🛍️ Preparing for my baby with SafeMama!',
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

  void _saveShoppingData() {
    // Save shopping list state to local storage
  }
}
