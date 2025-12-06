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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Mock data for now until auth is fully wired
    setState(() {
      _notifications = [
        {
          "id": 1,
          "title": "Diana Myradova added new lead Leyli Ashyrberdiyeva",
          "time": "12 min ago",
          "is_read": false,
          "type": "lead",
        },
        {
          "id": 2,
          "title": "Myrad Rahmanov sent Files",
          "time": "12 min ago",
          "is_read": true,
          "type": "file",
          "file_name": "Copies of governments.pdf",
          "file_size": "12 MB",
        },
      ];
    });
    // final notifs = await _notificationService.getNotifications();
    // setState(() => _notifications = notifs);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    // Spec: "mobile full screen" -> 100% width on mobile, 540px on desktop
    // Spec: border-radius: 50px 0px 0px 50px (Desktop usually)
    // On mobile full screen, we might not want rounded corners on the left if it takes full width?
    // Or maybe the user literally means "mobile full screen" width but still sliding from right.
    // Let's assume on Mobile it covers everything, on Desktop it's 540px.

    return Drawer(
      // Drawer automatically slides from end.
      // Width property available in newer Flutter versions or use Container inside.
      width: isMobile ? screenWidth : 540,
      backgroundColor: Colors.transparent, // Handle styling in container
      elevation: 0, // Disable default shadow to use custom
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isMobile
              ? BorderRadius
                    .zero // Full screen usually doesn't have rounded corners
              : const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  bottomLeft: Radius.circular(50),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            // Mobile Safe Area padding
            if (isMobile) const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 25, 30, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.notificationsTitle,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x66826D6D)),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.all),
                    Tab(text: AppLocalizations.of(context)!.unread),
                    Tab(text: AppLocalizations.of(context)!.mentions),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList(_notifications), // All
                  _buildNotificationList(
                    _notifications.where((n) => !n['is_read']).toList(),
                  ), // Unread
                  _buildNotificationList([]), // Mentions (Empty for now)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<dynamic> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          "No notifications",
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          color: item['is_read']
              ? const Color(0xFFF3F3F3)
              : const Color(0xFFBDC6F4),
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 1), // Separator
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 15),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                    if (item['type'] == 'file') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBDC6F4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              item['file_name'],
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item['file_size'],
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      item['time'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w300,
                        fontSize: 10,
                        color: const Color(0xFF363636),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
