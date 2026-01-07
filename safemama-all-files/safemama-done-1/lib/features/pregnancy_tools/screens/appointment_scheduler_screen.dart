import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/pregnancy_tools/providers/appointment_scheduler_providers.dart';
import 'package:safemama/core/widgets/custom_button.dart';

class AppointmentSchedulerScreen extends ConsumerStatefulWidget {
  const AppointmentSchedulerScreen({super.key});

  @override
  ConsumerState<AppointmentSchedulerScreen> createState() => _AppointmentSchedulerScreenState();
}

class _AppointmentSchedulerScreenState extends ConsumerState<AppointmentSchedulerScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentSchedulerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAppointmentDialog(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(appointmentSchedulerProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(state),
                    const SizedBox(height: 24),
                    _buildUpcomingAppointments(state),
                    const SizedBox(height: 24),
                    _buildPastAppointments(state),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAppointmentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCards(AppointmentSchedulerState state) {
    final stats = ref.read(appointmentSchedulerProvider.notifier).getAppointmentStats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Upcoming',
                '${stats['upcomingCount'] ?? 0}',
                Icons.schedule,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '${stats['completedCount'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Month',
                '${stats['thisMonthCount'] ?? 0}',
                Icons.calendar_month,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total',
                '${stats['totalCount'] ?? 0}',
                Icons.event,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments(AppointmentSchedulerState state) {
    final upcomingAppointments = state.upcomingAppointments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Appointments',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (upcomingAppointments.isEmpty)
          _buildEmptyState(
            'No upcoming appointments',
            'Schedule your next prenatal checkup',
            Icons.schedule,
          )
        else
          ...upcomingAppointments.map((appointment) => 
            _buildAppointmentCard(appointment, true)),
      ],
    );
  }

  Widget _buildPastAppointments(AppointmentSchedulerState state) {
    final now = DateTime.now();
    final pastAppointments = state.appointments
        .where((apt) {
          final dateTime = DateTime.parse(apt['dateTime']);
          return dateTime.isBefore(now) || apt['status'] == 'completed' || apt['status'] == 'cancelled';
        })
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a['dateTime']);
        final dateB = DateTime.parse(b['dateTime']);
        return dateB.compareTo(dateA); // Most recent first
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Past Appointments',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (pastAppointments.isEmpty)
          _buildEmptyState(
            'No past appointments',
            'Your completed appointments will appear here',
            Icons.history,
          )
        else
          ...pastAppointments.take(5).map((appointment) => 
            _buildAppointmentCard(appointment, false)),
        if (pastAppointments.length > 5)
          TextButton(
            onPressed: () {
              // Navigate to full history
            },
            child: const Text('View All Past Appointments'),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, bool isUpcoming) {
    final DateTime appointmentDateTime = DateTime.parse(appointment['appointment_datetime']);
    final bool isToday = _isToday(appointmentDateTime);
    final bool isTomorrow = _isTomorrow(appointmentDateTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUpcoming 
              ? (isToday ? Colors.red : Colors.blue) 
              : Colors.grey,
          child: Icon(
            _getAppointmentIcon(appointment['type']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          appointment['title'] ?? 'Appointment',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. ${appointment['doctor_name']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(_formatAppointmentDateTime(appointmentDateTime)),
            if (appointment['location'] != null)
              Text(appointment['location']),
            if (isToday)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isTomorrow)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tomorrow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: isUpcoming 
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleAppointmentAction(appointment, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
                  const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : PopupMenuButton<String>(
                onSelected: (value) => _handleAppointmentAction(appointment, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
        onTap: () => _showAppointmentDetails(appointment),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  IconData _getAppointmentIcon(String? type) {
    switch (type) {
      case 'prenatal_checkup':
        return Icons.favorite;
      case 'ultrasound':
        return Icons.monitor;
      case 'lab_work':
        return Icons.science;
      case 'specialist':
        return Icons.local_hospital;
      case 'dental':
        return Icons.medication;
      case 'vaccination':
        return Icons.vaccines;
      default:
        return Icons.medical_services;
    }
  }

  String _formatAppointmentDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference == -1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else {
      return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : 
                 (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year && 
           dateTime.month == now.month && 
           dateTime.day == now.day;
  }

  bool _isTomorrow(DateTime dateTime) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year && 
           dateTime.month == tomorrow.month && 
           dateTime.day == tomorrow.day;
  }

  void _showAddAppointmentDialog() {
    _showAppointmentForm();
  }

  void _showAppointmentForm({Map<String, dynamic>? appointment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentFormSheet(appointment: appointment),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AppointmentDetailsSheet(appointment: appointment),
    );
  }

  void _handleAppointmentAction(Map<String, dynamic> appointment, String action) {
    final notifier = ref.read(appointmentSchedulerProvider.notifier);
    
    switch (action) {
      case 'edit':
        _showAppointmentForm(appointment: appointment);
        break;
      case 'complete':
        notifier.markAppointmentCompleted(appointment['id']);
        break;
      case 'cancel':
        notifier.cancelAppointment(appointment['id']);
        break;
      case 'delete':
        _showDeleteConfirmation(appointment);
        break;
      case 'view':
        _showAppointmentDetails(appointment);
        break;
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to delete "${appointment['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(appointmentSchedulerProvider.notifier)
                 .deleteAppointment(appointment['appointment_id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AppointmentFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? appointment;

  const _AppointmentFormSheet({this.appointment});

  @override
  ConsumerState<_AppointmentFormSheet> createState() => _AppointmentFormSheetState();
}

class _AppointmentFormSheetState extends ConsumerState<_AppointmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'prenatal_checkup';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  
  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _titleController.text = widget.appointment!['title'] ?? '';
      _doctorController.text = widget.appointment!['doctor_name'] ?? '';
      _locationController.text = widget.appointment!['location'] ?? '';
      _notesController.text = widget.appointment!['notes'] ?? '';
      _selectedType = widget.appointment!['type'] ?? 'prenatal_checkup';
      _selectedDateTime = DateTime.parse(widget.appointment!['appointment_datetime']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.appointment != null ? 'Edit Appointment' : 'New Appointment',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Appointment Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Appointment Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'prenatal_checkup', child: Text('Prenatal Checkup')),
                      DropdownMenuItem(value: 'ultrasound', child: Text('Ultrasound')),
                      DropdownMenuItem(value: 'lab_work', child: Text('Lab Work')),
                      DropdownMenuItem(value: 'specialist', child: Text('Specialist')),
                      DropdownMenuItem(value: 'dental', child: Text('Dental')),
                      DropdownMenuItem(value: 'vaccination', child: Text('Vaccination')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _doctorController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor/Provider Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDateTimeSelector(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  CustomElevatedButton(
                    onPressed: _saveAppointment,
                    text: widget.appointment != null ? 'Update Appointment' : 'Schedule Appointment',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Appointment Date & Time', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_formatDate(_selectedDateTime)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(_selectedDateTime)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : 
                 (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _saveAppointment() {
    if (_formKey.currentState?.validate() != true) return;

    final notifier = ref.read(appointmentSchedulerProvider.notifier);
    
    if (widget.appointment != null) {
      // Update existing appointment
      notifier.updateAppointment(
        appointmentId: widget.appointment!['id'],
        title: _titleController.text,
        type: _selectedType,
        dateTime: _selectedDateTime,
        doctorName: _doctorController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    } else {
      // Create new appointment
      notifier.scheduleAppointment(
        title: _titleController.text,
        type: _selectedType,
        dateTime: _selectedDateTime,
        doctorName: _doctorController.text,
        location: _locationController.text.isEmpty ? 'Not specified' : _locationController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }
    
    Navigator.of(context).pop();
  }
}

class _AppointmentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const _AppointmentDetailsSheet({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final DateTime appointmentDateTime = DateTime.parse(appointment['appointment_datetime']);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Title', appointment['title'] ?? 'N/A'),
                _buildDetailRow('Doctor', 'Dr. ${appointment['doctor_name']}'),
                _buildDetailRow('Type', _getTypeDisplayName(appointment['type'])),
                _buildDetailRow('Date & Time', _formatAppointmentDateTime(appointmentDateTime)),
                if (appointment['location'] != null)
                  _buildDetailRow('Location', appointment['location']),
                if (appointment['notes'] != null && appointment['notes'].isNotEmpty)
                  _buildDetailRow('Notes', appointment['notes']),
                _buildDetailRow('Status', _getStatusDisplayName(appointment['status'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(String? type) {
    switch (type) {
      case 'prenatal_checkup':
        return 'Prenatal Checkup';
      case 'ultrasound':
        return 'Ultrasound';
      case 'lab_work':
        return 'Lab Work';
      case 'specialist':
        return 'Specialist';
      case 'dental':
        return 'Dental';
      case 'vaccination':
        return 'Vaccination';
      default:
        return 'Other';
    }
  }

  String _getStatusDisplayName(String? status) {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return 'Unknown';
    }
  }

  String _formatAppointmentDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference == -1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else {
      return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : 
                 (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
