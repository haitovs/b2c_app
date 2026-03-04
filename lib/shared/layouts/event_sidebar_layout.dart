import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/event_context_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../../features/shop/providers/shop_providers.dart';

/// Shared sidebar layout for all event sub-pages.
/// Desktop (>= 900px): fixed 280px left sidebar + scrollable content area.
/// Mobile (< 900px): AppBar with hamburger icon that opens a Drawer.
class EventSidebarLayout extends ConsumerWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const EventSidebarLayout({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final routerState = GoRouterState.of(context);
    final eventId = routerState.pathParameters['id'] ?? '';
    final currentPath = routerState.uri.toString();

    final eventContext = ref.watch(eventContextProvider);
    final eventName = eventContext.hasEventContext
        ? 'Event #${eventContext.eventId}'
        : 'Event';

    final eventIdInt = int.tryParse(eventId) ?? 0;
    final cartCount = ref.watch(cartBadgeCountProvider(eventIdInt));
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            _TopBar(
              title: title,
              eventName: eventName,
              eventId: eventId,
              cartCount: cartCount,
              unreadCount: unreadCount,
              actions: actions,
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: _SidebarContent(
                      eventId: eventId,
                      eventName: eventName,
                      currentPath: currentPath,
                    ),
                  ),
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _TopBar(
          title: title,
          eventName: eventName,
          eventId: eventId,
          cartCount: cartCount,
          unreadCount: unreadCount,
          actions: actions,
          showMenuButton: true,
          onMenuPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: _SidebarContent(
            eventId: eventId,
            eventName: eventName,
            currentPath: currentPath,
            onItemTap: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Top Bar
// ---------------------------------------------------------------------------
class _TopBar extends ConsumerWidget {
  final String title;
  final String eventName;
  final String eventId;
  final int cartCount;
  final int unreadCount;
  final List<Widget>? actions;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const _TopBar({
    required this.title,
    required this.eventName,
    required this.eventId,
    required this.cartCount,
    required this.unreadCount,
    this.actions,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showMenuButton)
            _TopBarMenuButton(onPressed: onMenuPressed),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
          // Notification bell
          _BadgeIconButton(
            icon: Icons.notifications_outlined,
            count: unreadCount,
            tooltip: 'Notifications',
            onPressed: () {
              // Open notification drawer or navigate
              // For now, this is a placeholder
            },
          ),
          const SizedBox(width: 4),
          // Cart
          _BadgeIconButton(
            icon: Icons.shopping_cart_outlined,
            count: cartCount,
            tooltip: 'Cart',
            onPressed: () {
              if (eventId.isNotEmpty) {
                context.go('/events/$eventId/services/cart');
              }
            },
          ),
          const SizedBox(width: 4),
          // Profile
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            tooltip: 'Profile',
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
    );
  }
}

class _TopBarMenuButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _TopBarMenuButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(Icons.menu, size: 24),
        tooltip: 'Menu',
        onPressed: onPressed ?? () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback onPressed;

  const _BadgeIconButton({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: AppTheme.errorColor,
        child: Icon(icon, size: 24),
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar Content (shared between desktop sidebar and mobile drawer)
// ---------------------------------------------------------------------------
class _SidebarContent extends StatelessWidget {
  final String eventId;
  final String eventName;
  final String currentPath;
  final VoidCallback? onItemTap;

  const _SidebarContent({
    required this.eventId,
    required this.eventName,
    required this.currentPath,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Column(
        children: [
          // 1. Logo / Event name area
          _EventLogoArea(eventName: eventName),
          const Divider(height: 1),

          // 2. Quick Actions
          _QuickActionsSection(eventId: eventId, onItemTap: onItemTap),
          const Divider(height: 1),

          // 3. Navigation items (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: _buildNavItems(context),
              ),
            ),
          ),

          // 4. Back to Events
          const Divider(height: 1),
          _BackToEventsLink(onTap: onItemTap),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    final basePath = '/events/$eventId';
    final items = <_NavItemData>[
      _NavItemData('Dashboard', Icons.dashboard, '$basePath/menu'),
      _NavItemData('Company Profile', Icons.business, '$basePath/company-profile'),
      _NavItemData('Team Members', Icons.people, '$basePath/team'),
      _NavItemData('Event Services', Icons.shopping_bag, '$basePath/services'),
      _NavItemData('Visa & Travel', Icons.flight, '$basePath/visa-travel'),
      _NavItemData('Schedule & Meetings', Icons.calendar_today, '$basePath/schedule'),
      _NavItemData('Agenda', Icons.event_note, '$basePath/agenda'),
      _NavItemData('Speakers', Icons.record_voice_over, '$basePath/speakers'),
      _NavItemData('Participants', Icons.groups, '$basePath/participants'),
      _NavItemData('News', Icons.newspaper, '$basePath/news'),
      _NavItemData('FAQ', Icons.help_outline, '$basePath/faq'),
      _NavItemData('Financial', Icons.account_balance, '$basePath/financial', locked: true),
      _NavItemData('Analytics', Icons.analytics, '$basePath/analytics', locked: true),
      _NavItemData('Hotels', Icons.hotel, '$basePath/hotels', locked: true),
    ];

    return items.map((item) {
      final isActive = _isPathActive(currentPath, item.path);
      return _NavItem(
        label: item.label,
        icon: item.icon,
        path: item.path,
        isActive: isActive,
        isLocked: item.locked,
        onTap: () {
          onItemTap?.call();
          context.go(item.path);
        },
      );
    }).toList();
  }

  bool _isPathActive(String currentPath, String navPath) {
    // Exact match or the current path starts with navPath followed by /
    if (currentPath == navPath) return true;
    if (currentPath.startsWith('$navPath/')) return true;
    return false;
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final String path;
  final bool locked;

  const _NavItemData(this.label, this.icon, this.path, {this.locked = false});
}

// ---------------------------------------------------------------------------
// Event Logo / Name Area
// ---------------------------------------------------------------------------
class _EventLogoArea extends StatelessWidget {
  final String eventName;

  const _EventLogoArea({required this.eventName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              eventName,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Section
// ---------------------------------------------------------------------------
class _QuickActionsSection extends StatelessWidget {
  final String eventId;
  final VoidCallback? onItemTap;

  const _QuickActionsSection({
    required this.eventId,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'QUICK ACTIONS',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          _QuickActionButton(
            label: 'Add Team Member',
            icon: Icons.person_add_outlined,
            onTap: () {
              onItemTap?.call();
              context.go('/events/$eventId/team/add');
            },
          ),
          const SizedBox(height: 4),
          _QuickActionButton(
            label: 'Company Profile',
            icon: Icons.business_outlined,
            onTap: () {
              onItemTap?.call();
              context.go('/events/$eventId/company-profile');
            },
          ),
          const SizedBox(height: 4),
          _QuickActionButton(
            label: 'Order Services',
            icon: Icons.add_shopping_cart_outlined,
            onTap: () {
              onItemTap?.call();
              context.go('/events/$eventId/services');
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation Item
// ---------------------------------------------------------------------------
class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String path;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isActive
        ? AppTheme.primaryColor
        : Colors.transparent;
    final Color fgColor = isActive
        ? Colors.white
        : isLocked
            ? Colors.grey.shade400
            : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: isActive
              ? null
              : Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: fgColor,
                    ),
                  ),
                ),
                if (isLocked)
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Back to Events Link
// ---------------------------------------------------------------------------
class _BackToEventsLink extends StatelessWidget {
  final VoidCallback? onTap;

  const _BackToEventsLink({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap?.call();
        context.go('/');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back,
              size: 18,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Text(
              'Back to Events',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
