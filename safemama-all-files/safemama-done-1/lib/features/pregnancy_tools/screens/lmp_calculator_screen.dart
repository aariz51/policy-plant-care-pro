import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/models/pregnancy_tools.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/utils/share_helper.dart';

class LmpCalculatorScreen extends ConsumerStatefulWidget {
  const LmpCalculatorScreen({super.key});

  @override
  ConsumerState<LmpCalculatorScreen> createState() => _LmpCalculatorScreenState();
}

class _LmpCalculatorScreenState extends ConsumerState<LmpCalculatorScreen> 
    with SingleTickerProviderStateMixin {
  DateTime? selectedLMP;
  Map<String, dynamic>? results;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectLMP() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedLMP ?? DateTime.now().subtract(const Duration(days: 100)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'SELECT LAST MENSTRUAL PERIOD',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedLMP) {
      setState(() {
        selectedLMP = picked;
        results = PregnancyCalculator.calculateFromLMP(picked);
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('LMP Calculator'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLmpResults,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'How to use',
          ),
        ],
      ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
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
                    Icon(
                      Icons.calendar_today,
                      size: 48,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Calculate Your Pregnancy',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your last menstrual period date to track your pregnancy journey',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Date Selection Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: _selectLMP,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.date_range,
                            color: AppTheme.primaryPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Menstrual Period',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedLMP != null
                                    ? DateFormat.yMMMMd().format(selectedLMP!)
                                    : 'Tap to select date',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: selectedLMP != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (results != null) ...[
                const SizedBox(height: 32),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildResultsCard(),
                ),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildResultsCard() {
    if (results == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Main Results Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.safeGreen.withOpacity(0.1),
                AppTheme.primaryPurple.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.safeGreen.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.baby_changing_station,
                    color: AppTheme.safeGreen,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Pregnancy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Gestational Age
              _buildResultItem(
                icon: Icons.schedule,
                title: 'Gestational Age',
                value: results!['gestationalAge'],
                subtitle: 'Current stage of pregnancy',
              ),
              
              const SizedBox(height: 16),
              
              // Due Date
              _buildResultItem(
                icon: Icons.event,
                title: 'Estimated Due Date',
                value: DateFormat.yMMMMd().format(results!['dueDate']),
                subtitle: '${results!['daysUntilDue']} days remaining',
              ),
              
              const SizedBox(height: 16),
              
              // Trimester
              _buildResultItem(
                icon: Icons.timeline,
                title: 'Trimester',
                value: results!['trimester'],
                subtitle: _getTrimesterString(results!['trimester']),
              ),
              
              const SizedBox(height: 20),
              
              // Baby Size
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your baby is about the size of:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Baby size information will be available soon',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryPurple,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTrimesterString(String trimester) {
    switch (trimester) {
      case 'First Trimester':
        return 'Organ formation & early development';
      case 'Second Trimester':
        return 'Growth & movement begin';
      case 'Third Trimester':
        return 'Final growth & preparation for birth';
      default:
        return '';
    }
  }

  void _shareLmpResults() async {
    if (results == null || selectedLMP == null) {
      await ShareHelper.shareToolOutput(
        toolName: 'LMP Calculator',
        catchyHook: '📅 Track your pregnancy journey with SafeMama!',
      );
      return;
    }

    final dueDate = results!['dueDate'] as DateTime;
    final gestationalAge = results!['gestationalAge'] as String;
    
    // Extract week number from gestational age string (e.g., "14 weeks, 3 days" -> 14)
    final weekMatch = RegExp(r'(\d+)\s*week').firstMatch(gestationalAge);
    final currentWeek = weekMatch != null ? int.parse(weekMatch.group(1)!) : 0;

    await ShareHelper.shareLMPCalculator(
      lmpDate: DateFormat.yMMMMd().format(selectedLMP!),
      dueDate: DateFormat.yMMMMd().format(dueDate),
      currentWeek: currentWeek,
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
                'How to Use LMP Calculator',
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
                  'This calculator helps you track your pregnancy based on your Last Menstrual Period (LMP) date.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoItem('1️⃣', 'Tap the date field to select the first day of your last menstrual period.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'The calculator automatically calculates your gestational age, due date, and current trimester.'),
                const SizedBox(height: 12),
                _buildInfoItem('3️⃣', 'The due date is calculated using the standard 40-week (280 days) pregnancy duration from LMP.'),
                const SizedBox(height: 12),
                _buildInfoItem('4️⃣', 'Your results show the current stage of pregnancy and remaining days until delivery.'),
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
