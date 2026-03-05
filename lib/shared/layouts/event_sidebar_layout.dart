import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/event_context_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../../features/shop/providers/shop_providers.dart';

// =============================================================================
// EventSidebarLayout — shared scaffold for all event sub-pages
// =============================================================================

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
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            _EventTopBar(
              title: title,
              eventName: eventName,
              eventId: eventId,
              unreadCount: unreadCount,
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 260,
                    child: _EventSidebar(
                      eventId: eventId,
                      eventIdInt: eventIdInt,
                      currentPath: currentPath,
                    ),
                  ),
                  Expanded(child: child),
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
        preferredSize: const Size.fromHeight(64),
        child: _EventTopBar(
          title: title,
          eventName: eventName,
          eventId: eventId,
          unreadCount: unreadCount,
          showMenuButton: true,
          onMenuPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: _EventSidebar(
            eventId: eventId,
            eventIdInt: eventIdInt,
            currentPath: currentPath,
            onItemTap: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: child,
    );
  }
}

// =============================================================================
// Top Bar — dark indigo header with event name
// =============================================================================

class _EventTopBar extends StatelessWidget {
  final String title;
  final String eventName;
  final String eventId;
  final int unreadCount;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const _EventTopBar({
    required this.title,
    required this.eventName,
    required this.eventId,
    required this.unreadCount,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (showMenuButton)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 24, color: Colors.white),
                tooltip: 'Menu',
                onPressed: onMenuPressed,
              ),
            ),
          // Event logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.diamond_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Event title
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Notification bell
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: AppTheme.errorColor,
              child: const Icon(
                Icons.notifications_outlined,
                size: 24,
                color: Colors.white,
              ),
            ),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          // Profile
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              size: 24,
              color: Colors.white,
            ),
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sidebar — company header, quick actions, navigation
// =============================================================================

class _EventSidebar extends ConsumerWidget {
  final String eventId;
  final int eventIdInt;
  final String currentPath;
  final VoidCallback? onItemTap;

  const _EventSidebar({
    required this.eventId,
    required this.eventIdInt,
    required this.currentPath,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPurchased = ref.watch(hasPurchasedProvider(eventIdInt));
    final cartCount = ref.watch(cartBadgeCountProvider(eventIdInt));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Company header
          _CompanyHeader(
            eventId: eventId,
            cartCount: cartCount,
            onItemTap: onItemTap,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _QuickActionsSection(
                    eventId: eventId,
                    hasPurchased: hasPurchased,
                    onItemTap: onItemTap,
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                  // Navigation items
                  const SizedBox(height: 8),
                  _buildNavSection(context, hasPurchased),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Back to events
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _BackToEventsLink(onTap: onItemTap),
        ],
      ),
    );
  }

  Widget _buildNavSection(BuildContext context, bool hasPurchased) {
    const lockedUntilPurchase = {
      'Visa & Travel Center',
      'Services & Add-Ons',
      'Schedule & Meetings',
      'Financial Section',
      'Analytics',
    };

    final basePath = '/events/$eventId';
    final items = <_NavItemData>[
      _NavItemData('Visa & Travel Center', Icons.public_outlined, '$basePath/visa-travel'),
      _NavItemData('Services & Add-Ons', Icons.grid_view_outlined, '$basePath/services'),
      _NavItemData('Schedule & Meetings', Icons.people_alt_outlined, '$basePath/schedule'),
      _NavItemData('Financial Section', Icons.account_balance_wallet_outlined, '$basePath/financial'),
      _NavItemData('Analytics', Icons.insights_outlined, '$basePath/analytics'),
      _NavItemData('Speakers', Icons.record_voice_over_outlined, '$basePath/speakers'),
      _NavItemData('Participants of event', Icons.groups_outlined, '$basePath/participants'),
      _NavItemData('News', Icons.article_outlined, '$basePath/news'),
      _NavItemData('Hotline', Icons.support_agent_outlined, '$basePath/hotline'),
      _NavItemData('Feedback', Icons.chat_bubble_outline, '$basePath/feedback'),
      _NavItemData('FAQ', Icons.help_outline, '$basePath/faq'),
    ];

    return Column(
      children: items.map((item) {
        final isActive = _isPathActive(currentPath, item.path);
        final isLocked = lockedUntilPurchase.contains(item.label) && !hasPurchased;
        return _NavItem(
          label: item.label,
          icon: item.icon,
          isActive: isActive,
          isLocked: isLocked,
          onTap: () {
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Purchase a service package to unlock this feature'),
                action: SnackBarAction(
                  label: 'View Services',
                  onPressed: () => context.go('/events/$eventId/services'),
                ),
              ));
              return;
            }
            onItemTap?.call();
            context.go(item.path);
          },
        );
      }).toList(),
    );
  }

  bool _isPathActive(String currentPath, String navPath) {
    if (currentPath == navPath) return true;
    if (currentPath.startsWith('$navPath/')) return true;
    return false;
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final String path;

  const _NavItemData(this.label, this.icon, this.path);
}

