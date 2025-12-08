import 'package:b2c_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notification_service.dart';

class NotificationDrawer extends StatefulWidget {
  const NotificationDrawer({super.key});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _notifications = [
        {
          "id": 1,
          "title": "New event registration",
          "subtitle": "Diana Myradova registered for Tech Summit 2024",
          "time": "2 min ago",
          "is_read": false,
          "type": "event",
          "icon": Icons.event,
          "color": const Color(0xFF4CAF50),
        },
        {
          "id": 2,
          "title": "Meeting reminder",
          "subtitle": "Your meeting with sponsors starts in 30 minutes",
          "time": "12 min ago",
          "is_read": false,
          "type": "reminder",
          "icon": Icons.access_time,
          "color": const Color(0xFFFF9800),
        },
        {
          "id": 3,
          "title": "New message received",
          "subtitle": "Myrad Rahmanov sent you a message about the conference",
          "time": "45 min ago",
          "is_read": false,
          "type": "message",
          "icon": Icons.message,
          "color": const Color(0xFF2196F3),
        },
        {
          "id": 4,
          "title": "File shared with you",
          "subtitle": "Conference agenda has been updated",
          "time": "1 hour ago",
          "is_read": true,
          "type": "file",
          "file_name": "Conference_Agenda_2024.pdf",
          "file_size": "2.4 MB",
          "icon": Icons.attach_file,
          "color": const Color(0xFF9C27B0),
        },
        {
          "id": 5,
          "title": "Schedule updated",
          "subtitle": "The keynote speech has been rescheduled to 2:00 PM",
          "time": "2 hours ago",
          "is_read": true,
          "type": "schedule",
          "icon": Icons.calendar_today,
          "color": const Color(0xFF607D8B),
        },
        {
          "id": 6,
          "title": "New speaker added",
          "subtitle": "John Smith has been added as a keynote speaker",
          "time": "3 hours ago",
          "is_read": true,
          "type": "speaker",
          "icon": Icons.person_add,
          "color": const Color(0xFF00BCD4),
        },
      ];
      _isLoading = false;
    });
  }

  int get _unreadCount =>
      _notifications.where((n) => !n['is_read']).toList().length;

  void _markAsRead(int id) {
    setState(() {
      for (var n in _notifications) {
        if (n['id'] == id) {
          n['is_read'] = true;
        }
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
    });
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
                            _notifications.where((n) => !n['is_read']).toList(),
                          ),
                          _buildNotificationList([]),
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

  Widget _buildNotificationList(List<dynamic> items) {
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
        final isUnread = !item['is_read'];

        return GestureDetector(
          onTap: () {
            _markAsRead(item['id']);
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
                      color: (item['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 22,
                    ),
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
                                item['title'],
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
                          item['subtitle'] ?? '',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // File attachment if present
                        if (item['type'] == 'file' &&
                            item['file_name'] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE53935,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Color(0xFFE53935),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['file_name'],
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          color: const Color(0xFF1E1E1E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        item['file_size'],
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.download_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                        Text(
                          item['time'],
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
            // TODO: Navigate to all notifications
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all notifications',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
