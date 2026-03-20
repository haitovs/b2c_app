import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/app_checkbox.dart';
import '../../../shared/widgets/product_card.dart';
import '../models/event_service.dart';
import '../providers/shop_providers.dart';

class EventServicesPage extends ConsumerStatefulWidget {
  const EventServicesPage({super.key});

  @override
  ConsumerState<EventServicesPage> createState() => _EventServicesPageState();
}

class _EventServicesPageState extends ConsumerState<EventServicesPage> {
  final Set<String> _selectedCategories = {};

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

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + cart totals (always visible)
          _ServicesHeader(eventId: eventId),

          // Mobile: Category button + Filter icon
          if (isMobile) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Category button
                  GestureDetector(
                    onTap: () => _showCategoryDrawer(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_view_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Category',
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
                  const Spacer(),
                  // Filter icon
                  GestureDetector(
                    onTap: () => _showFilterDrawer(context),
                    child: Icon(
                      Icons.tune,
                      size: 24,
                      color: Colors.black54,
                    ),
                  ),
                ],
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
                      categories: _selectedCategories,
                      onClearFilter: () =>
                          setState(() => _selectedCategories.clear()),
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
                        selected: _selectedCategories,
                        onToggle: (cat) => setState(() {
                          if (_selectedCategories.contains(cat)) {
                            _selectedCategories.remove(cat);
                          } else {
                            _selectedCategories.add(cat);
                          }
                        }),
                        onClearAll: () =>
                            setState(() => _selectedCategories.clear()),
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
                                      categories: _selectedCategories,
                                      onClearFilter: () => setState(
                                        () => _selectedCategories.clear(),
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
      );
  }

  void _showCategoryDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MobileCategoryDrawer(
        categories: _categories,
        selected: _selectedCategories,
        onToggle: (cat) {
          setState(() {
            if (_selectedCategories.contains(cat)) {
              _selectedCategories.remove(cat);
            } else {
              _selectedCategories.add(cat);
            }
          });
        },
        onClearAll: () {
          setState(() => _selectedCategories.clear());
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showFilterDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _MobileFilterDrawer(),
    );
  }

  List<EventServiceItem> _filterServices(List<EventServiceItem> services) {
    if (_selectedCategories.isEmpty) return services;
    final lowerSelected =
        _selectedCategories.map((c) => c.toLowerCase()).toSet();
    return services
        .where((s) => lowerSelected.contains(s.category.toLowerCase()))
        .toList();
  }

  Future<void> _addToCart(int eventId, EventServiceItem service) async {
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.addToCart(eventId, service.id);
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
      if (mounted) {
        AppSnackBar.showSuccess(context, '${service.name} added to cart');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to add to cart: $e');
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
        AppSnackBar.showError(context, 'Failed to update cart: $e');
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
        AppSnackBar.showError(context, 'Failed to update cart: $e');
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Event Services',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 22 : 30,
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
    final isMobile = MediaQuery.of(context).size.width < 600;

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
        if (!isMobile) ...[
          const SizedBox(width: 16),
          // Totals (desktop only)
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
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClearAll;

  const _CategorySidebar({
    required this.categories,
    required this.selected,
    required this.onToggle,
    required this.onClearAll,
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
          // "All" clears selection
          _CategoryRow(
            label: 'All',
            isSelected: selected.isEmpty,
            onTap: onClearAll,
          ),
          for (final cat in categories)
            _CategoryRow(
              label: cat,
              isSelected: selected.contains(cat),
              onTap: () => onToggle(cat),
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
      addAutomaticKeepAlives: false,
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

        return StaggeredFadeIn(
          index: index,
          child: ProductCard(
            name: service.name,
            imageUrl: service.imageUrl,
            price: service.price,
            currency: service.currency,
            discountPercent: service.discountPercent,
            subtitle: service.subtitle,
            cartQuantity: qty,
            onTap: () => context.go('/events/$eventIdStr/services/${service.id}'),
            onAddToCart: () => onAddToCart(service),
            onIncrement: () => onIncrement(service),
            onDecrement: () => onDecrement(service),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty grid message (shown inside the grid area, not replacing layout)
// ---------------------------------------------------------------------------
class _EmptyGridMessage extends StatelessWidget {
  final Set<String> categories;
  final VoidCallback onClearFilter;

  const _EmptyGridMessage({
    required this.categories,
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
              categories.isNotEmpty
                  ? 'No services in the selected categories.'
                  : 'No services are available for this event.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (categories.isNotEmpty) ...[
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
// Mobile Category Drawer
// ---------------------------------------------------------------------------
class _MobileCategoryDrawer extends StatelessWidget {
  final List<String> categories;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClearAll;

  const _MobileCategoryDrawer({
    required this.categories,
    required this.selected,
    required this.onToggle,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grid_view_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close,
                          size: 22, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Category list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    AppCheckboxRow(
                      label: 'All',
                      isSelected: selected.isEmpty,
                      onTap: onClearAll,
                    ),
                    for (final cat in categories)
                      AppCheckboxRow(
                        label: cat,
                        isSelected: selected.contains(cat),
                        onTap: () => onToggle(cat),
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

// ---------------------------------------------------------------------------
// Mobile Filter Drawer
// ---------------------------------------------------------------------------
class _MobileFilterDrawer extends StatelessWidget {
  const _MobileFilterDrawer();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close,
                          size: 22, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Filter sections
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterSection(
                      title: 'Price',
                      options: ['Low to High', 'High to Low', 'Premium'],
                    ),
                    _FilterSection(
                      title: 'Service Type',
                      options: [
                        'One-time service',
                        'Per person',
                        'Per booth',
                        'Daily rental',
                      ],
                    ),
                    _FilterSection(
                      title: 'Discount',
                      options: [
                        'On Sale',
                        'Early Bird',
                        'Per booth',
                        'Package Included',
                      ],
                    ),
                    _FilterSection(
                      title: 'Currency',
                      options: ['All', 'USD', 'TMT'],
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

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;

  const _FilterSection({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, size: 22, color: Colors.black54),
          ],
        ),
        const Divider(color: Color(0xFFCACACA)),
        ...options.map(
          (opt) => AppCheckboxRow(
            label: opt,
            isSelected: false,
            onTap: () {},
          ),
        ),
      ],
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
