import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/features/pregnancy_tools/providers/contraction_timer_providers.dart' as ct_providers;
import 'package:safemama/features/pregnancy_tools/screens/tool_ai_info_screen.dart';
import 'package:safemama/features/pregnancy_tools/screens/streaming_ai_result_screen.dart';
import 'package:safemama/core/providers/app_providers.dart' as core_providers;
import 'package:safemama/core/utils/share_helper.dart';

class ContractionTimerScreen extends ConsumerStatefulWidget {
  const ContractionTimerScreen({super.key});

  @override
  ConsumerState<ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends ConsumerState<ContractionTimerScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  bool _isTimerRunning = false;
  DateTime? _contractionStartTime;
  Timer? _timer;
  int _currentDuration = 0;
  int _selectedIntensity = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractionState = ref.watch(ct_providers.contractionTimerProvider);
    final isTimingContraction = contractionState.currentContraction != null;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Contraction Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            onPressed: contractionState.contractions.isNotEmpty ? _resetSession : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Session',
          ),
          IconButton(
            onPressed: () => _showContractionHistory(),
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'How to use',
            onPressed: _showInfoDialog,
          ),
          IconButton(
            onPressed: _shareContractionData,
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
                      AppTheme.warningOrange.withOpacity(0.1),
                      AppTheme.accentColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.warningOrange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 48,
                      color: AppTheme.warningOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Contraction Timer',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTimingContraction
                          ? 'Timing in progress... Tap "Stop" when contraction ends'
                          : 'Track your contractions to know when it\'s time for the hospital',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Current Status
              if (contractionState.contractions.isNotEmpty) ...[
                _buildContractionStats(contractionState.contractions),
                const SizedBox(height: 32),
              ],

              // Main Timer Button
              Center(
                child: GestureDetector(
                  onTap: _isTimerRunning ? _stopContraction : _startContraction,
                  child: AnimatedBuilder(
                    animation: _isTimerRunning ? _pulseAnimation : _waveAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isTimerRunning ? _pulseAnimation.value : 1.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Wave Effect for idle state
                            if (!_isTimerRunning)
                              ...List.generate(3, (index) {
                                return AnimatedBuilder(
                                  animation: _waveAnimation,
                                  builder: (context, child) {
                                    final delay = index * 0.3;
                                    final animationValue = ((_waveAnimation.value - delay) % 1.0).clamp(0.0, 1.0);
                                    
                                    return Container(
                                      width: 220 + (60 * animationValue),
                                      height: 220 + (60 * animationValue),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.warningOrange.withOpacity(0.3 * (1 - animationValue)),
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                            
                            // Main Button
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: _isTimerRunning 
                                    ? [
                                        AppTheme.dangerRed,
                                        AppTheme.dangerRed.withOpacity(0.8),
                                      ]
                                    : [
                                        AppTheme.warningOrange,
                                        AppTheme.warningOrange.withOpacity(0.8),
                                      ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isTimerRunning ? AppTheme.dangerRed : AppTheme.warningOrange).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isTimerRunning ? Icons.stop : Icons.play_arrow,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isTimerRunning ? 'STOP' : 'START',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_isTimerRunning) ...[
                                    const SizedBox(height: 4),
                                    StreamBuilder(
                                      stream: Stream.periodic(const Duration(seconds: 1)),
                                      builder: (context, snapshot) {
                                        final duration = _contractionStartTime != null
                                            ? DateTime.now().difference(_contractionStartTime!)
                                            : Duration.zero;
                                        return Text(
                                          _formatDuration(duration),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Intensity Selector (only during contraction)
              if (_isTimerRunning) ...[
                _buildIntensitySelector(),
                const SizedBox(height: 32),
              ],

              // Recent Contractions
              if (contractionState.contractions.isNotEmpty) ...[
                _buildRecentContractions(contractionState.contractions.take(5).toList()),
                const SizedBox(height: 32),
              ],

              // Labor Signs Information
              _buildLaborSignsCard(),
            ],
          ),
        ),
      floatingActionButton: contractionState.contractions.length >= 3
          ? FloatingActionButton.extended(
              onPressed: _analyzeContractions,
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze'),
            )
          : null,
    );
  }

  Widget _buildContractionStats(List<Map<String, dynamic>> contractions) {
    if (contractions.length < 2) return const SizedBox.shrink();

    final recentContractions = contractions.take(5).toList();
    final intervals = <Duration>[];
    final durations = <Duration>[];

    for (int i = 1; i < recentContractions.length; i++) {
      final currentStartTimeStr = recentContractions[i]['startTime'] ?? recentContractions[i]['start_time'];
      final previousStartTimeStr = recentContractions[i - 1]['startTime'] ?? recentContractions[i - 1]['start_time'];
      
      if (currentStartTimeStr != null && currentStartTimeStr is String &&
          previousStartTimeStr != null && previousStartTimeStr is String) {
        try {
          final current = DateTime.parse(currentStartTimeStr);
          final previous = DateTime.parse(previousStartTimeStr);
          intervals.add(current.difference(previous));
        } catch (e) {
          // Skip invalid date
        }
      }
    }

    for (final contraction in recentContractions) {
      final endTimeStr = contraction['endTime'] ?? contraction['end_time'];
      final startTimeStr = contraction['startTime'] ?? contraction['start_time'];
      
      if (endTimeStr != null && endTimeStr is String &&
          startTimeStr != null && startTimeStr is String) {
        try {
          final start = DateTime.parse(startTimeStr);
          final end = DateTime.parse(endTimeStr);
          durations.add(end.difference(start));
        } catch (e) {
          // Skip invalid date
        }
      }
    }

    final avgInterval = intervals.isNotEmpty
        ? intervals.reduce((a, b) => Duration(seconds: a.inSeconds + b.inSeconds)) ~/ intervals.length
        : Duration.zero;
    
    final avgDuration = durations.isNotEmpty
        ? durations.reduce((a, b) => Duration(seconds: a.inSeconds + b.inSeconds)) ~/ durations.length
        : Duration.zero;

    return Container(
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
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contraction Pattern',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Frequency',
                  value: _formatDuration(avgInterval),
                  subtitle: 'apart',
                  color: AppTheme.primaryPurple,
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Duration',
                  value: _formatDuration(avgDuration),
                  subtitle: 'average',
                  color: AppTheme.accentColor,
                  icon: Icons.timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLaborProgressIndicator(avgInterval, avgDuration),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaborProgressIndicator(Duration avgInterval, Duration avgDuration) {
    String status;
    Color statusColor;
    String advice;

    if (avgInterval.inMinutes <= 5 && avgDuration.inSeconds >= 60) {
      status = 'Active Labor - Time to go!';
      statusColor = AppTheme.dangerRed;
      advice = 'Head to the hospital immediately. Your contractions are consistent and strong.';
    } else if (avgInterval.inMinutes <= 10 && avgDuration.inSeconds >= 45) {
      status = 'Early Active Labor';
      statusColor = AppTheme.warningOrange;
      advice = 'Labor is progressing. Prepare to leave for the hospital soon.';
    } else if (avgInterval.inMinutes <= 20 && avgDuration.inSeconds >= 30) {
      status = 'Early Labor';
      statusColor = AppTheme.accentColor;
      advice = 'Early labor has begun. Rest and stay hydrated. Monitor the pattern.';
    } else {
      status = 'Pre-labor';
      statusColor = AppTheme.safeGreen;
      advice = 'These may be practice contractions. Keep monitoring.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            advice,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySelector() {
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
              'Contraction Intensity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final intensity = index + 1;
                final isSelected = _selectedIntensity == intensity;
                
                return GestureDetector(
                  onTap: () => _selectIntensity(intensity),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.warningOrange
                          : AppTheme.warningOrange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.warningOrange,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$intensity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isSelected ? Colors.white : AppTheme.warningOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mild',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Very Strong',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContractions(List<Map<String, dynamic>> contractions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Contractions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contractions.length,
          itemBuilder: (context, index) {
            final contraction = contractions[index];
            return _buildContractionCard(contraction, index);
          },
        ),
      ],
    );
  }

  Widget _buildContractionCard(Map<String, dynamic> contraction, int index) {
    final startTimeStr = contraction['startTime'];
    if (startTimeStr == null || startTimeStr is! String) {
      return const SizedBox.shrink();
    }
    final startTime = DateTime.parse(startTimeStr);
    final endTimeStr = contraction['endTime'];
    final endTime = endTimeStr != null && endTimeStr is String
        ? DateTime.parse(endTimeStr)
        : null;
    final duration = endTime != null 
        ? endTime.difference(startTime)
        : Duration.zero;
    final intensity = contraction['intensity'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endTime != null
                        ? 'Duration: ${_formatDuration(duration)}'
                        : 'In progress...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat.jm().format(startTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (intensity > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getIntensityColor(intensity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Level $intensity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getIntensityColor(intensity),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborSignsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.safeGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.safeGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'When to Go to Hospital',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSignItem('⏱️', 'Contractions 5 minutes apart'),
          _buildSignItem('⏳', 'Lasting 1 minute each'),
          _buildSignItem('🕐', 'For 1 hour consistently'),
          _buildSignItem('💧', 'Water breaks'),
          _buildSignItem('🩸', 'Heavy bleeding'),
          _buildSignItem('👶', 'Baby\'s movements decrease'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.dangerRed.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppTheme.dangerRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Call your healthcare provider immediately if you have concerns',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.dangerRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _startContraction() {
    setState(() {
      _isTimerRunning = true;
      _contractionStartTime = DateTime.now();
      _currentDuration = 0;
      _selectedIntensity = 0;
    });
    
    ref.read(ct_providers.contractionTimerProvider.notifier).startContraction();
    _pulseController.repeat(reverse: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDuration++;
        });
      }
    });
  }

  void _stopContraction() {
    if (!_isTimerRunning || _contractionStartTime == null) return;

    setState(() {
      _isTimerRunning = false;
      _timer?.cancel();
      
      final duration = DateTime.now().difference(_contractionStartTime!).inMilliseconds;
      
      _contractionStartTime = null;
      _currentDuration = 0;
    });
    
    ref.read(ct_providers.contractionTimerProvider.notifier).stopContraction();
    _pulseController.stop();
    _pulseController.reset();
  }

  void _resetSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Session?'),
        content: const Text('This will clear all recorded contractions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isTimerRunning = false;
                _timer?.cancel();
                _contractionStartTime = null;
                _currentDuration = 0;
                _selectedIntensity = 0;
              });
              ref.read(ct_providers.contractionTimerProvider.notifier).clearContractions();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _selectIntensity(int intensity) {
    setState(() {
      _selectedIntensity = intensity;
    });
    ref.read(ct_providers.contractionTimerProvider.notifier).setIntensity(intensity);
  }

  Future<void> _analyzeContractions() async {
    final contractionState = ref.read(ct_providers.contractionTimerProvider);
    final contractions = contractionState.contractions;
    
    if (contractions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contractions to analyze')),
      );
      return;
    }

    try {
      final contractionsData = contractions.map((c) => {
        'startTime': c['startTime'],
        'duration': c['endTime'] != null && c['startTime'] != null
            ? DateTime.parse(c['endTime']).difference(DateTime.parse(c['startTime'])).inMilliseconds
            : 0,
        'intensity': c['intensity'] ?? 0,
      }).toList();

      // Use streaming API
      final apiService = ref.read(core_providers.apiServiceProvider);
      final stream = apiService.contractionAnalyzeStream(contractionsData);

      if (mounted) {
        // Navigate to streaming result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamingAIResultScreen(
              title: 'Contraction Analysis',
              responseStream: stream,
              icon: Icons.analytics,
              color: AppTheme.primaryPurple,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing contractions: $e')),
        );
      }
    }
  }

  void _showContractionHistory() {
    // Show full history
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryPurple),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'How to Use Contraction Timer',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track your contractions to know when it\'s time to go to the hospital.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                '📝 How to Use:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('1. Tap "Start" when a contraction begins'),
              Text('2. Tap "Stop" when it ends'),
              Text('3. Rate the intensity (1-5)'),
              Text('4. Repeat for each contraction'),
              Text('5. Click "Analyze" to see patterns'),
              SizedBox(height: 16),
              Text(
                '⚠️ When to Go to Hospital:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.dangerRed),
              ),
              SizedBox(height: 8),
              Text('• Contractions 5 minutes apart'),
              Text('• Lasting 60 seconds each'),
              Text('• For at least 1 hour'),
              Text('• Or as advised by your doctor'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareContractionData() async {
    try {
      final contractionState = ref.read(ct_providers.contractionTimerProvider);
      
      if (contractionState.contractions.isEmpty) {
        // No data yet - share invitation to use the tool
        await ShareHelper.shareToolOutput(
          toolName: 'Contraction Timer',
          catchyHook: '⏱️ Track your labor contractions with SafeMama!',
        );
        return;
      }

      // Calculate average interval
      String averageInterval = 'N/A';
      if (contractionState.contractions.length >= 2) {
        final intervals = <Duration>[];
        for (int i = 1; i < contractionState.contractions.length; i++) {
          final current = contractionState.contractions[i];
          final previous = contractionState.contractions[i - 1];
          final currentStart = current['startTime'];
          final previousStart = previous['startTime'];
          if (currentStart != null && previousStart != null) {
            final currentTime = DateTime.parse(currentStart as String);
            final previousTime = DateTime.parse(previousStart as String);
            intervals.add(currentTime.difference(previousTime));
          }
        }
        if (intervals.isNotEmpty) {
          final avgSeconds = intervals.map((d) => d.inSeconds).reduce((a, b) => a + b) ~/ intervals.length;
          final minutes = avgSeconds ~/ 60;
          final seconds = avgSeconds % 60;
          averageInterval = '${minutes}m ${seconds}s';
        }
      }

      await ShareHelper.shareContractionTimer(
        contractionsCount: contractionState.contractions.length,
        averageInterval: averageInterval,
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

  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 1:
        return AppTheme.safeGreen;
      case 2:
        return AppTheme.accentColor;
      case 3:
        return AppTheme.warningOrange;
      case 4:
      case 5:
        return AppTheme.dangerRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}