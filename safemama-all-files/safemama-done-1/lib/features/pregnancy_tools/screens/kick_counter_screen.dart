import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/features/pregnancy_tools/providers/kick_counter_providers.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/utils/share_helper.dart';

class KickCounterScreen extends ConsumerStatefulWidget {
  const KickCounterScreen({super.key});

  @override
  ConsumerState<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends ConsumerState<KickCounterScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    
    // Start a periodic timer to update the UI every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kickCountState = ref.watch(kickCounterProvider);
    final isCountingSession = kickCountState.currentSession != null;
    
    return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Kick Counter'),
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
              onPressed: () => _showKickHistory(),
              icon: const Icon(Icons.history),
            ),
            IconButton(
              onPressed: _shareKickData,
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
                      AppTheme.safeGreen.withOpacity(0.1),
                      AppTheme.accentColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.safeGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.baby_changing_station,
                      size: 48,
                      color: AppTheme.safeGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Baby Kick Counter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCountingSession
                          ? 'Tap the button every time you feel a kick'
                          : 'Start a new session to track baby\'s movements',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (isCountingSession) ...[
                // Active Session
                _buildActiveSession(kickCountState.currentSession!),
              ] else ...[
                // Start Session
                _buildStartSession(),
              ],

              const SizedBox(height: 32),

              // Information Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
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
                          color: AppTheme.primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kick Counting Tips',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTipItem('⏰', 'Count at the same time each day'),
                    _buildTipItem('🍎', 'Do this after eating or drinking something sweet'),
                    _buildTipItem('🛏️', 'Lie on your side in a quiet place'),
                    _buildTipItem('👶', 'Look for 10 movements in 2 hours'),
                    _buildTipItem('👩‍⚕️', 'Contact your doctor if patterns change'),
                  ],
                ),
              ),

              if (kickCountState.recentSessions.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildRecentSessions(kickCountState.recentSessions),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildActiveSession(Map<String, dynamic> session) {
    final startTimeStr = session['startTime'];
    if (startTimeStr == null || startTimeStr is! String) {
      return const SizedBox.shrink();
    }
    final startTime = DateTime.parse(startTimeStr);
    final isActive = session['isActive'] as bool? ?? true;
    final totalPauseDuration = session['totalPauseDuration'] as int? ?? 0;
    final kickCount = (session['kicks'] as List? ?? []).length;
    
    // Calculate actual duration excluding pause time
    Duration duration;
    if (isActive) {
      // Session is running
      duration = DateTime.now().difference(startTime) - Duration(milliseconds: totalPauseDuration);
    } else {
      // Session is paused
      final pausedAtStr = session['pausedAt'];
      if (pausedAtStr == null || pausedAtStr is! String) {
        // If pausedAt is null, treat as active
        duration = DateTime.now().difference(startTime) - Duration(milliseconds: totalPauseDuration);
      } else {
        final pausedAt = DateTime.parse(pausedAtStr);
        duration = pausedAt.difference(startTime) - Duration(milliseconds: totalPauseDuration);
      }
    }
    
    return Column(
      children: [
        // Session Stats
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.safeGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kicks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '$kickCount',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.safeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isActive 
                      ? AppTheme.accentColor.withOpacity(0.1)
                      : AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive 
                        ? AppTheme.accentColor.withOpacity(0.3)
                        : AppTheme.warningOrange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isActive ? 'Time' : 'Paused',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppTheme.accentColor : AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Kick Button
        Center(
          child: GestureDetector(
            onTap: _recordKick,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple Effect
                      AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 200 + (100 * _rippleAnimation.value),
                            height: 200 + (100 * _rippleAnimation.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.safeGreen.withOpacity(0.3 * (1 - _rippleAnimation.value)),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      // Main Button
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.safeGreen,
                              AppTheme.safeGreen.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.safeGreen.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'KICK!',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

        // Control Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _pauseSession,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: isActive ? AppTheme.warningOrange : AppTheme.safeGreen,
                  side: BorderSide(
                    color: isActive ? AppTheme.warningOrange : AppTheme.safeGreen,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(isActive ? 'Pause' : 'Resume'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _endSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop, size: 20),
                          SizedBox(width: 8),
                          Text('End Session'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartSession() {
    return Column(
      children: [
        // Big Start Button
        Center(
          child: GestureDetector(
            onTap: _startSession,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple,
                    AppTheme.accentColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'START\nSESSION',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Tap to begin tracking your baby\'s movements',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentSessions(List<Map<String, dynamic>> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.take(3).length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _buildSessionCard(session);
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final startTimeStr = session['startTime'];
    if (startTimeStr == null || startTimeStr is! String) {
      return const SizedBox.shrink();
    }
    final startTime = DateTime.parse(startTimeStr);
    final endTimeStr = session['endTime'];
    if (endTimeStr == null || endTimeStr is! String) {
      return const SizedBox.shrink(); // Skip if no end time
    }
    final endTime = DateTime.parse(endTimeStr);
    final kickCount = (session['kicks'] as List? ?? []).length;
    final duration = endTime.difference(startTime);

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.baby_changing_station,
                color: AppTheme.safeGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$kickCount kicks in ${_formatDuration(duration)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().add_jm().format(startTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (kickCount >= 10)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Good',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.safeGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _startSession() {
    ref.read(kickCounterProvider.notifier).startSession();
  }

  void _recordKick() {
    ref.read(kickCounterProvider.notifier).recordKick();
    _pulseController.forward().then((_) => _pulseController.reverse());
    _rippleController.forward().then((_) => _rippleController.reset());
  }

  void _pauseSession() {
    ref.read(kickCounterProvider.notifier).pauseSession();
  }

  Future<void> _endSession() async {
    final kickCountState = ref.read(kickCounterProvider);
    final currentSession = kickCountState.currentSession;
    
    if (currentSession == null) return;
    
    final kickCount = (currentSession['kicks'] as List? ?? []).length;
    
    if (kickCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No kicks recorded yet')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final startTimeStr = currentSession['startTime'];
      final startTime = DateTime.parse(startTimeStr);
      final sessionDuration = DateTime.now().difference(startTime).inMilliseconds;
      
      // Get current pregnancy week from user profile or set default
      final currentWeek = 28; // You may want to get this from user profile
      
      final response = await ref.read(apiServiceProvider).post(
        '/api/pregnancy-tools/kick-counter',
        {
          'kickCount': kickCount,
          'sessionDuration': sessionDuration,
          'pregnancyWeek': currentWeek,
        },
      );

      if (response['success'] == true) {
        // End session in provider
        await ref.read(kickCounterProvider.notifier).endSession();
        
        // Show results dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Session Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Kicks: ${response['data']['kickCount']}'),
                  Text('Duration: ${response['data']['sessionMinutes']} min'),
                  Text('Kicks/Hour: ${response['data']['kicksPerHour']}'),
                  const SizedBox(height: 12),
                  Text(
                    response['data']['guidance'] ?? '',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // If API call fails, still end the session locally
      await ref.read(kickCounterProvider.notifier).endSession();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session saved locally. Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showKickHistory() {
    final kickCountState = ref.read(kickCounterProvider);
    if (kickCountState.recentSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions recorded yet')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick Counter History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: kickCountState.recentSessions.length,
            itemBuilder: (context, index) {
              final session = kickCountState.recentSessions[index];
              return _buildSessionCard(session);
            },
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _shareKickData() async {
    try {
      final kickCountState = ref.read(kickCounterProvider);
      
      if (kickCountState.recentSessions.isEmpty) {
        // No data - share invitation
        await ShareHelper.shareToolOutput(
          toolName: 'Kick Counter',
          catchyHook: '👶 Track your baby\'s movements with SafeMama!',
        );
        return;
      }

      // Get current or last session data
      final session = kickCountState.currentSession ?? kickCountState.recentSessions.first;
      final kicksCount = session['kickCount'] as int? ?? 0;
      final startTime = DateTime.parse(session['startTime'] as String);
      final endTime = session['endTime'] != null 
          ? DateTime.parse(session['endTime'] as String)
          : DateTime.now();
      final duration = endTime.difference(startTime);
      final durationText = '${duration.inMinutes} min ${duration.inSeconds % 60} sec';

      await ShareHelper.shareKickCounter(
        kicksCount: kicksCount,
        duration: durationText,
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.safeGreen),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'How to Use Kick Counter',
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
                  'Track your baby\'s movements to monitor fetal well-being during pregnancy.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoItem('1️⃣', 'Start a session when you begin counting kicks.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'Tap the green KICK! button every time you feel a movement.'),
                const SizedBox(height: 12),
                _buildInfoItem('3️⃣', 'Pause if you need a break and resume when ready.'),
                const SizedBox(height: 12),
                _buildInfoItem('4️⃣', 'End the session to save your kick count and duration.'),
                const SizedBox(height: 12),
                _buildInfoItem('💡', 'Recommended: Count kicks when baby is most active (after meals or when lying down).'),
                const SizedBox(height: 12),
                _buildInfoItem('⚠️', 'If you notice a decrease in movements, contact your healthcare provider immediately.'),
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
