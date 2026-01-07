import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/services/storage_service.dart';

class PartnerInvolvementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  Future<void> invitePartner({
    required String partnerEmail,
    required String partnerName,
    String? personalMessage,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final invitationData = {
        'user_id': user.id,
        'invitation_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'partner_email': partnerEmail,
        'partner_name': partnerName,
        'personal_message': personalMessage ?? '',
        'status': 'pending',
        'invitation_code': _generateInvitationCode(),
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('partner_invitations')
          .insert(invitationData);

      // Send invitation email (would be handled by backend)
      await _sendInvitationEmail(invitationData);

      // Save locally
      await _savePartnerInvitationLocally(invitationData);
    } catch (e) {
      rethrow;
    }
  }

  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[random % chars.length]).join();
  }

  Future<void> _sendInvitationEmail(Map<String, dynamic> invitation) async {
    // This would trigger a backend email service
    // For now, we'll just log it
    print('Invitation email would be sent to: ${invitation['partner_email']}');
  }

  Future<void> _savePartnerInvitationLocally(Map<String, dynamic> invitation) async {
    try {
      final List<Map<String, dynamic>> invitations = await getPartnerInvitations();
      invitations.insert(0, invitation);
      
      await _storageService.setString('partner_invitations', 
          invitations.toString()); // Use proper JSON in production
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getPartnerInvitations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('partner_invitations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return await _getPartnerInvitationsLocally();
    }
  }

  Future<List<Map<String, dynamic>>> _getPartnerInvitationsLocally() async {
    try {
      final invitationsStr = await _storageService.getString('partner_invitations');
      if (invitationsStr != null) {
        // Parse invitations - use proper JSON in production
        return []; // Placeholder
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> acceptPartnerInvitation(String invitationCode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Find invitation by code
      final invitation = await _supabase
          .from('partner_invitations')
          .select()
          .eq('invitation_code', invitationCode)
          .eq('status', 'pending')
          .maybeSingle();

      if (invitation == null) {
        throw Exception('Invalid or expired invitation code');
      }

      // Check if invitation is expired
      final expiresAt = DateTime.parse(invitation['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Invitation has expired');
      }

      // Create partner relationship
      await _supabase
          .from('partner_relationships')
          .insert({
            'primary_user_id': invitation['user_id'],
            'partner_user_id': user.id,
            'relationship_type': 'partner',
            'access_level': 'full', // full, read-only, limited
            'created_at': DateTime.now().toIso8601String(),
          });

      // Update invitation status
      await _supabase
          .from('partner_invitations')
          .update({
            'status': 'accepted',
            'accepted_by': user.id,
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('invitation_code', invitationCode);

    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPartnerRelationship() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Check if user is primary user in a relationship
      var relationship = await _supabase
          .from('partner_relationships')
          .select('''
            *,
            partner:profiles!partner_user_id(full_name, email)
          ''')
          .eq('primary_user_id', user.id)
          .maybeSingle();

      if (relationship != null) {
        relationship['role'] = 'primary';
        return relationship;
      }

      // Check if user is partner in a relationship
      relationship = await _supabase
          .from('partner_relationships')
          .select('''
            *,
            primary:profiles!primary_user_id(full_name, email)
          ''')
          .eq('partner_user_id', user.id)
          .maybeSingle();

      if (relationship != null) {
        relationship['role'] = 'partner';
        return relationship;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> sharePregnancyData({
    required String dataType, // 'weight', 'appointments', 'milestones', etc.
    required Map<String, dynamic> data,
    String? note,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final relationship = await getPartnerRelationship();
      if (relationship == null) {
        throw Exception('No partner relationship found');
      }

      final sharedDataEntry = {
        'user_id': user.id,
        'relationship_id': relationship['id'],
        'data_type': dataType,
        'shared_data': data,
        'note': note ?? '',
        'visibility': 'partner', // partner, family, private
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('shared_pregnancy_data')
          .insert(sharedDataEntry);

      // Send notification to partner
      await _notifyPartner(relationship, dataType, note);

    } catch (e) {
      rethrow;
    }
  }

  Future<void> _notifyPartner(Map<String, dynamic> relationship, String dataType, String? note) async {
    try {
      final partnerId = relationship['role'] == 'primary' 
          ? relationship['partner_user_id'] 
          : relationship['primary_user_id'];

      await _supabase
          .from('partner_notifications')
          .insert({
            'recipient_user_id': partnerId,
            'sender_user_id': _supabase.auth.currentUser!.id,
            'notification_type': 'data_shared',
            'title': 'New pregnancy update shared',
            'message': 'Your partner shared ${dataType} data${note != null ? ': $note' : ''}',
            'data': {'dataType': dataType, 'note': note},
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Map<String, dynamic>>> getSharedData({String? dataType}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final relationship = await getPartnerRelationship();
      if (relationship == null) return [];

      var query = _supabase
          .from('shared_pregnancy_data')
          .select('''
            *,
            profiles!user_id(full_name)
          ''')
          .eq('relationship_id', relationship['id']);

      if (dataType != null) {
        query = query.eq('data_type', dataType);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPartnerNotifications({bool unreadOnly = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      var query = _supabase
          .from('partner_notifications')
          .select('''
            *,
            sender:profiles!sender_user_id(full_name)
          ''')
          .eq('recipient_user_id', user.id);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('partner_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_user_id', user.id);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> updatePartnerAccessLevel({
    required String accessLevel, // 'full', 'read-only', 'limited'
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final relationship = await getPartnerRelationship();
      if (relationship == null || relationship['role'] != 'primary') {
        throw Exception('Only primary user can update access levels');
      }

      await _supabase
          .from('partner_relationships')
          .update({
            'access_level': accessLevel,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', relationship['id']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removePartnerRelationship() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final relationship = await getPartnerRelationship();
      if (relationship == null) return;

      // Soft delete the relationship
      await _supabase
          .from('partner_relationships')
          .update({
            'status': 'inactive',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', relationship['id']);

      // Clear local data
      await _storageService.remove('partner_invitations');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPartnerStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'hasPartner': false,
          'invitationsSent': 0,
          'dataShared': 0,
          'notificationsUnread': 0,
        };
      }

      final relationship = await getPartnerRelationship();
      final invitations = await getPartnerInvitations();
      final sharedData = await getSharedData();
      final unreadNotifications = await getPartnerNotifications(unreadOnly: true);

      return {
        'hasPartner': relationship != null,
        'partnerRole': relationship?['role'],
        'invitationsSent': invitations.length,
        'dataShared': sharedData.length,
        'notificationsUnread': unreadNotifications.length,
        'relationshipCreated': relationship?['created_at'],
      };
    } catch (e) {
      return {
        'hasPartner': false,
        'invitationsSent': 0,
        'dataShared': 0,
        'notificationsUnread': 0,
      };
    }
  }
}
