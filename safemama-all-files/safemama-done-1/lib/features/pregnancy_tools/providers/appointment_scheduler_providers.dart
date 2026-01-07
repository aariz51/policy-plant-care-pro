import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/appointment_scheduler_service.dart';

class AppointmentSchedulerState {
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> upcomingAppointments;
  final Map<String, dynamic>? selectedAppointment;
  final bool isLoading;
  final String? error;

  const AppointmentSchedulerState({
    this.appointments = const [],
    this.upcomingAppointments = const [],
    this.selectedAppointment,
    this.isLoading = false,
    this.error,
  });

  AppointmentSchedulerState copyWith({
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? upcomingAppointments,
    Map<String, dynamic>? selectedAppointment,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentSchedulerState(
      appointments: appointments ?? this.appointments,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      selectedAppointment: selectedAppointment ?? this.selectedAppointment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AppointmentSchedulerNotifier extends StateNotifier<AppointmentSchedulerState> {
  final AppointmentSchedulerService _service;

  AppointmentSchedulerNotifier(this._service) : super(const AppointmentSchedulerState()) {
    _loadAppointments();
  }

  Future<void> scheduleAppointment({
    required String title,
    required String type,
    required DateTime dateTime,
    required String doctorName,
    required String location,
    String? notes,
    Map<String, dynamic>? reminderSettings,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final appointment = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'type': type,
        'dateTime': dateTime.toIso8601String(),
        'doctorName': doctorName,
        'location': location,
        'notes': notes ?? '',
        'reminderSettings': reminderSettings ?? {
          'enabled': true,
          'reminderTimes': [24, 2], // 24 hours and 2 hours before
        },
        'status': 'scheduled',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _service.scheduleAppointment(appointment);
      
      final updatedAppointments = [appointment, ...state.appointments];
      _updateUpcomingAppointments(updatedAppointments);
      
      state = state.copyWith(
        appointments: updatedAppointments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateAppointment({
    required String appointmentId,
    String? title,
    String? type,
    DateTime? dateTime,
    String? doctorName,
    String? location,
    String? notes,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final updatedAppointments = state.appointments.map((appointment) {
        if (appointment['id'] == appointmentId) {
          final updated = Map<String, dynamic>.from(appointment);
          if (title != null) updated['title'] = title;
          if (type != null) updated['type'] = type;
          if (dateTime != null) updated['dateTime'] = dateTime.toIso8601String();
          if (doctorName != null) updated['doctorName'] = doctorName;
          if (location != null) updated['location'] = location;
          if (notes != null) updated['notes'] = notes;
          if (status != null) updated['status'] = status;
          updated['updatedAt'] = DateTime.now().toIso8601String();
          return updated;
        }
        return appointment;
      }).toList();

      await _service.updateAppointment(appointmentId, updatedAppointments.firstWhere(
        (apt) => apt['id'] == appointmentId,
      ));

      _updateUpcomingAppointments(updatedAppointments);
      
      state = state.copyWith(
        appointments: updatedAppointments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await updateAppointment(appointmentId: appointmentId, status: 'cancelled');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAppointmentCompleted(String appointmentId) async {
    try {
      await updateAppointment(appointmentId: appointmentId, status: 'completed');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _service.deleteAppointment(appointmentId);
      
      final updatedAppointments = state.appointments
          .where((apt) => apt['id'] != appointmentId)
          .toList();
      
      _updateUpcomingAppointments(updatedAppointments);
      
      state = state.copyWith(appointments: updatedAppointments);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void selectAppointment(String appointmentId) {
    final appointment = state.appointments
        .where((apt) => apt['id'] == appointmentId)
        .firstOrNull;
    
    state = state.copyWith(selectedAppointment: appointment);
  }

  void clearSelectedAppointment() {
    state = state.copyWith(selectedAppointment: null);
  }

  Future<void> _loadAppointments() async {
    state = state.copyWith(isLoading: true);

    try {
      final appointments = await _service.getAppointments();
      _updateUpcomingAppointments(appointments);
      
      state = state.copyWith(
        appointments: appointments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _updateUpcomingAppointments(List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    final upcoming = appointments
        .where((apt) {
          final dateTime = DateTime.parse(apt['dateTime']);
          return dateTime.isAfter(now) && apt['status'] == 'scheduled';
        })
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a['dateTime']);
        final dateB = DateTime.parse(b['dateTime']);
        return dateA.compareTo(dateB);
      });

    state = state.copyWith(upcomingAppointments: upcoming);
  }

  List<Map<String, dynamic>> getAppointmentsByType(String type) {
    return state.appointments
        .where((apt) => apt['type'] == type)
        .toList();
  }

  List<Map<String, dynamic>> getAppointmentsForDate(DateTime date) {
    final dateStr = DateTime(date.year, date.month, date.day);
    
    return state.appointments.where((apt) {
      final aptDate = DateTime.parse(apt['dateTime']);
      final aptDateStr = DateTime(aptDate.year, aptDate.month, aptDate.day);
      return aptDateStr.isAtSameMomentAs(dateStr);
    }).toList();
  }

  Map<String, dynamic> getAppointmentStats() {
    final totalAppointments = state.appointments.length;
    final upcomingCount = state.upcomingAppointments.length;
    final completedCount = state.appointments
        .where((apt) => apt['status'] == 'completed')
        .length;
    final cancelledCount = state.appointments
        .where((apt) => apt['status'] == 'cancelled')
        .length;

    final appointmentTypes = <String, int>{};
    for (final apt in state.appointments) {
      final type = apt['type'] as String;
      appointmentTypes[type] = (appointmentTypes[type] ?? 0) + 1;
    }

    return {
      'totalAppointments': totalAppointments,
      'upcomingCount': upcomingCount,
      'completedCount': completedCount,
      'cancelledCount': cancelledCount,
      'appointmentTypes': appointmentTypes,
      'nextAppointment': state.upcomingAppointments.isNotEmpty 
          ? state.upcomingAppointments.first 
          : null,
    };
  }
}

// Providers
final appointmentSchedulerServiceProvider = Provider<AppointmentSchedulerService>((ref) {
  return AppointmentSchedulerService();
});

final appointmentSchedulerProvider = StateNotifierProvider<AppointmentSchedulerNotifier, AppointmentSchedulerState>((ref) {
  final service = ref.watch(appointmentSchedulerServiceProvider);
  return AppointmentSchedulerNotifier(service);
});
