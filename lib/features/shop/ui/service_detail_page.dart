import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/breadcrumb_nav.dart';
import '../providers/shop_providers.dart';
import '../models/event_service.dart';

class ServiceDetailPage extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = GoRouterState.of(context);
    final eventIdStr = routerState.pathParameters['id'] ?? '0';
    final eventId = int.tryParse(eventIdStr) ?? 0;

    return EventSidebarLayout(
      title: 'Service Details',
      child: FutureBuilder<EventServiceItem>(
        future: ref.read(shopServiceProvider).getServiceDetail(
              int.tryParse(serviceId) ?? 0,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return _DetailErrorView(
              message: snapshot.error.toString(),
              onRetry: () {
                // Force rebuild by navigating to the same page
                context.go('/events/$eventIdStr/services/$serviceId');
              },
            );
          }

          final service = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                BreadcrumbNav(
                  items: [
                    BreadcrumbItem(
                      label: 'Services',
                      path: '/events/$eventIdStr/services',
                    ),
                    BreadcrumbItem(label: service.name),
                  ],
                ),
                const SizedBox(height: 24),

                // Content — responsive layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 800) {
                      return _DesktopLayout(
                        service: service,
                        eventId: eventId,
                        eventIdStr: eventIdStr,
                      );
                    }
                    return _MobileLayout(
                      service: service,
                      eventId: eventId,
                      eventIdStr: eventIdStr,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout — image left, details right
// ---------------------------------------------------------------------------
class _DesktopLayout extends StatelessWidget {
  final EventServiceItem service;
  final int eventId;
  final String eventIdStr;

  const _DesktopLayout({
    required this.service,
    required this.eventId,
    required this.eventIdStr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Expanded(
          flex: 5,
          child: _ServiceImage(imageUrl: service.imageUrl),
        ),
        const SizedBox(width: 32),

        // Details
        Expanded(
          flex: 5,
          child: _ServiceDetails(
            service: service,
            eventId: eventId,
            eventIdStr: eventIdStr,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout — stacked
// ---------------------------------------------------------------------------
class _MobileLayout extends StatelessWidget {
  final EventServiceItem service;
  final int eventId;
  final String eventIdStr;

  const _MobileLayout({
    required this.service,
    required this.eventId,
    required this.eventIdStr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ServiceImage(imageUrl: service.imageUrl),
        const SizedBox(height: 24),
        _ServiceDetails(
          service: service,
          eventId: eventId,
          eventIdStr: eventIdStr,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Service image with discount badge
// ---------------------------------------------------------------------------
class _ServiceImage extends StatelessWidget {
  final String? imageUrl;

  const _ServiceImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Service details section (name, price, description, included lists, add to cart)
// ---------------------------------------------------------------------------
class _ServiceDetails extends ConsumerStatefulWidget {
  final EventServiceItem service;
  final int eventId;
  final String eventIdStr;

  const _ServiceDetails({
    required this.service,
    required this.eventId,
    required this.eventIdStr,
  });

  @override
  ConsumerState<_ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends ConsumerState<_ServiceDetails> {
  int _quantity = 1;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.service.minOrder > 0 ? widget.service.minOrder : 1;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final hasDiscount = service.discountPercent > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            service.category.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Name
        Text(
          service.name,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),

        // Subtitle
        if (service.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            service.subtitle!,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Price row with optional discount
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '\$${_formatNumber(service.priceUsd)} / ${_formatNumber(service.priceTmt)} TMT',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${service.discountPercent.round()}% OFF',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),

        if (service.minOrder > 1) ...[
          const SizedBox(height: 8),
          Text(
            'Minimum order: ${service.minOrder}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Description
        if (service.description != null && service.description!.isNotEmpty) ...[
          Text(
            'Description',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service.description!,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Included list
        if (service.included != null && service.included!.isNotEmpty) ...[
          _ChecklistSection(
            title: 'Included',
            items: service.included!.map((e) => e.toString()).toList(),
            icon: Icons.check_circle,
            iconColor: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
        ],

        // Not included list
        if (service.notIncluded != null &&
            service.notIncluded!.isNotEmpty) ...[
          _ChecklistSection(
            title: 'Not Included',
            items: service.notIncluded!.map((e) => e.toString()).toList(),
            icon: Icons.cancel,
            iconColor: AppTheme.errorColor,
          ),
          const SizedBox(height: 24),
        ],

        // Divider
        Divider(color: Colors.grey.shade200, height: 1),
        const SizedBox(height: 24),

        // Quantity selector + Add to Cart
        Row(
          children: [
            // Quantity selector
            _QuantitySelector(
              quantity: _quantity,
              minQuantity: service.minOrder > 0 ? service.minOrder : 1,
              onChanged: (q) => setState(() => _quantity = q),
            ),
            const SizedBox(width: 16),

            // Add to Cart button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isAddingToCart ? null : _handleAddToCart,
                icon: _isAddingToCart
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(
                  _isAddingToCart ? 'Adding...' : 'Add to Cart',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleAddToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.addToCart(
        widget.eventId,
        widget.service.id,
        quantity: _quantity,
      );
      ref.invalidate(cartProvider(widget.eventId));
      ref.invalidate(cartBadgeCountProvider(widget.eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.service.name} added to cart',
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
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  static String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

// ---------------------------------------------------------------------------
// Quantity selector
// ---------------------------------------------------------------------------
class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int minQuantity;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.quantity,
    required this.minQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            enabled: quantity > minQuantity,
            onPressed: () => onChanged(quantity - 1),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            enabled: true,
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checklist section (Included / Not Included)
// ---------------------------------------------------------------------------
class _ChecklistSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  const _ChecklistSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error view with retry
// ---------------------------------------------------------------------------
class _DetailErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorView({
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
              'Could not load service',
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
