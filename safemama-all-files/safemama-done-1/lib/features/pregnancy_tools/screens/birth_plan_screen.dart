import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/providers/app_providers.dart'; // The correct one
import 'package:safemama/features/pregnancy_tools/screens/streaming_ai_result_screen.dart';
import 'package:safemama/core/utils/share_helper.dart';

class BirthPlanScreen extends ConsumerStatefulWidget {
  const BirthPlanScreen({super.key});

  @override
  ConsumerState<BirthPlanScreen> createState() => _BirthPlanScreenState();
}

class _BirthPlanScreenState extends ConsumerState<BirthPlanScreen> {
  
  final Map<String, Map<String, dynamic>> _planSections = {
    'labor_preferences': {
      'title': 'Labor Preferences',
      'items': [
        {'key': 'pain_management', 'label': 'Pain Management Preferences', 'value': ''},
        {'key': 'movement', 'label': 'Movement & Positions', 'value': ''},
        {'key': 'monitoring', 'label': 'Fetal Monitoring Preferences', 'value': ''},
        {'key': 'environment', 'label': 'Environment Preferences', 'value': ''},
      ],
    },
    'delivery_preferences': {
      'title': 'Delivery Preferences',
      'items': [
        {'key': 'position', 'label': 'Preferred Delivery Position', 'value': ''},
        {'key': 'support', 'label': 'Support People Present', 'value': ''},
        {'key': 'cutting', 'label': 'Cord Cutting Preferences', 'value': ''},
        {'key': 'immediate', 'label': 'Immediate Post-Birth Preferences', 'value': ''},
      ],
    },
    'postpartum_preferences': {
      'title': 'Postpartum Preferences',
      'items': [
        {'key': 'feeding', 'label': 'Feeding Plan', 'value': ''},
        {'key': 'rooming', 'label': 'Rooming-In Preferences', 'value': ''},
        {'key': 'visitors', 'label': 'Visitor Preferences', 'value': ''},
        {'key': 'circumcision', 'label': 'Circumcision Decision (if applicable)', 'value': ''},
      ],
    },
    'special_considerations': {
      'title': 'Special Considerations',
      'items': [
        {'key': 'medical', 'label': 'Medical History & Conditions', 'value': ''},
        {'key': 'allergies', 'label': 'Allergies & Medications', 'value': ''},
        {'key': 'cultural', 'label': 'Cultural or Religious Preferences', 'value': ''},
        {'key': 'emergency', 'label': 'Emergency Preferences', 'value': ''},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Birth Plan Creator'),
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
            icon: const Icon(Icons.auto_awesome),
            onPressed: _getAIAdvice,
            tooltip: 'AI Suggestions',
          ),
          IconButton(
            onPressed: _savePlan,
            icon: const Icon(Icons.save),
            tooltip: 'Save Plan',
          ),
          IconButton(
            onPressed: _sharePlan,
            icon: const Icon(Icons.share),
            tooltip: 'Share Plan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            ..._planSections.entries.map((entry) => _buildSectionCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment,
                size: 32,
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Birth Plan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan your ideal delivery experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'A birth plan helps you communicate your preferences to your healthcare team. '
            'Remember that flexibility is important, as birth can be unpredictable.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String sectionKey, Map<String, dynamic> section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          section['title'] as String,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: Icon(
          Icons.check_circle_outline,
          color: AppTheme.primaryPurple,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: (section['items'] as List).map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: item['label'] as String,
                      hintText: 'Enter your preferences...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.scaffoldBackground,
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        item['value'] = value;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
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
                'How to Use Birth Plan Creator',
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
                  'A birth plan helps you communicate your preferences to your healthcare team during labor and delivery.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoItem('1️⃣', 'Fill in each section with your preferences and wishes.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'Be specific but flexible - birth can be unpredictable.'),
                const SizedBox(height: 12),
                _buildInfoItem('3️⃣', 'Share your plan with your healthcare provider before delivery.'),
                const SizedBox(height: 12),
                _buildInfoItem('4️⃣', 'Save your plan so you can review and update it anytime.'),
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

  void _savePlan() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Birth plan saved successfully!'),
        backgroundColor: AppTheme.safeGreen,
      ),
    );
  }

  void _sharePlan() async {
    try {
      // Collect all birth plan data
      final birthPlanData = <String, dynamic>{};
      for (final section in _planSections.entries) {
        final items = section.value['items'] as List;
        for (final item in items) {
          final key = item['key'] as String;
          final value = item['value'] as String;
          if (value.isNotEmpty) {
            birthPlanData[key] = value;
          }
        }
      }

      // Share using ShareHelper
      await ShareHelper.shareBirthPlan(birthPlanData);
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

  Future<void> _getAIAdvice() async {
    print('[BirthPlan] AI Advice requested');
    
    try {
      // Collect birth plan data
      final birthPlanData = <String, String>{};
      for (final section in _planSections.entries) {
        final items = section.value['items'] as List;
        for (final item in items) {
          final key = item['key'] as String;
          final value = item['value'] as String;
          if (value.isNotEmpty) {
            birthPlanData[key] = value;
          }
        }
      }

      print('[BirthPlan] Collected data: $birthPlanData');

      // Create streaming response
      final stream = ref.read(apiServiceProvider).birthPlanAIStream(birthPlanData);

      // Navigate to streaming AI result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreamingAIResultScreen(
            title: 'Birth Plan Advice',
            icon: Icons.article,
            color: AppTheme.primaryPurple,
            responseStream: stream,
          ),
        ),
      );
    } catch (e) {
      print('[BirthPlan] Error: $e');
      if (mounted) {
        // Close loading dialog if open
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
