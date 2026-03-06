import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/category_filter.dart';
import '../../../shared/widgets/product_card.dart';
import '../models/event_service.dart';
import '../providers/shop_providers.dart';

class EventServicesPage extends ConsumerStatefulWidget {
  const EventServicesPage({super.key});

  @override
  ConsumerState<EventServicesPage> createState() => _EventServicesPageState();
}

class _EventServicesPageState extends ConsumerState<EventServicesPage> {
  String? _selectedCategory;

  static const _categories = [
    'Expo',
    'Forum',
    'Sponsors',
    'Promotional',
    'Print',
    'Transfer',
    'Tickets',
    'Flight',
    'Catering',
  ];

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final eventIdStr = routerState.pathParameters['id'] ?? '0';
    final eventId = int.tryParse(eventIdStr) ?? 0;
    final servicesAsync = ref.watch(eventServicesProvider(eventId));
    final cartAsync = ref.watch(cartProvider(eventId));
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Build a map of serviceId -> CartItem for quantity display
    final cartItems = cartAsync.whenOrNull(data: (c) => c.items) ?? [];
    final cartMap = <int, CartItem>{};
    for (final item in cartItems) {
      cartMap[item.serviceId] = item;
    }

    return EventSidebarLayout(
      title: 'Event Services',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + cart totals (always visible)
          _ServicesHeader(eventId: eventId),

          // Mobile: horizontal category chips
          if (isMobile) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryFilter(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Body: always show sidebar + filter pills + grid area
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (error, _) => _ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(eventServicesProvider(eventId)),
              ),
              data: (services) {
                final filtered = _filterServices(services);

                if (isMobile) {
                  if (filtered.isEmpty) {
                    return _EmptyGridMessage(
                      category: _selectedCategory,
                      onClearFilter: () =>
                          setState(() => _selectedCategory = null),
                    );
                  }
                  return _ServicesGrid(
                    services: filtered,
                    eventIdStr: eventIdStr,
                    cartMap: cartMap,
                    onAddToCart: (s) => _addToCart(eventId, s),
                    onIncrement: (s) => _incrementCart(eventId, s, cartMap),
                    onDecrement: (s) => _decrementCart(eventId, s, cartMap),
                    crossAxisCount: 2,
                  );
                }

                // Desktop: always show sidebar + pills + grid
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category sidebar (always visible)
                      _CategorySidebar(
                        categories: _categories,
                        selected: _selectedCategory,
                        onChanged: (cat) =>
                            setState(() => _selectedCategory = cat),
                      ),

                      const SizedBox(width: 16),

                      // Filter pills + grid
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FilterPillsRow(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: filtered.isEmpty
                                  ? _EmptyGridMessage(
                                      category: _selectedCategory,
                                      onClearFilter: () => setState(
                                        () => _selectedCategory = null,
                                      ),
                                    )
                                  : _ServicesGrid(
                                      services: filtered,
                                      eventIdStr: eventIdStr,
                                      cartMap: cartMap,
                                      onAddToCart: (s) => _addToCart(eventId, s),
                                      onIncrement: (s) =>
                                          _incrementCart(eventId, s, cartMap),
                                      onDecrement: (s) =>
                                          _decrementCart(eventId, s, cartMap),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<EventServiceItem> _filterServices(List<EventServiceItem> services) {
    if (_selectedCategory == null) return services;
    return services
        .where(
          (s) => s.category.toLowerCase() == _selectedCategory!.toLowerCase(),
        )
        .toList();
  }

  Future<void> _addToCart(int eventId, EventServiceItem service) async {
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.addToCart(eventId, service.id);
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${service.name} added to cart',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add to cart: $e',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _incrementCart(
    int eventId,
    EventServiceItem service,
    Map<int, CartItem> cartMap,
  ) async {
    final existing = cartMap[service.id];
    if (existing == null) {
      await _addToCart(eventId, service);
      return;
    }
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.updateCartItem(existing.id, existing.quantity + 1);
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update cart: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _decrementCart(
    int eventId,
    EventServiceItem service,
    Map<int, CartItem> cartMap,
  ) async {
    final existing = cartMap[service.id];
    if (existing == null) return;
    try {
      final shopService = ref.read(shopServiceProvider);
      if (existing.quantity <= 1) {
        await shopService.removeCartItem(existing.id);
      } else {
        await shopService.updateCartItem(existing.id, existing.quantity - 1);
      }
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update cart: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Header: "Event Services" title + cart summary (always visible)
// ---------------------------------------------------------------------------
class _ServicesHeader extends ConsumerWidget {
  final int eventId;

  const _ServicesHeader({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider(eventId));
    final totalTmt = cartAsync.whenOrNull(data: (c) => c.totalTmt) ?? 0;
    final totalUsd = cartAsync.whenOrNull(data: (c) => c.totalUsd) ?? 0;
    final itemCount = cartAsync.whenOrNull(data: (c) => c.itemCount) ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Event Services',
                style: GoogleFonts.montserrat(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '0';
                  context.go('/events/$eventIdStr/services/cart');
                },
                child: _CartSummary(
                  itemCount: itemCount,
                  totalTmt: totalTmt,
                  totalUsd: totalUsd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: const Color(0xFFCACACA)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart summary: icon + badge + totals
// ---------------------------------------------------------------------------
class _CartSummary extends StatelessWidget {
  final int itemCount;
  final double totalTmt;
  final double totalUsd;

  const _CartSummary({
    required this.itemCount,
    required this.totalTmt,
    required this.totalUsd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cart icon with badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              'assets/event_services/shopping-cart.png',
              width: 37,
              height: 37,
              color: Colors.black.withValues(alpha: 0.7),
            ),
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    itemCount > 9 ? '9+' : itemCount.toString(),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Totals
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_fmt(totalTmt)} TMT',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              width: 80,
              height: 0.5,
              color: AppTheme.primaryColor,
            ),
            Text(
              '${_fmt(totalUsd)} \$',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Category sidebar — flat, clean, no colored header (matches Figma)
// ---------------------------------------------------------------------------
class _CategorySidebar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategorySidebar({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 182,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Category" label row — blue background, white text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Image.asset('assets/event_services/category.png', width: 18, height: 18),
                const SizedBox(width: 8),
                Text(
                  'Category',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category list — clean, no shadow
          _CategoryRow(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final cat in categories)
            _CategoryRow(
              label: cat,
              isSelected: selected == cat,
              onTap: () => onChanged(cat),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single category row
// ---------------------------------------------------------------------------
class _CategoryRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter pills — gray borders (matches Figma)
// ---------------------------------------------------------------------------
class _FilterPillsRow extends StatelessWidget {
  const _FilterPillsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        _FilterPill(label: 'Price'),
        _FilterPill(label: 'Discount'),
        _FilterPill(label: 'Service Type'),
        _FilterPill(label: 'Currency'),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;

  const _FilterPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppTheme.primaryColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Services grid
// ---------------------------------------------------------------------------
class _ServicesGrid extends StatelessWidget {
  final List<EventServiceItem> services;
  final String eventIdStr;
  final Map<int, CartItem> cartMap;
  final ValueChanged<EventServiceItem> onAddToCart;
  final ValueChanged<EventServiceItem> onIncrement;
  final ValueChanged<EventServiceItem> onDecrement;
  final int? crossAxisCount;

  const _ServicesGrid({
    required this.services,
    required this.eventIdStr,
    required this.cartMap,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      gridDelegate: crossAxisCount != null
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount!,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 184 / 246,
            )
          : const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 184 / 246,
            ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final cartItem = cartMap[service.id];
        final qty = cartItem?.quantity ?? 0;

        return ProductCard(
          name: service.name,
          imageUrl: service.imageUrl,
          priceUsd: service.priceUsd,
          priceTmt: service.priceTmt,
          discountPercent: service.discountPercent,
          subtitle: service.subtitle,
          cartQuantity: qty,
          onTap: () => context.go('/events/$eventIdStr/services/${service.id}'),
          onAddToCart: () => onAddToCart(service),
          onIncrement: () => onIncrement(service),
          onDecrement: () => onDecrement(service),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty grid message (shown inside the grid area, not replacing layout)
// ---------------------------------------------------------------------------
class _EmptyGridMessage extends StatelessWidget {
  final String? category;
  final VoidCallback onClearFilter;

  const _EmptyGridMessage({
    required this.category,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category != null
                  ? 'No services in the "$category" category.'
                  : 'No services are available for this event.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (category != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onClearFilter,
                style: AppTheme.secondaryButtonStyle,
                child: const Text('Show All Services'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view with retry
// ---------------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: AppTheme.errorColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }
}
