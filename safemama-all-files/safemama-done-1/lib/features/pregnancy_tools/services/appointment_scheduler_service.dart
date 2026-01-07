import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';


class AppointmentSchedulerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> scheduleAppointment(Map<String, dynamic> appointment) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _scheduleAppointmentLocally(appointment);
        return;
      }

      final appointmentData = {
        'user_id': user.id,
        'appointment_id': appointment['id'],
        'title': appointment['title'],
        'type': appointment['type'],
        'appointment_datetime': appointment['dateTime'],
        'doctor_name': appointment['doctorName'],
        'location': appointment['location'],
        'notes': appointment['notes'],
        'reminder_settings': appointment['reminderSettings'],
        'status': appointment['status'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('appointments')
          .insert(appointmentData);

      await _scheduleAppointmentLocally(appointment);
    } catch (e) {
      await _scheduleAppointmentLocally(appointment);
      rethrow;
    }
  }

  Future<void> _scheduleAppointmentLocally(Map<String, dynamic> appointment) async {
    try {
      final List<Map<String, dynamic>> appointments = await getAppointments();
      appointments.insert(0, appointment);
      
      await _storageService.setString('appointments', 
          appointments.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('appointments')
            .select()
            .eq('user_id', user.id)
            .order('appointment_datetime', ascending: true);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      }

      return await _getAppointmentsLocally();
    } catch (e) {
      return await _getAppointmentsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getAppointmentsLocally() async {
    try {
      final appointmentsStr = await _storageService.getString('appointments');
      if (appointmentsStr != null) {
        // Parse appointments - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> updatedData) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final updateData = {
          'title': updatedData['title'],
          'type': updatedData['type'],
          'appointment_datetime': updatedData['dateTime'],
          'doctor_name': updatedData['doctorName'],
          'location': updatedData['location'],
          'notes': updatedData['notes'],
          'status': updatedData['status'],
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabase
            .from('appointments')
            .update(updateData)
            .eq('appointment_id', appointmentId)
            .eq('user_id', user.id);
      }

      await _updateAppointmentLocally(appointmentId, updatedData);
    } catch (e) {
      await _updateAppointmentLocally(appointmentId, updatedData);
    }
  }

  Future<void> _updateAppointmentLocally(String appointmentId, Map<String, dynamic> updatedData) async {
    try {
      final appointments = await _getAppointmentsLocally();
      
      for (int i = 0; i < appointments.length; i++) {
        if (appointments[i]['id'] == appointmentId) {
          appointments[i] = {...appointments[i], ...updatedData};
          break;
        }
      }
      
      await _storageService.setString('appointments', 
          appointments.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('appointments')
            .delete()
            .eq('appointment_id', appointmentId)
            .eq('user_id', user.id);
      }

      await _deleteAppointmentLocally(appointmentId);
    } catch (e) {
      await _deleteAppointmentLocally(appointmentId);
    }
  }

  Future<void> _deleteAppointmentLocally(String appointmentId) async {
    try {
      final appointments = await _getAppointmentsLocally();
      appointments.removeWhere((apt) => apt['id'] == appointmentId);
      
      await _storageService.setString('appointments', 
          appointments.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final appointments = await getAppointments();
      final now = DateTime.now();
      
      return appointments
          .where((apt) {
            final dateTime = DateTime.parse(apt['dateTime'] ?? apt['appointment_datetime']);
            return dateTime.isAfter(now) && apt['status'] == 'scheduled';
          })
          .toList()
        ..sort((a, b) {
          final dateA = DateTime.parse(a['dateTime'] ?? a['appointment_datetime']);
          final dateB = DateTime.parse(b['dateTime'] ?? b['appointment_datetime']);
          return dateA.compareTo(dateB);
        });
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('appointments')
            .select()
            .eq('user_id', user.id)
            .gte('appointment_datetime', startDate.toIso8601String())
            .lte('appointment_datetime', endDate.toIso8601String())
            .order('appointment_datetime', ascending: true);

        return List<Map<String, dynamic>>.from(response);
      }

      // Filter local appointments by date range
      final allAppointments = await _getAppointmentsLocally();
      return allAppointments.where((apt) {
        final aptDate = DateTime.parse(apt['dateTime'] ?? apt['appointment_datetime']);
        return aptDate.isAfter(startDate) && aptDate.isBefore(endDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByType(String type) async {
    try {
      final appointments = await getAppointments();
      return appointments
          .where((apt) => apt['type'] == type)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getNextAppointment() async {
    try {
      final upcomingAppointments = await getUpcomingAppointments();
      return upcomingAppointments.isNotEmpty ? upcomingAppointments.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> setAppointmentReminder(String appointmentId, List<int> reminderHours) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        await _supabase
            .from('appointments')
            .update({
              'reminder_settings': {'enabled': true, 'reminderTimes': reminderHours},
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('appointment_id', appointmentId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getPastAppointments({int limit = 20}) async {
    try {
      final appointments = await getAppointments();
      final now = DateTime.now();
      
      return appointments
          .where((apt) {
            final dateTime = DateTime.parse(apt['dateTime'] ?? apt['appointment_datetime']);
            return dateTime.isBefore(now);
          })
          .take(limit)
          .toList()
        ..sort((a, b) {
          final dateA = DateTime.parse(a['dateTime'] ?? a['appointment_datetime']);
          final dateB = DateTime.parse(b['dateTime'] ?? b['appointment_datetime']);
          return dateB.compareTo(dateA); // Descending order
        });
    } catch (e) {
      return [];
    }
  }
}
