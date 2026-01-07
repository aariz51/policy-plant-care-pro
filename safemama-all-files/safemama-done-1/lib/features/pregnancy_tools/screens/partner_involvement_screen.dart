import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safemama/features/pregnancy_tools/providers/partner_involvement_providers.dart';
import 'package:safemama/core/widgets/custom_button.dart';

class PartnerInvolvementScreen extends ConsumerStatefulWidget {
  const PartnerInvolvementScreen({super.key});

  @override
  ConsumerState<PartnerInvolvementScreen> createState() => _PartnerInvolvementScreenState();
}

class _PartnerInvolvementScreenState extends ConsumerState<PartnerInvolvementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerInvolvementProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Involvement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.hasUnreadNotifications)
            Stack(
              children: [
                IconButton(
                  onPressed: () => _tabController.animateTo(2),
                  icon: const Icon(Icons.notifications),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Sharing', icon: Icon(Icons.share)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(state),
                _buildSharingTab(state),
                _buildNotificationsTab(state),
              ],
            ),
      floatingActionButton: state.hasPartner
          ? FloatingActionButton.extended(
              onPressed: () => _showShareOptions(),
              icon: const Icon(Icons.share),
              label: const Text('Share Update'),
            )
          : FloatingActionButton.extended(
              onPressed: () => _invitePartner(),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Partner'),
            ),
    );
  }

  Widget _buildOverviewTab(PartnerInvolvementState state) {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload data
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.hasPartner)
              _buildPartnerCard(state)
            else
              _buildInvitePartnerCard(state),
            const SizedBox(height: 24),
            _buildStatsCard(state),
            const SizedBox(height: 24),
            _buildRecentSharedData(state),
            const SizedBox(height: 24),
            _buildRecommendations(state),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(PartnerInvolvementState state) {
    final relationship = state.partnerRelationship!;
    final partnerInfo = relationship['role'] == 'primary' 
        ? relationship['partner'] 
        : relationship['primary'];
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    (partnerInfo?['full_name'] as String? ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerInfo?['full_name'] ?? 'Partner',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        partnerInfo?['email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          state.isPrimaryUser ? 'Your Partner' : 'Following',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handlePartnerAction(action),
                  itemBuilder: (context) => [
                    if (state.isPrimaryUser)
                      const PopupMenuItem(value: 'access', child: Text('Manage Access')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove Partner')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Access Level: ${ref.read(partnerInvolvementProvider.notifier).getAccessLevelDescription(state.accessLevel)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitePartnerCard(PartnerInvolvementState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Invite Your Partner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your pregnancy journey with your partner. They can track appointments, milestones, and stay updated on your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _invitePartner(),
              icon: const Icon(Icons.person_add),
              label: const Text('Send Invitation'),
            ),
            if (state.invitations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Pending Invitations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...state.invitations.map((invitation) => 
                _buildInvitationCard(invitation)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final status = invitation['status'] as String;
    final expiresAt = DateTime.parse(invitation['expires_at']);
    final isExpired = DateTime.now().isAfter(expiresAt);
    
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text((invitation['partner_name'] as String)[0]),
        ),
        title: Text(invitation['partner_name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invitation['partner_email']),
            Text(
              isExpired ? 'Expired' : 'Expires ${_formatDate(expiresAt)}',
              style: TextStyle(
                fontSize: 12,
                color: isExpired ? Colors.red : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor(status, isExpired),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isExpired ? 'Expired' : status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(PartnerInvolvementState state) {
    final stats = state.stats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sharing Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Data Shared',
                    '${stats['dataShared'] ?? 0}',
                    Icons.share,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Invitations',
                    '${stats['invitationsSent'] ?? 0}',
                    Icons.mail,
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (state.hasPartner)
              const SizedBox(height: 16),
            if (state.hasPartner)
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Unread Updates',
                      '${stats['notificationsUnread'] ?? 0}',
                      Icons.notifications,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Connection Since',
                      _formatConnectionDate(stats['relationshipCreated']),
                      Icons.calendar_today,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentSharedData(PartnerInvolvementState state) {
    final recentData = ref.read(partnerInvolvementProvider.notifier)
        .getRecentSharedData(limit: 5);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Shares',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recentData.isNotEmpty)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentData.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.share_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No shared data yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Start sharing your pregnancy journey with your partner',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentData.map((data) => _buildSharedDataCard(data, isCompact: true)),
      ],
    );
  }

  Widget _buildRecommendations(PartnerInvolvementState state) {
    final recommendations = ref.read(partnerInvolvementProvider.notifier)
        .getSharingRecommendations();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sharing Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingTab(PartnerInvolvementState state) {
    final dataSharingStats = ref.read(partnerInvolvementProvider.notifier)
        .getDataSharingStats();
    
    return RefreshIndicator(
      onRefresh: () async {
        // Reload data
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!state.hasPartner)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Invite your partner to start sharing pregnancy data',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _invitePartner(),
                        child: const Text('Invite'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildQuickShareButtons(),
              const SizedBox(height: 24),
              _buildSharingStats(dataSharingStats),
              const SizedBox(height: 24),
            ],
            _buildSharedDataHistory(state),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShareButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildQuickShareCard(
                  'Weight Update',
                  Icons.monitor_weight,
                  Colors.blue,
                  () => _shareWeightUpdate(),
                ),
                _buildQuickShareCard(
                  'Appointment',
                  Icons.calendar_today,
                  Colors.green,
                  () => _shareAppointment(),
                ),
                _buildQuickShareCard(
                  'Milestone',
                  Icons.star,
                  Colors.orange,
                  () => _shareMilestone(),
                ),
                _buildQuickShareCard(
                  'Kick Count',
                  Icons.favorite,
                  Colors.red,
                  () => _shareKickCount(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShareCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingStats(Map<String, int> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sharing Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (stats.isEmpty)
              const Text(
                'No data shared yet',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...stats.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getDataTypeDisplayName(entry.key)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDataTypeColor(entry.key),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedDataHistory(PartnerInvolvementState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shared Data History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (state.sharedData.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No shared data yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Your shared pregnancy data will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.sharedData.map((data) => _buildSharedDataCard(data)),
      ],
    );
  }

  Widget _buildSharedDataCard(Map<String, dynamic> data, {bool isCompact = false}) {
    final createdAt = DateTime.parse(data['created_at']);
    final dataType = data['data_type'] as String;
    final note = data['note'] as String? ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDataTypeColor(dataType),
          child: Icon(
            _getDataTypeIcon(dataType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _getDataTypeDisplayName(dataType),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.isNotEmpty)
              Text(
                note,
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _formatTimeAgo(createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: isCompact 
            ? null 
            : PopupMenuButton<String>(
                onSelected: (action) => _handleSharedDataAction(data, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationsTab(PartnerInvolvementState state) {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload notifications
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.hasUnreadNotifications)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _markAllNotificationsAsRead(),
                    child: const Text('Mark All Read'),
                  ),
                ],
              )
            else
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            if (state.notifications.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No notifications yet'),
                      const SizedBox(height: 8),
                      const Text(
                        'Partner notifications will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...state.notifications.map((notification) => 
                _buildNotificationCard(notification)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final createdAt = DateTime.parse(notification['created_at']);
    final isRead = notification['is_read'] as bool;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : Colors.blue[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey : Colors.blue,
          child: Icon(
            _getNotificationIcon(notification['notification_type']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification['title'] ?? 'Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            const SizedBox(height: 4),
            Text(
              _formatTimeAgo(createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: !isRead
            ? IconButton(
                onPressed: () => _markNotificationAsRead(notification['id']),
                icon: const Icon(Icons.mark_email_read),
                tooltip: 'Mark as read',
              )
            : null,
        onTap: !isRead ? () => _markNotificationAsRead(notification['id']) : null,
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status, bool isExpired) {
    if (isExpired) return Colors.red;
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatConnectionDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 30) {
      return '${difference}d';
    } else {
      return '${(difference / 30).floor()}mo';
    }
  }

  Color _getDataTypeColor(String dataType) {
    switch (dataType) {
      case 'weight':
        return Colors.blue;
      case 'appointment':
        return Colors.green;
      case 'milestone':
        return Colors.orange;
      case 'kick_counter':
        return Colors.red;
      case 'contractions':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDataTypeIcon(String dataType) {
    switch (dataType) {
      case 'weight':
        return Icons.monitor_weight;
      case 'appointment':
        return Icons.calendar_today;
      case 'milestone':
        return Icons.star;
      case 'kick_counter':
        return Icons.favorite;
      case 'contractions':
        return Icons.timer;
      default:
        return Icons.share;
    }
  }

  String _getDataTypeDisplayName(String dataType) {
    switch (dataType) {
      case 'weight':
        return 'Weight Update';
      case 'appointment':
        return 'Appointment';
      case 'milestone':
        return 'Milestone';
      case 'kick_counter':
        return 'Kick Counter';
      case 'contractions':
        return 'Contractions';
      default:
        return dataType;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'data_shared':
        return Icons.share;
      case 'invitation_sent':
        return Icons.mail;
      case 'invitation_accepted':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  // Action methods
  void _invitePartner() {
    ref.read(partnerInvolvementProvider.notifier).startNewInvitation();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _InvitePartnerSheet(),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Update',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: const Text('Weight Update'),
              onTap: () {
                Navigator.of(context).pop();
                _shareWeightUpdate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Appointment'),
              onTap: () {
                Navigator.of(context).pop();
                _shareAppointment();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Milestone'),
              onTap: () {
                Navigator.of(context).pop();
                _shareMilestone();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Kick Counter Session'),
              onTap: () {
                Navigator.of(context).pop();
                _shareKickCount();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handlePartnerAction(String action) {
    switch (action) {
      case 'access':
        _showAccessLevelDialog();
        break;
      case 'remove':
        _showRemovePartnerConfirmation();
        break;
    }
  }

  void _showAccessLevelDialog() {
    final currentLevel = ref.read(partnerInvolvementProvider).accessLevel ?? 'full';
    final levels = ref.read(partnerInvolvementProvider.notifier).getAvailableAccessLevels();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partner Access Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) => RadioListTile<String>(
            title: Text(level.replaceAll('_', ' ').toUpperCase()),
            subtitle: Text(ref.read(partnerInvolvementProvider.notifier)
                .getAccessLevelDescription(level)),
            value: level,
            groupValue: currentLevel,
            onChanged: (value) {
              if (value != null) {
                ref.read(partnerInvolvementProvider.notifier)
                   .updateAccessLevel(value);
                Navigator.of(context).pop();
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showRemovePartnerConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Partner'),
        content: const Text('Are you sure you want to remove your partner? They will no longer have access to your pregnancy data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(partnerInvolvementProvider.notifier).removePartner();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _shareWeightUpdate() {
    // This would open a form to share weight update
    // For now, share a sample update
    ref.read(partnerInvolvementProvider.notifier).shareWeightUpdate(
      weight: 65.5,
      pregnancyWeek: 20,
      note: 'Feeling good this week!',
    );
  }

  void _shareAppointment() {
    // This would open a form to share appointment
    ref.read(partnerInvolvementProvider.notifier).shareAppointment(
      title: 'Prenatal Checkup',
      doctorName: 'Dr. Smith',
      dateTime: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      notes: 'Regular monthly checkup',
    );
  }

  void _shareMilestone() {
    // This would open a form to share milestone
    ref.read(partnerInvolvementProvider.notifier).shareMilestone(
      title: 'First Kick Felt',
      description: 'Felt the baby kick for the first time!',
      pregnancyWeek: 18,
    );
  }

  void _shareKickCount() {
    // This would open a form to share kick count session
    ref.read(partnerInvolvementProvider.notifier).shareKickCounterSession(
      kickCount: 10,
      sessionDuration: 600, // 10 minutes
      pregnancyWeek: 20,
    );
  }

  void _markNotificationAsRead(String notificationId) {
    ref.read(partnerInvolvementProvider.notifier)
       .markNotificationAsRead(notificationId);
  }

  void _markAllNotificationsAsRead() {
    ref.read(partnerInvolvementProvider.notifier)
       .markAllNotificationsAsRead();
  }

  void _handleSharedDataAction(Map<String, dynamic> data, String action) {
    switch (action) {
      case 'view':
        // Show data details
        break;
    }
  }
}

class _InvitePartnerSheet extends ConsumerStatefulWidget {
  const _InvitePartnerSheet();

  @override
  ConsumerState<_InvitePartnerSheet> createState() => _InvitePartnerSheetState();
}

class _InvitePartnerSheetState extends ConsumerState<_InvitePartnerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                const Text(
                  'Invite Partner',
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
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Partner Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Partner Email *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Personal Message (Optional)',
                      hintText: 'Add a personal message to your invitation...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  CustomElevatedButton(
                    onPressed: _sendInvitation,
                    text: 'Send Invitation',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendInvitation() {
    if (_formKey.currentState?.validate() != true) return;

    ref.read(partnerInvolvementProvider.notifier).updateCurrentInvitation({
      'partnerEmail': _emailController.text.trim(),
      'partnerName': _nameController.text.trim(),
      'personalMessage': _messageController.text.trim(),
    });

    ref.read(partnerInvolvementProvider.notifier).sendInvitation();
    Navigator.of(context).pop();
  }
}
