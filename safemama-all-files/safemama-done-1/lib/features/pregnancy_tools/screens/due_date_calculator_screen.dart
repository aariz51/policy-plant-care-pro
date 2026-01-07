import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/utils/share_helper.dart';

class DueDateCalculatorScreen extends ConsumerStatefulWidget {
  const DueDateCalculatorScreen({super.key});

  @override
  ConsumerState<DueDateCalculatorScreen> createState() => _DueDateCalculatorScreenState();
}

class _DueDateCalculatorScreenState extends ConsumerState<DueDateCalculatorScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? results;
  
  // LMP Method
  DateTime? lmpDate;
  
  // Conception Method  
  DateTime? conceptionDate;
  
  // IVF Method
  DateTime? ivfTransferDate;
  
  // Ultrasound Method
  DateTime? ultrasoundDate;
  int ultrasoundWeeks = 12;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Due Date Calculator'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDueDateResults,
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(),
              tooltip: 'How to use',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'LMP', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Conception', icon: Icon(Icons.favorite)),
              Tab(text: 'IVF', icon: Icon(Icons.science)),
              Tab(text: 'Ultrasound', icon: Icon(Icons.medical_services)),
            ],
            indicatorColor: AppTheme.primaryPurple,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLMPTab(),
                  _buildConceptionTab(),
                  _buildIVFTab(),
                  _buildUltrasoundTab(),
                ],
              ),
            ),
            if (results != null) 
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: _buildResultsSection(),
              ),
          ],
        ),
    );
  }

  Widget _buildLMPTab() {
    return SingleChildScrollView(
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
                  AppTheme.primaryPurple.withOpacity(0.1),
                  AppTheme.accentColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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
                  'Last Menstrual Period',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Most common method used by healthcare providers',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Date Selection
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _selectDate('lmp'),
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
                            'First day of last period',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lmpDate != null
                                ? DateFormat.yMMMMd().format(lmpDate!)
                                : 'Tap to select date',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: lmpDate != null
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

          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: lmpDate != null ? () => _calculateDueDate('lmp') : null,
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
                  const Icon(Icons.calculate),
                  const SizedBox(width: 8),
                  Text(
                    'Calculate Due Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptionTab() {
    return SingleChildScrollView(
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
                  AppTheme.safeGreen.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite,
                  size: 48,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Conception Date',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'If you know the exact date of conception',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Date Selection
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _selectDate('conception'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.date_range,
                        color: AppTheme.accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of conception',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conceptionDate != null
                                ? DateFormat.yMMMMd().format(conceptionDate!)
                                : 'Tap to select date',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: conceptionDate != null
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

          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: conceptionDate != null ? () => _calculateDueDate('conception') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate),
                  const SizedBox(width: 8),
                  Text(
                    'Calculate Due Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIVFTab() {
    return SingleChildScrollView(
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
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.science,
                  size: 48,
                  color: AppTheme.safeGreen,
                ),
                const SizedBox(height: 16),
                Text(
                  'IVF Transfer Date',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'For pregnancies conceived through IVF',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Date Selection
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _selectDate('ivf'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.date_range,
                        color: AppTheme.safeGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Embryo transfer date',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ivfTransferDate != null
                                ? DateFormat.yMMMMd().format(ivfTransferDate!)
                                : 'Tap to select date',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: ivfTransferDate != null
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

          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: ivfTransferDate != null ? () => _calculateDueDate('ivf') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.safeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate),
                  const SizedBox(width: 8),
                  Text(
                    'Calculate Due Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltrasoundTab() {
    return SingleChildScrollView(
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
                  AppTheme.warningOrange.withOpacity(0.1),
                  AppTheme.accentColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.medical_services,
                  size: 48,
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ultrasound Dating',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on ultrasound measurements',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Date Selection
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _selectDate('ultrasound'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.date_range,
                        color: AppTheme.warningOrange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ultrasound date',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ultrasoundDate != null
                                ? DateFormat.yMMMMd().format(ultrasoundDate!)
                                : 'Tap to select date',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: ultrasoundDate != null
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

          const SizedBox(height: 16),

          // Weeks Selection
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timeline,
                      color: AppTheme.warningOrange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestational age at ultrasound',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$ultrasoundWeeks weeks',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          if (ultrasoundWeeks > 4) {
                            setState(() => ultrasoundWeeks--);
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
                          color: AppTheme.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$ultrasoundWeeks',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningOrange,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (ultrasoundWeeks < 40) {
                            setState(() => ultrasoundWeeks++);
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

          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: ultrasoundDate != null ? () => _calculateDueDate('ultrasound') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate),
                  const SizedBox(width: 8),
                  Text(
                    'Calculate Due Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (results == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.safeGreen.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.celebration,
                color: AppTheme.safeGreen,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Due Date',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Due Date
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Estimated Due Date',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  results?['formattedDueDate']?.toString() ?? '',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Method: ${results?['method']?.toString() ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Countdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        (results?['remainingDays'] ?? 0) >= 0 ? 'Days Remaining' : 'Days Overdue',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${(results?['remainingDays'] ?? 0).abs()}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: (results?['remainingDays'] ?? 0) >= 0 ? AppTheme.accentColor : AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (results?['currentWeek'] != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Current Week',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${results?['currentWeek']?.toString() ?? ''}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(String type) async {
    DateTime? initialDate;
    DateTime? firstDate;
    DateTime? lastDate;

    switch (type) {
      case 'lmp':
        initialDate = lmpDate ?? DateTime.now().subtract(const Duration(days: 100));
        firstDate = DateTime.now().subtract(const Duration(days: 365));
        lastDate = DateTime.now();
        break;
      case 'conception':
        initialDate = conceptionDate ?? DateTime.now().subtract(const Duration(days: 80));
        firstDate = DateTime.now().subtract(const Duration(days: 365));
        lastDate = DateTime.now();
        break;
      case 'ivf':
        initialDate = ivfTransferDate ?? DateTime.now().subtract(const Duration(days: 75));
        firstDate = DateTime.now().subtract(const Duration(days: 365));
        lastDate = DateTime.now();
        break;
      case 'ultrasound':
        initialDate = ultrasoundDate ?? DateTime.now().subtract(const Duration(days: 30));
        firstDate = DateTime.now().subtract(const Duration(days: 365));
        lastDate = DateTime.now();
        break;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate!,
      firstDate: firstDate!,
      lastDate: lastDate!,
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

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'lmp':
            lmpDate = picked;
            break;
          case 'conception':
            conceptionDate = picked;
            break;
          case 'ivf':
            ivfTransferDate = picked;
            break;
          case 'ultrasound':
            ultrasoundDate = picked;
            break;
        }
      });
    }
  }

  void _calculateDueDate(String method) {
    try {
      DateTime? dueDate;
      String methodName;
      
      switch (method) {
        case 'lmp':
          if (lmpDate == null) return;
          dueDate = lmpDate!.add(const Duration(days: 280));
          methodName = 'LMP Method';
          break;
        case 'conception':
          if (conceptionDate == null) return;
          dueDate = conceptionDate!.add(const Duration(days: 266));
          methodName = 'Conception Date';
          break;
        case 'ivf':
          if (ivfTransferDate == null) return;
          dueDate = ivfTransferDate!.add(const Duration(days: 259));
          methodName = 'IVF Transfer Date';
          break;
        case 'ultrasound':
          if (ultrasoundDate == null) return;
          final remainingWeeks = 40 - ultrasoundWeeks;
          dueDate = ultrasoundDate!.add(Duration(days: remainingWeeks * 7));
          methodName = 'Ultrasound Dating';
          break;
        default:
          return;
      }

      final now = DateTime.now();
      final remaining = dueDate.difference(now).inDays;
      final totalDays = dueDate.difference(dueDate.subtract(const Duration(days: 280))).inDays;
      final daysPassed = totalDays - remaining;
      final week = (daysPassed / 7).floor();

      setState(() {
        results = {
          'formattedDueDate': dueDate != null ? DateFormat.yMMMMd().format(dueDate) : '',
          'method': methodName,
          'remainingDays': remaining,
          'currentWeek': week.clamp(0, 40),
        };
      });
      
      _animationController.forward(from: 0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating due date: ${e.toString()}'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _shareDueDateResults() async {
    if (results == null) {
      await ShareHelper.shareToolOutput(
        toolName: 'Due Date Calculator',
        catchyHook: '📅 Calculate your baby\'s due date with SafeMama!',
      );
      return;
    }

    final dueDate = results!['formattedDueDate'] as String;
    final remainingDays = results!['remainingDays'] as int;
    final currentWeek = (results!['currentWeek'] as int?) ?? 0;

    await ShareHelper.shareDueDateCalculator(
      dueDate: dueDate,
      weeksPregnant: currentWeek,
      daysRemaining: remainingDays,
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
            const Expanded(
              child: Text('How to Use Due Date Calculator'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculate your due date using multiple methods for accurate results.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoItem('📅', 'LMP Method: Select the first day of your last menstrual period.'),
              const SizedBox(height: 12),
              _buildInfoItem('💑', 'Conception Method: Enter the date of conception if known.'),
              const SizedBox(height: 12),
              _buildInfoItem('🔬', 'IVF Method: Select the embryo transfer date for IVF pregnancies.'),
              const SizedBox(height: 12),
              _buildInfoItem('📊', 'Ultrasound Method: Enter your ultrasound date and gestational age (weeks).'),
              const SizedBox(height: 12),
              _buildInfoItem('✨', 'Results show estimated due date, gestational age, and remaining days.'),
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
