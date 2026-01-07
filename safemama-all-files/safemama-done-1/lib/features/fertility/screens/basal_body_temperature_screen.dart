import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/theme/app_theme.dart';

class BasalBodyTemperatureScreen extends ConsumerStatefulWidget {
  const BasalBodyTemperatureScreen({super.key});

  @override
  ConsumerState<BasalBodyTemperatureScreen> createState() => _BasalBodyTemperatureScreenState();
}

class _BasalBodyTemperatureScreenState extends ConsumerState<BasalBodyTemperatureScreen> {
  final TextEditingController _temperatureController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedUnit = 'Celsius';
  String notes = '';
  
  // Sample data - replace with actual provider data
  final List<Map<String, dynamic>> temperatureData = [
    {'date': DateTime.now().subtract(const Duration(days: 6)), 'temperature': 36.4},
    {'date': DateTime.now().subtract(const Duration(days: 5)), 'temperature': 36.5},
    {'date': DateTime.now().subtract(const Duration(days: 4)), 'temperature': 36.3},
    {'date': DateTime.now().subtract(const Duration(days: 3)), 'temperature': 36.6},
    {'date': DateTime.now().subtract(const Duration(days: 2)), 'temperature': 36.8},
    {'date': DateTime.now().subtract(const Duration(days: 1)), 'temperature': 37.0},
  ];

  @override
  void dispose() {
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Basal Body Temperature'),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.dangerRed.withOpacity(0.1),
                    AppTheme.warningOrange.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.dangerRed.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thermostat, color: AppTheme.dangerRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Track Your Morning Temperature',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Take your temperature first thing in the morning before getting out of bed. Track daily to identify fertility patterns.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Temperature Chart
            _buildTemperatureChart(),

            const SizedBox(height: 24),

            // Log Temperature Form
            _buildLogTemperatureForm(),

            const SizedBox(height: 24),

            // Recent Entries
            _buildRecentEntries(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature Trend (Last 7 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Simple temperature visualization with cards
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: temperatureData.asMap().entries.map((entry) {
                final temp = entry.value['temperature'] as double;
                final date = entry.value['date'] as DateTime;
                final barHeight = ((temp - 36.0) / 2.0) * 180; // Scale to 180px max height
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$temp°',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.dangerRed,
                                AppTheme.dangerRed.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTemperatureForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Temperature',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Temperature Input
          TextField(
            controller: _temperatureController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Temperature',
              hintText: '36.5',
              suffixText: selectedUnit == 'Celsius' ? '°C' : '°F',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Unit Toggle
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => selectedUnit = 'Celsius'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedUnit == 'Celsius' 
                        ? AppTheme.dangerRed.withOpacity(0.1)
                        : Colors.transparent,
                    foregroundColor: AppTheme.dangerRed,
                    side: BorderSide(color: AppTheme.dangerRed),
                  ),
                  child: const Text('Celsius (°C)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => selectedUnit = 'Fahrenheit'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedUnit == 'Fahrenheit' 
                        ? AppTheme.dangerRed.withOpacity(0.1)
                        : Colors.transparent,
                    foregroundColor: AppTheme.dangerRed,
                    side: BorderSide(color: AppTheme.dangerRed),
                  ),
                  child: const Text('Fahrenheit (°F)'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectTime(context),
                  icon: const Icon(Icons.access_time),
                  label: Text(selectedTime.format(context)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notes
          TextField(
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Add any relevant notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
            onChanged: (value) => notes = value,
          ),

          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTemperature,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Temperature'),
            ),
          ),
        ],
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
          itemCount: temperatureData.take(5).length,
          itemBuilder: (context, index) {
            final entry = temperatureData[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.thermostat, color: AppTheme.dangerRed),
                ),
                title: Text(
                  '${entry['temperature']}°C',
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  void _saveTemperature() {
    if (_temperatureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a temperature')),
      );
      return;
    }

    // Add save logic here - save to provider/database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Temperature saved successfully!')),
    );
    
    _temperatureController.clear();
  }

  void _deleteEntry(int index) {
    // Add delete logic here
    setState(() => temperatureData.removeAt(index));
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.dangerRed),
            const SizedBox(width: 12),
            const Text('How to Track BBT'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basal Body Temperature tracking helps identify ovulation and fertility patterns.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoItem('1️⃣', 'Take your temperature first thing in the morning, before getting out of bed or doing any activity.'),
              const SizedBox(height: 12),
              _buildInfoItem('2️⃣', 'Use a basal thermometer for more accurate readings.'),
              const SizedBox(height: 12),
              _buildInfoItem('3️⃣', 'Track consistently at the same time each day for best results.'),
              const SizedBox(height: 12),
              _buildInfoItem('4️⃣', 'Your temperature typically rises slightly (0.5-1°F) after ovulation.'),
              const SizedBox(height: 12),
              _buildInfoItem('📊', 'Review the 7-day trend chart to identify patterns and fertile windows.'),
              const SizedBox(height: 12),
              _buildInfoItem('💡', 'BBT tracking is most effective when combined with cervical mucus observation.'),
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

