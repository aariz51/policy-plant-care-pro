import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/models/ttc_tracker.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/utils/share_helper.dart';
import 'package:safemama/features/fertility/providers/ttc_providers.dart';
import 'package:safemama/features/fertility/screens/basal_body_temperature_screen.dart';
import 'package:safemama/features/fertility/screens/cervical_mucus_screen.dart';
import 'package:safemama/features/fertility/screens/symptoms_mood_screen.dart';
import 'package:table_calendar/table_calendar.dart';

class TtcTrackerScreen extends ConsumerStatefulWidget {
  const TtcTrackerScreen({super.key});

  @override
  ConsumerState<TtcTrackerScreen> createState() => _TtcTrackerScreenState();
}

class _TtcTrackerScreenState extends ConsumerState<TtcTrackerScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? selectedLMP;
  int cycleLength = 28;
  TtcTracker? currentCycle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttcTrackerProvider.notifier).loadTtcData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('TTC Tracker'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareTtcData,
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
            tabs: const [
              Tab(text: 'Cycle', icon: Icon(Icons.event_available)),
              Tab(text: 'Fertility', icon: Icon(Icons.favorite)),
              Tab(text: 'Calendar', icon: Icon(Icons.calendar_month)),
            ],
            indicatorColor: AppTheme.primaryPurple,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCycleTab(),
            _buildFertilityTab(),
            _buildCalendarTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDataDialog,
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Log Data'),
        ),
    );
  }

  Widget _buildCycleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Cycle Card
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.track_changes,
                        color: AppTheme.primaryPurple,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Cycle',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Track your fertility journey',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // LMP Selection
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _selectLMP,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: AppTheme.primaryPurple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Menstrual Period',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  selectedLMP != null
                                      ? DateFormat.yMMMMd().format(selectedLMP!)
                                      : 'Tap to select date',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
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

                // Cycle Length Selector
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.loop,
                          color: AppTheme.primaryPurple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cycle Length',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$cycleLength days (average)',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                if (cycleLength > 21) {
                                  setState(() => cycleLength--);
                                  _calculateCycle();
                                }
                              },
                              icon: const Icon(Icons.remove),
                              iconSize: 20,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$cycleLength',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (cycleLength < 45) {
                                  setState(() => cycleLength++);
                                  _calculateCycle();
                                }
                              },
                              icon: const Icon(Icons.add),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (currentCycle != null) ...[
                  const SizedBox(height: 24),
                  _buildCycleResults(),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TTC Tips',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTipItem('💊', 'Take folic acid supplements (400mcg daily)'),
                _buildTipItem('🥗', 'Maintain a healthy, balanced diet'),
                _buildTipItem('🏃‍♀️', 'Exercise regularly but avoid overexertion'),
                _buildTipItem('😴', 'Get adequate sleep (7-8 hours)'),
                _buildTipItem('🚭', 'Avoid smoking, alcohol, and excessive caffeine'),
                _buildTipItem('📱', 'Track your cycle consistently'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleResults() {
    if (currentCycle == null) return const SizedBox.shrink();

    final today = DateTime.now();
    final ovulationDate = currentCycle!.estimatedOvulation!;
    final fertileStart = currentCycle!.fertileWindowStart!;
    final fertileEnd = currentCycle!.fertileWindowEnd!;
    
    final daysToOvulation = ovulationDate.difference(today).inDays;
    final isInFertileWindow = today.isAfter(fertileStart.subtract(const Duration(days: 1))) && 
                              today.isBefore(fertileEnd.add(const Duration(days: 1)));

    return Column(
      children: [
        // Ovulation Countdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isInFertileWindow 
                ? AppTheme.safeGreen.withOpacity(0.1)
                : AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isInFertileWindow 
                  ? AppTheme.safeGreen.withOpacity(0.3)
                  : AppTheme.primaryPurple.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                isInFertileWindow ? '🌟 Fertile Window!' : '📅 Next Ovulation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isInFertileWindow 
                    ? 'This is your peak fertility period!'
                    : daysToOvulation > 0 
                        ? 'In $daysToOvulation days (${DateFormat.MMMd().format(ovulationDate)})'
                        : daysToOvulation == 0
                            ? 'Today!'
                            : '${daysToOvulation.abs()} days ago',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Fertile Window
        Row(
          children: [
            Expanded(
              child: _buildDateCard(
                title: 'Fertile Window Start',
                date: fertileStart,
                icon: Icons.play_arrow,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateCard(
                title: 'Fertile Window End',
                date: fertileEnd,
                icon: Icons.stop,
                color: AppTheme.warningOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required String title,
    required DateTime date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            DateFormat.MMMd().format(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
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
              children: [
                Icon(
                  Icons.favorite,
                  size: 48,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(height: 12),
                Text(
                  'Track Your Fertility Signs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Perfect timing for conception',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Fertility Tracking Cards
          _buildFertilityCard(
            icon: Icons.thermostat,
            title: 'Basal Body Temperature',
            subtitle: 'Track your morning temperature',
            color: AppTheme.dangerRed,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BasalBodyTemperatureScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _buildFertilityCard(
            icon: Icons.water_drop,
            title: 'Cervical Mucus',
            subtitle: 'Monitor changes in cervical fluid',
            color: AppTheme.accentColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CervicalMucusScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _buildFertilityCard(
            icon: Icons.psychology,
            title: 'Symptoms & Mood',
            subtitle: 'Log daily symptoms and feelings',
            color: AppTheme.primaryPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SymptomsMoodScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFertilityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Calendar
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: selectedLMP ?? DateTime.now(),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppTheme.safeGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: (day) {
                  return isSameDay(selectedLMP, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    selectedLMP = selectedDay;
                    _calculateCycle();
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    // Mark fertile window, ovulation, period days
                    if (currentCycle != null) {
                      final fertileStart = currentCycle!.fertileWindowStart;
                      final fertileEnd = currentCycle!.fertileWindowEnd;
                      final ovulation = currentCycle!.estimatedOvulation;
                      final periodEnd = selectedLMP?.add(const Duration(days: 5));

                      if (ovulation != null && isSameDay(date, ovulation)) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.safeGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '●',
                              style: TextStyle(color: Colors.white, fontSize: 8),
                            ),
                          ),
                        );
                      }

                      if (fertileStart != null && fertileEnd != null) {
                        if (date.isAfter(fertileStart.subtract(const Duration(days: 1))) &&
                            date.isBefore(fertileEnd.add(const Duration(days: 1)))) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '●',
                                style: TextStyle(color: Colors.white, fontSize: 8),
                              ),
                            ),
                          );
                        }
                      }

                      if (selectedLMP != null && periodEnd != null) {
                        if (date.isAfter(selectedLMP!.subtract(const Duration(days: 1))) &&
                            date.isBefore(periodEnd.add(const Duration(days: 1)))) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '●',
                                style: TextStyle(color: Colors.white, fontSize: 8),
                              ),
                            ),
                          );
                        }
                      }
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendar Legend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLegendItem(AppTheme.dangerRed, 'Period Days'),
                _buildLegendItem(AppTheme.accentColor, 'Fertile Window'),
                _buildLegendItem(AppTheme.safeGreen, 'Ovulation Day'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
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

  Future<void> _selectLMP() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedLMP ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'SELECT LAST MENSTRUAL PERIOD',
    );

    if (picked != null && picked != selectedLMP) {
      setState(() {
        selectedLMP = picked;
      });
      _calculateCycle();
    }
  }

  void _calculateCycle() {
    if (selectedLMP != null) {
      setState(() {
        currentCycle = TtcTracker.calculateFertileWindow(
          userId: 'current_user', // Replace with actual user ID
          lmp: selectedLMP!,
          cycleLength: cycleLength,
        );
      });
    }
  }

  void _showAddDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Daily Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Cycle & Fertility'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(0); // Switch to Cycle tab
                },
              ),
              ListTile(
                leading: const Icon(Icons.thermostat),
                title: const Text('Basal Body Temperature'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BasalBodyTemperatureScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.water_drop),
                title: const Text('Cervical Mucus'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CervicalMucusScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.mood),
                title: const Text('Symptoms & Mood'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SymptomsMoodScreen(),
                    ),
                  );
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
        ],
      ),
    );
  }

  void _shareTtcData() async {
    if (currentCycle == null || selectedLMP == null) {
      await ShareHelper.shareToolOutput(
        toolName: 'TTC Tracker',
        catchyHook: '💕 Track your fertility journey with SafeMama!',
      );
      return;
    }

    final today = DateTime.now();
    final cycleDay = today.difference(selectedLMP!).inDays + 1;
    
    // Determine fertility status
    final ovulationDate = currentCycle!.estimatedOvulation!;
    final fertileStart = currentCycle!.fertileWindowStart!;
    final fertileEnd = currentCycle!.fertileWindowEnd!;
    
    String fertilityStatus;
    if (today.isAfter(fertileStart.subtract(const Duration(days: 1))) && 
        today.isBefore(fertileEnd.add(const Duration(days: 1)))) {
      fertilityStatus = 'Fertile Window 🌟';
    } else if (today.difference(ovulationDate).inDays.abs() <= 1) {
      fertilityStatus = 'Ovulation Day 💫';
    } else {
      final daysToOvulation = ovulationDate.difference(today).inDays;
      if (daysToOvulation > 0) {
        fertilityStatus = '$daysToOvulation days to ovulation';
      } else {
        fertilityStatus = 'Past ovulation';
      }
    }

    await ShareHelper.shareTTCTracker(
      cycleDay: cycleDay,
      fertilityStatus: fertilityStatus,
      cyclesTracked: 1, // Could be enhanced to track actual cycles count
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
                'How to Use TTC Tracker',
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
                  'Track your fertility cycle to identify your most fertile days and optimize your chances of conception.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoItem('1️⃣', 'Enter your Last Menstrual Period (LMP) date and cycle length.'),
                const SizedBox(height: 12),
                _buildInfoItem('2️⃣', 'Track your cycle, fertility window, and ovulation dates.'),
                const SizedBox(height: 12),
                _buildInfoItem('3️⃣', 'Log daily data including basal body temperature, cervical mucus, and symptoms.'),
                const SizedBox(height: 12),
                _buildInfoItem('4️⃣', 'View your fertility calendar to see your most fertile days.'),
                const SizedBox(height: 12),
                _buildInfoItem('💡', 'The fertile window is typically 5-6 days before ovulation.'),
                const SizedBox(height: 12),
                _buildInfoItem('⚠️', 'This tracker is for informational purposes. Consult your healthcare provider for fertility guidance.'),
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
