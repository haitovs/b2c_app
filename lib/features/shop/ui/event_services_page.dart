import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/category_filter.dart';
import '../../../shared/widgets/product_card.dart';
import '../providers/shop_providers.dart';
import '../models/event_service.dart';

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
    final cartCount = ref.watch(cartBadgeCountProvider(eventId));

    return EventSidebarLayout(
      title: 'Event Services',
      actions: [
        _CartBadgeButton(
          count: cartCount,
          onPressed: () => context.go('/events/$eventIdStr/services/cart'),
        ),
      ],
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse Services',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${services.length} services available',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Category filter
              CategoryFilter(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),

              const SizedBox(height: 20),

              // Services grid or empty state
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyFilterView(
                        category: _selectedCategory,
                        onClearFilter: () {
                          setState(() => _selectedCategory = null);
                        },
                      )
                    : _ServicesGrid(
                        services: filtered,
                        eventId: eventId,
                        eventIdStr: eventIdStr,
                        onAddToCart: (service) =>
                            _addToCart(eventId, service),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<EventServiceItem> _filterServices(List<EventServiceItem> services) {
    if (_selectedCategory == null) return services;
    return services
        .where((s) =>
            s.category.toLowerCase() == _selectedCategory!.toLowerCase())
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
}

// ---------------------------------------------------------------------------
// Cart badge button for actions area
// ---------------------------------------------------------------------------
class _CartBadgeButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _CartBadgeButton({
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Shopping Cart',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: AppTheme.errorColor,
        child: const Icon(Icons.shopping_cart_outlined, size: 24),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Services grid
// ---------------------------------------------------------------------------
class _ServicesGrid extends StatelessWidget {
  final List<EventServiceItem> services;
  final int eventId;
  final String eventIdStr;
  final ValueChanged<EventServiceItem> onAddToCart;

  const _ServicesGrid({
    required this.services,
    required this.eventId,
    required this.eventIdStr,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 1 : 2;
    final childAspectRatio = screenWidth < 600 ? 0.85 : 0.78;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ProductCard(
          name: service.name,
          imageUrl: service.imageUrl,
          priceUsd: service.priceUsd,
          priceTmt: service.priceTmt,
          discountPercent: service.discountPercent,
          subtitle: service.subtitle,
          onTap: () => context.go(
            '/events/$eventIdStr/services/${service.id}',
          ),
          onAddToCart: () => onAddToCart(service),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty filter view
// ---------------------------------------------------------------------------
class _EmptyFilterView extends StatelessWidget {
  final String? category;
  final VoidCallback onClearFilter;

  const _EmptyFilterView({
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
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
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

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

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
