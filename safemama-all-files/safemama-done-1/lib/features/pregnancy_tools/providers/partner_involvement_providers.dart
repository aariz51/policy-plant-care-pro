import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safemama/features/pregnancy_tools/services/partner_involvement_service.dart';

class PartnerInvolvementState {
  final List<Map<String, dynamic>> invitations;
  final Map<String, dynamic>? partnerRelationship;
  final List<Map<String, dynamic>> sharedData;
  final List<Map<String, dynamic>> notifications;
  final Map<String, dynamic> stats;
  final Map<String, dynamic>? currentInvitation;
  final bool isLoading;
  final String? error;
  final bool hasUnreadNotifications;

  const PartnerInvolvementState({
    this.invitations = const [],
    this.partnerRelationship,
    this.sharedData = const [],
    this.notifications = const [],
    this.stats = const {},
    this.currentInvitation,
    this.isLoading = false,
    this.error,
    this.hasUnreadNotifications = false,
  });

  PartnerInvolvementState copyWith({
    List<Map<String, dynamic>>? invitations,
    Map<String, dynamic>? partnerRelationship,
    List<Map<String, dynamic>>? sharedData,
    List<Map<String, dynamic>>? notifications,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? currentInvitation,
    bool? isLoading,
    String? error,
    bool? hasUnreadNotifications,
  }) {
    return PartnerInvolvementState(
      invitations: invitations ?? this.invitations,
      partnerRelationship: partnerRelationship ?? this.partnerRelationship,
      sharedData: sharedData ?? this.sharedData,
      notifications: notifications ?? this.notifications,
      stats: stats ?? this.stats,
      currentInvitation: currentInvitation ?? this.currentInvitation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasUnreadNotifications: hasUnreadNotifications ?? this.hasUnreadNotifications,
    );
  }

  bool get hasPartner => partnerRelationship != null;
  bool get isPrimaryUser => partnerRelationship?['role'] == 'primary';
  bool get isPartner => partnerRelationship?['role'] == 'partner';
  String? get accessLevel => partnerRelationship?['access_level'];
}

class PartnerInvolvementNotifier extends StateNotifier<PartnerInvolvementState> {
  final PartnerInvolvementService _service;

