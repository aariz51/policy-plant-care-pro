import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/theme/app_theme.dart';

class CervicalMucusScreen extends ConsumerStatefulWidget {
  const CervicalMucusScreen({super.key});

  @override
  ConsumerState<CervicalMucusScreen> createState() => _CervicalMucusScreenState();
}

class _CervicalMucusScreenState extends ConsumerState<CervicalMucusScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedType = '';
  String notes = '';

  final List<Map<String, dynamic>> mucusTypes = [
    {
      'type': 'dry',
      'title': 'Dry',
      'description': 'No fluid',
      'icon': Icons.blur_off,
      'color': AppTheme.textSecondary,
      'fertility': 'Low',
    },
    {
      'type': 'sticky',
      'title': 'Sticky',
      'description': 'Thick and paste-like',
      'icon': Icons.water_drop,
      'color': Colors.brown,
      'fertility': 'Low',
    },
    {
      'type': 'creamy',
      'title': 'Creamy',
      'description': 'Lotion-like consistency',
      'icon': Icons.water_drop,
      'color': Colors.amber,
      'fertility': 'Medium',
    },
    {
      'type': 'watery',
      'title': 'Watery',
      'description': 'Clear and thin',
      'icon': Icons.water,
      'color': Colors.lightBlue,
      'fertility': 'Medium-High',
    },
    {
      'type': 'egg_white',
      'title': 'Egg White',
      'description': 'Clear, stretchy, slippery',
      'icon': Icons.egg,
      'color': AppTheme.safeGreen,
      'fertility': 'High',
    },
  ];

  // Sample data
  final List<Map<String, dynamic>> recentEntries = [
    {'date': DateTime.now().subtract(const Duration(days: 1)), 'type': 'egg_white'},
    {'date': DateTime.now().subtract(const Duration(days: 2)), 'type': 'watery'},
    {'date': DateTime.now().subtract(const Duration(days: 3)), 'type': 'creamy'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Cervical Mucus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'How to use',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop, color: AppTheme.accentColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Monitor Changes in Cervical Fluid',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cervical mucus changes throughout your cycle. Egg-white consistency indicates peak fertility.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Date Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mucus Type Selection
            Text(
              'Select Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mucusTypes.length,
              itemBuilder: (context, index) {
                final type = mucusTypes[index];
                final isSelected = selectedType == type['type'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? type['color'] as Color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => selectedType = type['type']),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (type['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              type['icon'] as IconData,
                              color: type['color'] as Color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        type['title'],
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getFertilityColor(type['fertility']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        type['fertility'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _getFertilityColor(type['fertility']),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type['description'],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: type['color'] as Color),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Notes
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any relevant notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              onChanged: (value) => notes = value,
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Entry'),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Entries
            _buildRecentEntries(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Entries',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentEntries.length,
          itemBuilder: (context, index) {
            final entry = recentEntries[index];
            final type = mucusTypes.firstWhere((t) => t['type'] == entry['type']);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (type['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    type['icon'] as IconData,
                    color: type['color'] as Color,
                  ),
                ),
                title: Text(
                  type['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(entry['date'])),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteEntry(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getFertilityColor(String fertility) {
    switch (fertility) {
      case 'High':
        return AppTheme.safeGreen;
      case 'Medium-High':
        return AppTheme.accentColor;
      case 'Medium':
        return AppTheme.warningOrange;
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _saveEntry() {
    if (selectedType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a type')),
      );
      return;
    }

    // Add save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry saved successfully!')),
    );
    
    setState(() => selectedType = '');
  }

  void _deleteEntry(int index) {
    setState(() => recentEntries.removeAt(index));
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.accentColor),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('How to Track Cervical Mucus'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cervical mucus changes throughout your cycle and is a key indicator of fertility.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoItem('💧', 'Dry: No cervical mucus present (low fertility period).'),
              const SizedBox(height: 12),
              _buildInfoItem('🌰', 'Sticky: Thick and paste-like consistency (low fertility).'),
              const SizedBox(height: 12),
              _buildInfoItem('🧈', 'Creamy: Lotion-like, white or yellowish (medium fertility).'),
              const SizedBox(height: 12),
              _buildInfoItem('💧', 'Watery: Clear and thin, flows easily (medium-high fertility).'),
              const SizedBox(height: 12),
              _buildInfoItem('🥚', 'Egg White: Clear, stretchy, slippery - indicates peak fertility!'),
              const SizedBox(height: 12),
              _buildInfoItem('📅', 'Track daily to identify your fertile window. Mucus becomes more fertile as ovulation approaches.'),
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

}
