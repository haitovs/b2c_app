import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../auth/services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationDrawer extends StatefulWidget {
  const NotificationDrawer({super.key});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationService _notificationService;
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      _notificationService = NotificationService(authService);
      _loadNotifications();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    await _notificationService.getNotifications();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int get _unreadCount => _notificationService.unreadCount;

  List<NotificationItem> get _notifications =>
      _notificationService.notifications;

  void _markAsRead(int id) async {
    await _notificationService.markAsRead(id);
    if (mounted) setState(() {});
  }

  void _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    if (mounted) setState(() {});
  }

  void _navigateToEntity(String? entityType, String? entityId) {
    if (entityType == null) return;

    // Close the drawer first
    Navigator.of(context).pop();

    // Get current event ID - default to 1 if not set
    final eventId = '1'; // Uses default event for now

    // Navigate based on entity type
    switch (entityType.toUpperCase()) {
      case 'MEETING':
      case 'MEETING_REQUEST':
      case 'MEETING_ACCEPTED':
      case 'MEETING_DECLINED':
      case 'MEETING_CANCELLED':
      case 'MEETING_MODIFIED':
        GoRouter.of(context).push('/events/$eventId/meetings');
        break;
      case 'TICKET':
      case 'TICKET_RESPONSE':
        GoRouter.of(context).push('/events/$eventId/contact-us');
        break;
      default:
        // Unknown type - just close drawer
        break;
    }
  }

  /// Get icon and color based on notification type
  IconData _getIconForType(String? type) {
    switch (type?.toUpperCase()) {
      case 'MEETING_REQUEST':
      case 'MEETING_ACCEPTED':
      case 'MEETING_DECLINED':
      case 'MEETING_CANCELLED':
      case 'MEETING_MODIFIED':
        return Icons.handshake;
      case 'TICKET_RESPONSE':
        return Icons.support_agent;
      case 'ROLE_CHANGED':
        return Icons.verified_user;
      case 'ACCOUNT_VERIFIED':
        return Icons.verified;
      case 'EVENT_ANNOUNCEMENT':
        return Icons.campaign;
      case 'AGENDA_CHANGE':
        return Icons.calendar_today;
      case 'ADMIN_BROADCAST':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch (type?.toUpperCase()) {
      case 'MEETING_REQUEST':
        return const Color(0xFF2196F3);
      case 'MEETING_ACCEPTED':
        return const Color(0xFF4CAF50);
      case 'MEETING_DECLINED':
      case 'MEETING_CANCELLED':
        return const Color(0xFFF44336);
      case 'MEETING_MODIFIED':
        return const Color(0xFFFF9800);
      case 'TICKET_RESPONSE':
        return const Color(0xFF9C27B0);
      case 'ROLE_CHANGED':
        return const Color(0xFF00BCD4);
      case 'ACCOUNT_VERIFIED':
        return const Color(0xFF4CAF50);
      case 'EVENT_ANNOUNCEMENT':
        return const Color(0xFF3C4494);
      case 'AGENDA_CHANGE':
        return const Color(0xFF607D8B);
      case 'ADMIN_BROADCAST':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF3C4494);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Drawer(
      width: isMobile ? screenWidth : 480,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isMobile
              ? BorderRadius.zero
              : const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(-10, 0),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isMobile),

              // Tabs
              _buildTabs(),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3C4494),
                          strokeWidth: 2,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotificationList(_notifications),
                          _buildNotificationList(
                            _notifications.where((n) => !n.isRead).toList(),
                          ),
                          _buildNotificationList(
                            [],
                          ), // Mentions - future feature
                        ],
                      ),
              ),

              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 30,
        isMobile ? 16 : 25,
        isMobile ? 16 : 25,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Bell Icon with badge
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C4494).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF3C4494),
                      size: 26,
                    ),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4757),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          _unreadCount.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notificationsTitle,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _unreadCount > 0
                          ? 'You have $_unreadCount unread notifications'
                          : 'All caught up!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadNotifications,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.close, color: Colors.grey[700], size: 20),
                  ),
                ),
              ),
            ],
          ),

          // Mark all as read button
          if (_unreadCount > 0) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _markAllAsRead,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C4494).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3C4494).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.done_all,
                      color: Color(0xFF3C4494),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mark all as read',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3C4494),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF3C4494),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C4494).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.all(4),
        labelPadding: EdgeInsets.zero,
        tabs: [
          Tab(
            child: SizedBox(
              width: double.infinity,
              child: Center(child: Text(AppLocalizations.of(context)!.all)),
            ),
          ),
          Tab(
            child: SizedBox(
              width: double.infinity,
              child: Center(child: Text(AppLocalizations.of(context)!.unread)),
            ),
          ),
          Tab(
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Text(AppLocalizations.of(context)!.mentions),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No notifications",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up!",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final isUnread = !item.isRead;
        final icon = _getIconForType(item.relatedEntityType);
        final color = _getColorForType(item.relatedEntityType);

        return GestureDetector(
          onTap: () {
            _markAsRead(item.id);
            // Navigate to related entity based on type
            _navigateToEntity(item.relatedEntityType, item.relatedEntityId);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isUnread
                  ? const Color(0xFF3C4494).withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: isUnread
                  ? Border.all(
                      color: const Color(0xFF3C4494).withValues(alpha: 0.15),
                      width: 1,
                    )
                  : Border.all(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with colored background
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.inter(
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  color: const Color(0xFF1E1E1E),
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3C4494),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(item.createdAt),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Material(
        color: const Color(0xFF3C4494),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            // Could navigate to a full notifications page in the future
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
