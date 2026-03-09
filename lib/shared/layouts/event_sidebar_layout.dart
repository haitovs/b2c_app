import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/event_context_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../../features/shop/providers/shop_providers.dart';

// =============================================================================
// EventShellLayout — persistent shell for all event sub-pages.
// Used as the builder for a ShellRoute so the sidebar stays mounted
// and only the content area (navigatorBuilder's child) swaps on navigation.
// =============================================================================

class EventShellLayout extends ConsumerWidget {
  final Widget child;

  const EventShellLayout({super.key, required this.child});

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

    // Mobile layout — sidebar in drawer
    return _MobileShell(
      eventName: eventName,
      eventId: eventId,
      eventIdInt: eventIdInt,
      logoUrl: logoUrl,
      unreadCount: unreadCount,
      currentPath: currentPath,
      child: child,
    );
  }
}

// Mobile shell — StatefulWidget so we can open the drawer via GlobalKey.
class _MobileShell extends StatefulWidget {
  final String eventName;
  final String eventId;
  final int eventIdInt;
  final String? logoUrl;
  final int unreadCount;
  final String currentPath;
  final Widget child;

  const _MobileShell({
    required this.eventName,
    required this.eventId,
    required this.eventIdInt,
    required this.logoUrl,
    required this.unreadCount,
    required this.currentPath,
    required this.child,
  });

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _EventTopBar(
          eventName: widget.eventName,
          eventId: widget.eventId,
          logoUrl: widget.logoUrl,
          unreadCount: widget.unreadCount,
          showMenuButton: true,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: _EventSidebar(
            eventId: widget.eventId,
            eventIdInt: widget.eventIdInt,
            currentPath: widget.currentPath,
            onItemTap: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: widget.child,
    );
  }
}

// =============================================================================
// Top Bar — dark indigo header with event name
// =============================================================================