// =============================================================================
// Company Header
// =============================================================================

class _CompanyHeader extends StatelessWidget {
  final String eventId;
  final int cartCount;
  final VoidCallback? onItemTap;

  const _CompanyHeader({
    required this.eventId,
    required this.cartCount,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Company logo placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: Icon(
              Icons.business_outlined,
              size: 18,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your company',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          // Cart icon with badge
          if (cartCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () {
                  onItemTap?.call();
                  context.go('/events/$eventId/services/cart');
                },
                borderRadius: BorderRadius.circular(8),
                child: Badge(
                  label: Text(
                    cartCount.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: AppTheme.successColor,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 22,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          // Hamburger menu
          Icon(Icons.menu, size: 22, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}

// =============================================================================
// Quick Actions Section
// =============================================================================

class _QuickActionsSection extends StatelessWidget {
  final String eventId;
  final bool hasPurchased;
  final VoidCallback? onItemTap;

  const _QuickActionsSection({
    required this.eventId,
    required this.hasPurchased,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _QuickActionItem(
            icon: Icons.task_alt_outlined,
            label: 'Complete Company Profile',
            isLocked: !hasPurchased,
            onTap: () => _handleTap(context, '/events/$eventId/company-profile'),
          ),
          _QuickActionItem(
            icon: Icons.person_add_outlined,
            label: 'Add Team Member',
            isLocked: !hasPurchased,
            onTap: () => _handleTap(context, '/events/$eventId/team/add'),
          ),
          _QuickActionItem(
            icon: Icons.description_outlined,
            label: 'Order Additional Services',
            isLocked: !hasPurchased,
            onTap: () => _handleTap(context, '/events/$eventId/services'),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, String route) {
    if (!hasPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Purchase a service package to unlock this feature'),
        action: SnackBarAction(
          label: 'View Services',
          onPressed: () => context.go('/events/$eventId/services'),
        ),
      ));
      return;
    }
    onItemTap?.call();
    context.go(route);
  }
}

// =============================================================================
// Quick Action Item — simple icon + label + lock row
// =============================================================================

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLocked;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isLocked ? Colors.grey.shade500 : Colors.grey.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isLocked ? Colors.grey.shade500 : Colors.black87,
                ),
              ),
            ),
            if (isLocked)
              Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Navigation Item — with active indicator and lock state
// =============================================================================

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isActive
        ? AppTheme.primaryColor
        : isLocked
            ? Colors.grey.shade500
            : Colors.black87;

    final Color iconColor = isActive
        ? AppTheme.primaryColor
        : isLocked
            ? Colors.grey.shade400
            : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.04)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            if (isLocked)
              Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Back to Events Link
// =============================================================================

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
            Icon(Icons.arrow_back, size: 18, color: Colors.grey.shade600),
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
