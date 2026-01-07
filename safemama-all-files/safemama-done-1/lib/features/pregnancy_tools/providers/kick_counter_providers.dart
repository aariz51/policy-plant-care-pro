import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/kick_counter_service.dart';
import 'package:uuid/uuid.dart';

class KickCounterState {
  final Map<String, dynamic>? currentSession;
  final List<Map<String, dynamic>> recentSessions;
  final bool isLoading;
  final String? error;

  const KickCounterState({
    this.currentSession,
    this.recentSessions = const [],
    this.isLoading = false,
    this.error,
  });

  KickCounterState copyWith({
    Map<String, dynamic>? currentSession,
    List<Map<String, dynamic>>? recentSessions,
    bool? isLoading,
    String? error,
  }) {
    return KickCounterState(
      currentSession: currentSession ?? this.currentSession,
      recentSessions: recentSessions ?? this.recentSessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class KickCounterNotifier extends StateNotifier<KickCounterState> {
  final KickCounterService _service;

  KickCounterNotifier(this._service) : super(const KickCounterState()) {
    loadRecentSessions();
  }

  void startSession() {
    const uuid = Uuid();
    final session = {
      'id': uuid.v4(), // Use UUID v4 for guaranteed uniqueness
      'startTime': DateTime.now().toIso8601String(),
      'kicks': <Map<String, dynamic>>[],
      'isActive': true,
      'totalPauseDuration': 0, // Initialize total pause duration
    };

    state = state.copyWith(currentSession: session);
  }

  void recordKick() {
    if (state.currentSession == null) return;

    final updatedSession = Map<String, dynamic>.from(state.currentSession!);
    final kicks = List<Map<String, dynamic>>.from(updatedSession['kicks']);
    
    kicks.add({
      'timestamp': DateTime.now().toIso8601String(),
      'note': '',
    });

    updatedSession['kicks'] = kicks;
    state = state.copyWith(currentSession: updatedSession);
  }

  void pauseSession() {
    if (state.currentSession == null) return;

    final updatedSession = Map<String, dynamic>.from(state.currentSession!);
    final isActive = updatedSession['isActive'] as bool? ?? true;
    
    if (isActive) {
      // Pause the session
      updatedSession['isActive'] = false;
      updatedSession['pausedAt'] = DateTime.now().toIso8601String();
    } else {
      // Resume the session
      updatedSession['isActive'] = true;
      // Calculate the pause duration and add it to accumulated pause time
      final pausedAtStr = updatedSession['pausedAt'];
      if (pausedAtStr != null && pausedAtStr is String) {
        final pausedAt = DateTime.parse(pausedAtStr);
        final pauseDuration = DateTime.now().difference(pausedAt);
        final totalPauseDuration = (updatedSession['totalPauseDuration'] as int? ?? 0) + pauseDuration.inMilliseconds;
        updatedSession['totalPauseDuration'] = totalPauseDuration;
      }
      updatedSession.remove('pausedAt');
    }

    state = state.copyWith(currentSession: updatedSession);
  }

  void resumeSession() {
    // Now handled by pauseSession toggle
    pauseSession();
  }

  Future<void> endSession() async {
    if (state.currentSession == null) return;

    final session = Map<String, dynamic>.from(state.currentSession!);
    session['endTime'] = DateTime.now().toIso8601String();
    session['isActive'] = false;
    // Calculate final kick count
    session['kickCount'] = (session['kicks'] as List? ?? []).length;
    // Calculate session duration
    final startTimeStr = session['startTime'];
    if (startTimeStr != null && startTimeStr is String) {
      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.now();
      final totalPauseDuration = session['totalPauseDuration'] as int? ?? 0;
      final actualDuration = endTime.difference(startTime) - Duration(milliseconds: totalPauseDuration);
      session['sessionDuration'] = actualDuration.inMilliseconds;
    }

    // Save session
    try {
      await _service.saveKickSession(session);
    } catch (e) {
      // Handle error silently or log it
      print('Error saving kick session: $e');
    }

    // Add to recent sessions
    final updatedRecentSessions = [session, ...state.recentSessions];

    state = state.copyWith(
      currentSession: null,
      recentSessions: updatedRecentSessions,
    );
  }

  Future<void> loadRecentSessions() async {
    state = state.copyWith(isLoading: true);

    try {
      final sessions = await _service.getRecentSessions();
      state = state.copyWith(
        recentSessions: sessions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final kickCounterServiceProvider = Provider<KickCounterService>((ref) {
  return KickCounterService();
});

final kickCounterProvider = StateNotifierProvider<KickCounterNotifier, KickCounterState>((ref) {
  final service = ref.watch(kickCounterServiceProvider);
  return KickCounterNotifier(service);
});