  PartnerInvolvementNotifier(this._service) : super(const PartnerInvolvementState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final invitations = await _service.getPartnerInvitations();
      final relationship = await _service.getPartnerRelationship();
      final sharedData = await _service.getSharedData();
      final notifications = await _service.getPartnerNotifications();
      final unreadNotifications = await _service.getPartnerNotifications(unreadOnly: true);
      final stats = await _service.getPartnerStats();

      state = state.copyWith(
        invitations: invitations,
        partnerRelationship: relationship,
        sharedData: sharedData,
        notifications: notifications,
        stats: stats,
        hasUnreadNotifications: unreadNotifications.isNotEmpty,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startNewInvitation() {
    final invitation = {
      'partnerEmail': '',
      'partnerName': '',
      'personalMessage': '',
    };

    state = state.copyWith(currentInvitation: invitation, error: null);
  }

  void updateCurrentInvitation(Map<String, dynamic> updates) {
    if (state.currentInvitation == null) return;

    final updatedInvitation = {...state.currentInvitation!, ...updates};
    state = state.copyWith(currentInvitation: updatedInvitation);
  }

  Future<void> sendInvitation() async {
    if (state.currentInvitation == null) return;

    final invitation = state.currentInvitation!;
    if (invitation['partnerEmail'] == null || invitation['partnerEmail'].isEmpty) {
      state = state.copyWith(error: 'Partner email is required');
      return;
    }
    if (invitation['partnerName'] == null || invitation['partnerName'].isEmpty) {
      state = state.copyWith(error: 'Partner name is required');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.invitePartner(
        partnerEmail: invitation['partnerEmail'],
        partnerName: invitation['partnerName'],
        personalMessage: invitation['personalMessage'],
      );

      state = state.copyWith(
        currentInvitation: null,
        isLoading: false,
      );

      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> acceptInvitation(String invitationCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.acceptPartnerInvitation(invitationCode);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> shareData({
    required String dataType,
    required Map<String, dynamic> data,
    String? note,
  }) async {
    if (!state.hasPartner) {
      state = state.copyWith(error: 'No partner relationship found');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.sharePregnancyData(
        dataType: dataType,
        data: data,
        note: note,
      );

      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> shareWeightUpdate({
    required double weight,
    required int pregnancyWeek,
    String? note,
  }) async {
    await shareData(
      dataType: 'weight',
      data: {
        'weight': weight,
        'pregnancyWeek': pregnancyWeek,
        'date': DateTime.now().toIso8601String(),
      },
      note: note ?? 'Weight update for week $pregnancyWeek',
    );
  }

  Future<void> shareAppointment({
    required String title,
    required String doctorName,
    required String dateTime,
    String? notes,
  }) async {
    await shareData(
      dataType: 'appointment',
      data: {
        'title': title,
        'doctorName': doctorName,
        'dateTime': dateTime,
        'notes': notes,
      },
      note: 'Upcoming appointment: $title',
    );
  }

  Future<void> shareMilestone({
    required String title,
    required String description,
    required int pregnancyWeek,
    String? photoUrl,
  }) async {
    await shareData(
      dataType: 'milestone',
      data: {
        'title': title,
        'description': description,
        'pregnancyWeek': pregnancyWeek,
        'photoUrl': photoUrl,
        'date': DateTime.now().toIso8601String(),
      },
      note: 'New milestone reached: $title',
    );
  }

  Future<void> shareKickCounterSession({
    required int kickCount,
    required int sessionDuration,
    required int pregnancyWeek,
  }) async {
    await shareData(
      dataType: 'kick_counter',
      data: {
        'kickCount': kickCount,
        'sessionDuration': sessionDuration,
        'pregnancyWeek': pregnancyWeek,
        'date': DateTime.now().toIso8601String(),
      },
      note: 'Baby kicked $kickCount times in ${sessionDuration ~/ 60} minutes',
    );
  }

  Future<void> shareContractionTimerSession({
    required int contractionCount,
    required double averageInterval,
    required double averageDuration,
  }) async {
    await shareData(
      dataType: 'contractions',
      data: {
        'contractionCount': contractionCount,
        'averageInterval': averageInterval,
        'averageDuration': averageDuration,
        'date': DateTime.now().toIso8601String(),
      },
      note: 'Contraction timing session: $contractionCount contractions',
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _service.markNotificationAsRead(notificationId);
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      for (final notification in state.notifications) {
        if (notification['is_read'] == false) {
          await _service.markNotificationAsRead(notification['id']);
        }
      }
      await _loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateAccessLevel(String accessLevel) async {
    if (!state.isPrimaryUser) {
      state = state.copyWith(error: 'Only primary user can update access levels');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updatePartnerAccessLevel(accessLevel: accessLevel);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> removePartner() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.removePartnerRelationship();
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<Map<String, dynamic>> getSharedDataByType(String dataType) {
    return state.sharedData
        .where((data) => data['data_type'] == dataType)
        .toList();
  }

  List<Map<String, dynamic>> getRecentSharedData({int limit = 10}) {
    final sortedData = List<Map<String, dynamic>>.from(state.sharedData);
    sortedData.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });
    return sortedData.take(limit).toList();
  }

  Map<String, int> getDataSharingStats() {
    final stats = <String, int>{};
    for (final data in state.sharedData) {
      final dataType = data['data_type'] as String;
      stats[dataType] = (stats[dataType] ?? 0) + 1;
    }
    return stats;
  }

  List<String> getSharingRecommendations() {
    final recommendations = <String>[];
    final dataSharingStats = getDataSharingStats();

    if (!state.hasPartner) {
      recommendations.add('Invite your partner to stay connected throughout your pregnancy journey');
      return recommendations;
    }

    if (dataSharingStats.isEmpty) {
      recommendations.addAll([
        'Share your first weight update with your partner',
        'Let your partner know about upcoming appointments',
        'Share kick counter sessions to involve your partner',
      ]);
    } else {
      if ((dataSharingStats['weight'] ?? 0) == 0) {
        recommendations.add('Share weight updates to keep your partner informed of your progress');
      }
      
      if ((dataSharingStats['appointment'] ?? 0) == 0) {
        recommendations.add('Share appointment schedules so your partner can support you');
      }
      
      if ((dataSharingStats['kick_counter'] ?? 0) == 0) {
        recommendations.add('Share kick counting sessions to help your partner feel connected');
      }
      
      if ((dataSharingStats['milestone'] ?? 0) == 0) {
        recommendations.add('Share pregnancy milestones to celebrate together');
      }
    }

    if (state.hasUnreadNotifications) {
      recommendations.add('Check your partner notifications for updates');
    }

    return recommendations.take(3).toList();
  }

  String getAccessLevelDescription(String? accessLevel) {
    switch (accessLevel) {
      case 'full':
        return 'Full access to all pregnancy data and tracking';
      case 'read-only':
        return 'Can view shared data but cannot add or modify';
      case 'limited':
        return 'Limited access to basic pregnancy updates only';
      default:
        return 'No access level set';
    }
  }

  List<String> getAvailableAccessLevels() {
    return ['full', 'read-only', 'limited'];
  }

  void cancelCurrentInvitation() {
    state = state.copyWith(currentInvitation: null, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final partnerInvolvementServiceProvider = Provider<PartnerInvolvementService>((ref) {
  return PartnerInvolvementService();
});

final partnerInvolvementProvider = StateNotifierProvider<PartnerInvolvementNotifier, PartnerInvolvementState>((ref) {
  final service = ref.watch(partnerInvolvementServiceProvider);
  return PartnerInvolvementNotifier(service);
});