class _EventTopBar extends StatelessWidget {
  final String eventName;
  final String eventId;
  final String? logoUrl;
  final int unreadCount;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const _EventTopBar({
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

class _EventSidebar extends ConsumerStatefulWidget {
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
  ConsumerState<_EventSidebar> createState() => _EventSidebarState();
}

class _EventSidebarState extends ConsumerState<_EventSidebar> {
  bool _visaExpanded = false;
  bool _agendaMeetingsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand groups if the current path is inside them
    final path = widget.currentPath;
    final base = '/events/${widget.eventId}';
    if (path.startsWith('$base/visa') || path.startsWith('$base/transfer') ||
        path.startsWith('$base/hotels') || path.startsWith('$base/travel')) {
      _visaExpanded = true;
    }
    if (path.startsWith('$base/agenda') || path.startsWith('$base/schedule') ||
        path.startsWith('$base/meetings')) {
      _agendaMeetingsExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPurchased = ref.watch(hasPurchasedProvider(widget.eventIdInt));
    final cartCount = ref.watch(cartBadgeCountProvider(widget.eventIdInt));

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
          _CompanyHeader(
            eventId: widget.eventId,
            cartCount: cartCount,
            onItemTap: widget.onItemTap,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuickActionsSection(
                    eventId: widget.eventId,
                    hasPurchased: hasPurchased,
                    onItemTap: widget.onItemTap,
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 8),
                  _buildNavSection(context, hasPurchased),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _BackToEventsLink(onTap: widget.onItemTap),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation section
  // ---------------------------------------------------------------------------

  Widget _buildNavSection(BuildContext context, bool hasPurchased) {
    final basePath = '/events/${widget.eventId}';
    final path = widget.currentPath;

    return Column(
      children: [
        // Dashboard
        _buildNavItem(
          context,
          label: 'Dashboard',
          iconAsset: 'assets/sidebar/analytics.svg',
          path: '$basePath/dashboard',
          hasPurchased: true,
        ),

        // Services & Add-Ons
        _buildNavItem(
          context,
          label: 'Services & Add-Ons',
          iconAsset: 'assets/sidebar/services.svg',
          path: '$basePath/services',
          hasPurchased: true,
        ),

        // ── Visa & Travel Center (expandable) ──
        _buildExpandableGroup(
          context,
          label: 'Visa & Travel Center',
          iconAsset: 'assets/sidebar/visa.svg',
          isExpanded: _visaExpanded,
          isLocked: !hasPurchased,
          isGroupActive: path.startsWith('$basePath/visa') ||
              path.startsWith('$basePath/transfer') ||
              path.startsWith('$basePath/hotels') ||
              path.startsWith('$basePath/travel'),
          onToggle: () => setState(() => _visaExpanded = !_visaExpanded),
          children: [
            _buildSubItem(
              context,
              label: 'Visa Application',
              path: '$basePath/visa-travel',
              isActive: path.startsWith('$basePath/visa'),
            ),
            _buildSubItem(
              context,
              label: 'Travel Information',
              path: '$basePath/travel',
              isActive: path.startsWith('$basePath/travel'),
              comingSoon: true,
            ),
            _buildSubItem(
              context,
              label: 'Transfer Information',
              path: '$basePath/transfer',
              isActive: path.startsWith('$basePath/transfer'),
              comingSoon: true,
            ),
            _buildSubItem(
              context,
              label: 'Hotel Information',
              path: '$basePath/hotels',
              isActive: path.startsWith('$basePath/hotels'),
              comingSoon: true,
            ),
          ],
        ),

        // ── Agenda & Meetings (expandable) ──
        _buildExpandableGroup(
          context,
          label: 'Agenda & Meetings',
          iconAsset: 'assets/sidebar/meetings.svg',
          isExpanded: _agendaMeetingsExpanded,
          isLocked: !hasPurchased,
          isGroupActive: path.startsWith('$basePath/agenda') ||
              path.startsWith('$basePath/schedule') ||
              path.startsWith('$basePath/meetings'),
          onToggle: () => setState(() => _agendaMeetingsExpanded = !_agendaMeetingsExpanded),
          children: [
            _buildSubItem(
              context,
              label: 'Agenda',
              path: '$basePath/agenda',
              isActive: path.startsWith('$basePath/agenda'),
            ),
            _buildSubItem(
              context,
              label: 'Meetings',
              path: '$basePath/schedule',
              isActive: path.startsWith('$basePath/schedule') ||
                  path.startsWith('$basePath/meetings'),
            ),
          ],
        ),

        // Financial Section (coming soon)
        _buildNavItem(
          context,
          label: 'Financial Section',
          iconAsset: 'assets/sidebar/financial.svg',
          path: '$basePath/financial',
          hasPurchased: hasPurchased,
        ),

        // Analytics (coming soon)
        _buildNavItem(
          context,
          label: 'Analytics',
          iconAsset: 'assets/sidebar/analytics.svg',
          path: '$basePath/analytics',
          hasPurchased: hasPurchased,
        ),

        // Speakers
        _buildNavItem(
          context,
          label: 'Speakers',
          iconAsset: 'assets/sidebar/speakers.svg',
          path: '$basePath/speakers',
          hasPurchased: true,
        ),

        // Participants of event
        _buildNavItem(
          context,
          label: 'Participants of event',
          iconAsset: 'assets/sidebar/participants.svg',
          path: '$basePath/participants',
          hasPurchased: true,
        ),

        // News
        _buildNavItem(
          context,
          label: 'News',
          iconAsset: 'assets/sidebar/news.svg',
          path: '$basePath/news',
          hasPurchased: true,
        ),

        // Hotline
        _buildNavItem(
          context,
          label: 'Hotline',
          iconAsset: 'assets/sidebar/hotline.svg',
          path: '$basePath/hotline',
          hasPurchased: true,
        ),

        // Feedback
        _buildNavItem(
          context,
          label: 'Feedback',
          iconAsset: 'assets/sidebar/feedback.svg',
          path: '$basePath/feedback',
          hasPurchased: true,
        ),

        // FAQ
        _buildNavItem(
          context,
          label: 'FAQ',
          iconAsset: 'assets/sidebar/faq.svg',
          path: '$basePath/faq',
          hasPurchased: true,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Regular nav item
  // ---------------------------------------------------------------------------

  Widget _buildNavItem(
    BuildContext context, {
    required String label,
    required String iconAsset,
    required String path,
    required bool hasPurchased,
  }) {
    final isActive = _isPathActive(widget.currentPath, path);
    final isLocked = !hasPurchased;
    return _NavItem(
      label: label,
      iconAsset: iconAsset,
      isActive: isActive,
      isLocked: isLocked,
      onTap: () {
        if (isLocked) {
          _showLockedSnackbar(context);
          return;
        }
        widget.onItemTap?.call();
        context.go(path);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Expandable group header + children
  // ---------------------------------------------------------------------------

  Widget _buildExpandableGroup(
    BuildContext context, {
    required String label,
    required String iconAsset,
    required bool isExpanded,
    required bool isLocked,
    required bool isGroupActive,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        // Group header
        InkWell(
          onTap: () {
            if (isLocked) {
              _showLockedSnackbar(context);
              return;
            }
            onToggle();
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isGroupActive && !isExpanded
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              color: isGroupActive && !isExpanded
                  ? AppTheme.primaryColor.withValues(alpha: 0.10)
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: isLocked
                      ? const ColorFilter.mode(Color(0xFFBBBBBB), BlendMode.srcIn)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isGroupActive ? FontWeight.w600 : FontWeight.w400,
                      color: isLocked
                          ? const Color(0xFFBBBBBB)
                          : isGroupActive
                              ? AppTheme.primaryColor
                              : Colors.black87,
                    ),
                  ),
                ),
                if (isLocked)
                  SvgPicture.asset('assets/sidebar/lock.svg', width: 16, height: 16)
                else
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: isGroupActive ? AppTheme.primaryColor : Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Animated children
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: children),
          crossFadeState: isExpanded && !isLocked
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-item (indented, inside expandable group)
  // ---------------------------------------------------------------------------

  Widget _buildSubItem(
    BuildContext context, {
    required String label,
    required String path,
    required bool isActive,
    bool comingSoon = false,
  }) {
    final Color textColor = comingSoon
        ? Colors.grey.shade400
        : isActive
            ? AppTheme.primaryColor
            : Colors.black87;

    return InkWell(
      onTap: comingSoon
          ? null
          : () {
              widget.onItemTap?.call();
              context.go(path);
            },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isActive && !comingSoon ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
          color: isActive && !comingSoon
              ? AppTheme.primaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.only(left: 48, right: 16, top: 10, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive && !comingSoon ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Soon',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showLockedSnackbar(BuildContext context) {
    AppSnackBar.showInfo(context, 'Purchase a service package to unlock this feature');
  }

  bool _isPathActive(String currentPath, String navPath) {
    if (currentPath == navPath) return true;
    if (currentPath.startsWith('$navPath/')) return true;
    return false;
  }
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
          SvgPicture.asset('assets/sidebar/burger.svg', width: 22, height: 22),
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
            iconAsset: 'assets/sidebar/complete-company.svg',
            label: 'Complete Company Profile',
            isLocked: !hasPurchased,
            onTap: () =>
                _handleTap(context, '/events/$eventId/company-profile'),
          ),
          _QuickActionItem(
            iconAsset: 'assets/sidebar/add_team.svg',
            label: 'Team Members',
            isLocked: !hasPurchased,
            onTap: () => _handleTap(context, '/events/$eventId/team'),
          ),
          _QuickActionItem(
            iconAsset: 'assets/sidebar/order_additional.svg',
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
      AppSnackBar.showInfo(context, 'Purchase a service package to unlock this feature');
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
            SvgPicture.asset(
              iconAsset,
              width: 20,
              height: 20,
              colorFilter: isLocked
                  ? const ColorFilter.mode(Color(0xFFBBBBBB), BlendMode.srcIn)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isLocked ? const Color(0xFFBBBBBB) : Colors.black87,
                ),
              ),
            ),
            if (isLocked)
              SvgPicture.asset('assets/sidebar/lock.svg', width: 16, height: 16),
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
            ? const Color(0xFFBBBBBB)
            : Colors.black87;

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
              ? AppTheme.primaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20,
              height: 20,
              colorFilter: isLocked
                  ? const ColorFilter.mode(Color(0xFFBBBBBB), BlendMode.srcIn)
                  : null,
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
              SvgPicture.asset('assets/sidebar/lock.svg', width: 16, height: 16),
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
