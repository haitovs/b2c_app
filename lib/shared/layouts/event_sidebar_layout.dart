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

    // Ensure event context is loaded when we have a route eventId
    // but name/logo are missing (e.g. direct navigation to a sub-page).
    final eventIdInt = int.tryParse(eventId) ?? 0;
    if (eventIdInt > 0 &&
        (eventContext.eventName == null || eventContext.logoUrl == null)) {
      Future.microtask(() {
        ref
            .read(eventContextProvider.notifier)
            .ensureEventContext(eventIdInt);
      });
    }

    final eventName =
        eventContext.eventName ??
        (eventContext.hasEventContext
            ? 'Event #${eventContext.eventId}'
            : 'Event');
    final logoUrl = eventContext.logoUrl;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            _EventTopBar(
              title: eventName,
              eventName: eventName,
              eventId: eventId,
              logoUrl: logoUrl,
              unreadCount: unreadCount,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    // Sidebar — separate rounded card
                    Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _EventSidebar(
                        eventId: eventId,
                        eventIdInt: eventIdInt,
                        currentPath: currentPath,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content — separate rounded card
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: child,
                      ),
                    ),
                  ],
                ),
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
          logoUrl: logoUrl,
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
  final String? logoUrl;
  final int unreadCount;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const _EventTopBar({
    required this.title,
    required this.eventName,
    required this.eventId,
    this.logoUrl,
    required this.unreadCount,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final barHeight = isMobile ? 64.0 : 100.0;
    final titleFontSize = isMobile ? 20.0 : 40.0;
    final logoSize = isMobile ? 40.0 : 56.0;
    final logoIconSize = isMobile ? 20.0 : 28.0;
    final actionIconSize = isMobile ? 24.0 : 28.0;

    return Container(
      height: barHeight,
      decoration: const BoxDecoration(color: AppTheme.primaryColor),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
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
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
              color: Colors.white.withValues(alpha: 0.15),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null
                ? Image.network(
                    logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.diamond_outlined,
                      color: Colors.white,
                      size: logoIconSize,
                    ),
                  )
                : Icon(
                    Icons.diamond_outlined,
                    color: Colors.white,
                    size: logoIconSize,
                  ),
          ),
          const SizedBox(width: 16),
          // Event name
          Expanded(
            child: Text(
              eventName,
              style: GoogleFonts.montserrat(
                fontSize: titleFontSize,
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
              child: Image.asset(
                'assets/header/bell.png',
                width: actionIconSize,
                height: actionIconSize,
              ),
            ),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          // Profile
          IconButton(
            icon: Image.asset(
              'assets/header/user.png',
              width: actionIconSize,
              height: actionIconSize,
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
      'Schedule & Meetings',
      'Financial Section',
      'Analytics',
    };

    final basePath = '/events/$eventId';
    final items = <_NavItemData>[
      _NavItemData(
        'Services & Add-Ons',
        'assets/sidebar/services.png',
        '$basePath/services',
      ),
      _NavItemData(
        'Visa & Travel Center',
        'assets/sidebar/visa.png',
        '$basePath/visa-travel',
      ),
      _NavItemData(
        'Schedule & Meetings',
        'assets/sidebar/meetings.png',
        '$basePath/schedule',
      ),
      _NavItemData(
        'Financial Section',
        'assets/sidebar/financial.png',
        '$basePath/financial',
      ),
      _NavItemData('Analytics', 'assets/sidebar/analytics.png', '$basePath/analytics'),
      _NavItemData(
        'Speakers',
        'assets/sidebar/speakers.png',
        '$basePath/speakers',
      ),
      _NavItemData(
        'Participants of event',
        'assets/sidebar/participants.png',
        '$basePath/participants',
      ),
      _NavItemData('News', 'assets/sidebar/news.png', '$basePath/news'),
      _NavItemData(
        'Hotline',
        'assets/sidebar/hotline.png',
        '$basePath/hotline',
      ),
      _NavItemData('Feedback', 'assets/sidebar/feedback.png', '$basePath/feedback'),
      _NavItemData('FAQ', 'assets/sidebar/faq.png', '$basePath/faq'),
    ];

    return Column(
      children: items.map((item) {
        final isActive = _isPathActive(currentPath, item.path);
        final isLocked =
            lockedUntilPurchase.contains(item.label) && !hasPurchased;
        return _NavItem(
          label: item.label,
          iconAsset: item.iconAsset,
          isActive: isActive,
          isLocked: isLocked,
          onTap: () {
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Purchase a service package to unlock this feature',
                  ),
                  action: SnackBarAction(
                    label: 'View Services',
                    onPressed: () => context.go('/events/$eventId/services'),
                  ),
                ),
              );
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
  final String iconAsset;
  final String path;

  const _NavItemData(this.label, this.iconAsset, this.path);
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
          // Hamburger menu
          Image.asset('assets/sidebar/burger.png', width: 22, height: 22),
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
            iconAsset: 'assets/sidebar/complete-company.png',
            label: 'Complete Company Profile',
            isLocked: !hasPurchased,
            onTap: () =>
                _handleTap(context, '/events/$eventId/company-profile'),
          ),
          _QuickActionItem(
            iconAsset: 'assets/sidebar/add_team.png',
            label: 'Add Team Member',
            isLocked: !hasPurchased,
            onTap: () => _handleTap(context, '/events/$eventId/team/add'),
          ),
          _QuickActionItem(
            iconAsset: 'assets/sidebar/order_additional.png',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Purchase a service package to unlock this feature',
          ),
          action: SnackBarAction(
            label: 'View Services',
            onPressed: () => context.go('/events/$eventId/services'),
          ),
        ),
      );
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
  final String iconAsset;
  final String label;
  final bool isLocked;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.iconAsset,
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
            Opacity(
              opacity: isLocked ? 0.4 : 1.0,
              child: Image.asset(iconAsset, width: 20, height: 20),
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
              Image.asset('assets/sidebar/lock.png', width: 16, height: 16),
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
  final String iconAsset;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.iconAsset,
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

    final double iconOpacity = isLocked ? 0.4 : 1.0;

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
            Opacity(
              opacity: iconOpacity,
              child: Image.asset(iconAsset, width: 20, height: 20),
            ),
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
              Image.asset('assets/sidebar/lock.png', width: 16, height: 16),
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
