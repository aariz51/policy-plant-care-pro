import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/theme/app_theme.dart';

class SymptomsMoodScreen extends ConsumerStatefulWidget {
  const SymptomsMoodScreen({super.key});

  @override
  ConsumerState<SymptomsMoodScreen> createState() => _SymptomsMoodScreenState();
}

class _SymptomsMoodScreenState extends ConsumerState<SymptomsMoodScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedMood = '';
  Set<String> selectedSymptoms = {};
  String notes = '';

  final List<Map<String, dynamic>> moodOptions = [
    {'value': 'happy', 'emoji': '😊', 'label': 'Happy', 'color': AppTheme.safeGreen},
    {'value': 'calm', 'emoji': '😌', 'label': 'Calm', 'color': AppTheme.accentColor},
    {'value': 'neutral', 'emoji': '😐', 'label': 'Neutral', 'color': AppTheme.textSecondary},
    {'value': 'anxious', 'emoji': '😟', 'label': 'Anxious', 'color': AppTheme.warningOrange},
    {'value': 'sad', 'emoji': '😢', 'label': 'Sad', 'color': AppTheme.dangerRed},
  ];

  final List<Map<String, dynamic>> symptomOptions = [
    {'value': 'cramps', 'icon': Icons.healing, 'label': 'Cramps'},
    {'value': 'bloating', 'icon': Icons.bubble_chart, 'label': 'Bloating'},
    {'value': 'tender_breasts', 'icon': Icons.favorite, 'label': 'Tender Breasts'},
    {'value': 'headache', 'icon': Icons.psychology, 'label': 'Headache'},
    {'value': 'fatigue', 'icon': Icons.bed, 'label': 'Fatigue'},
    {'value': 'nausea', 'icon': Icons.sick, 'label': 'Nausea'},
    {'value': 'back_pain', 'icon': Icons.accessibility_new, 'label': 'Back Pain'},
    {'value': 'acne', 'icon': Icons.face, 'label': 'Acne'},
    {'value': 'food_cravings', 'icon': Icons.restaurant, 'label': 'Food Cravings'},
    {'value': 'increased_libido', 'icon': Icons.favorite_border, 'label': 'Increased Libido'},
    {'value': 'spotting', 'icon': Icons.water_drop, 'label': 'Spotting'},
    {'value': 'other', 'icon': Icons.more_horiz, 'label': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Symptoms & Mood'),
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
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: AppTheme.primaryPurple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Track Daily Symptoms & Mood',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recording how you feel helps identify patterns in your cycle and predict fertility windows.',
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

            // Mood Selection
            Text(
              'How Are You Feeling?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: moodOptions.map((mood) {
                  final isSelected = selectedMood == mood['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedMood = mood['value']),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (mood['color'] as Color).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? mood['color'] as Color
                                : AppTheme.textSecondary.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              mood['emoji'],
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mood['label'],
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected 
                                    ? mood['color'] as Color
                                    : AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Symptoms Selection
            Text(
              'Select Symptoms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: symptomOptions.map((symptom) {
                final isSelected = selectedSymptoms.contains(symptom['value']);
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        symptom['icon'] as IconData,
                        size: 16,
                        color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(symptom['label']),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedSymptoms.add(symptom['value']);
                      } else {
                        selectedSymptoms.remove(symptom['value']);
                      }
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryPurple.withOpacity(0.1),
                  checkmarkColor: AppTheme.primaryPurple,
                  side: BorderSide(
                    color: isSelected 
                        ? AppTheme.primaryPurple
                        : AppTheme.textSecondary.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Notes
            TextField(
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Add any other observations...',
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
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
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
    if (selectedMood.isEmpty && selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least a mood or symptom')),
      );
      return;
    }

    // Add save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry saved successfully!')),
    );
    
    setState(() {
      selectedMood = '';
      selectedSymptoms.clear();
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryPurple),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('How to Track Symptoms & Mood'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logging daily symptoms and mood helps you understand your cycle patterns.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoItem('😊', 'Select your mood: Happy, Calm, Neutral, Anxious, or Sad.'),
              const SizedBox(height: 12),
              _buildInfoItem('🏥', 'Select all symptoms that apply to you today (multiple selection allowed).'),
              const SizedBox(height: 12),
              _buildInfoItem('📝', 'Add optional notes to track specific details or observations.'),
              const SizedBox(height: 12),
              _buildInfoItem('📅', 'Select the date for your entry (defaults to today).'),
              const SizedBox(height: 12),
              _buildInfoItem('💡', 'Tracking patterns helps you predict your cycle and identify fertile days.'),
              const SizedBox(height: 12),
              _buildInfoItem('📊', 'Review your entries to understand how symptoms correlate with your cycle phases.'),
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
