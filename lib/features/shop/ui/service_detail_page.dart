import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
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

    final serviceAsync = ref.watch(
      serviceDetailProvider(int.tryParse(serviceId) ?? 0),
    );

    return EventSidebarLayout(
      title: 'Service Details',
      child: serviceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, _) => _DetailErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(
              serviceDetailProvider(int.tryParse(serviceId) ?? 0),
            );
          },
        ),
        data: (service) {
          return _ServiceDetailContent(
            service: service,
            eventId: eventId,
            eventIdStr: eventIdStr,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content — matches Figma layout
// ---------------------------------------------------------------------------
class _ServiceDetailContent extends ConsumerStatefulWidget {
  final EventServiceItem service;
  final int eventId;
  final String eventIdStr;

  const _ServiceDetailContent({
    required this.service,
    required this.eventId,
    required this.eventIdStr,
  });

  @override
  ConsumerState<_ServiceDetailContent> createState() =>
      _ServiceDetailContentState();
}

class _ServiceDetailContentState extends ConsumerState<_ServiceDetailContent> {
  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "Event Services" > service name + divider
        _DetailHeader(
          eventIdStr: widget.eventIdStr,
          serviceName: service.name,
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              16,
              isMobile ? 16 : 24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service title (large, centered)
                Center(
                  child: Text(
                    service.name,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 22 : 30,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Subtitle
                if (service.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      service.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Image + Price (left) | Description + Included/NotIncluded (right)
                if (isMobile)
                  _MobileBody(service: service)
                else
                  _DesktopBody(service: service),

                const SizedBox(height: 32),

                // Add to Cart button — centered, green, 47px
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 47,
                    child: ElevatedButton(
                      onPressed: _isAddingToCart ? null : _handleAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF519672),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: _isAddingToCart
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Image.asset(
                              'assets/event_services/event_detail/shopping-cart.png',
                              width: 30,
                              height: 30,
                              color: Colors.white,
                            ),
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

  Future<void> _handleAddToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      final shopService = ref.read(shopServiceProvider);
      final qty =
          widget.service.minOrder > 0 ? widget.service.minOrder : 1;
      await shopService.addToCart(
        widget.eventId,
        widget.service.id,
        quantity: qty,
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
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Header — "Event Services" > chevron > service name + divider
// ---------------------------------------------------------------------------
class _DetailHeader extends StatelessWidget {
  final String eventIdStr;
  final String serviceName;

  const _DetailHeader({
    required this.eventIdStr,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    context.go('/events/$eventIdStr/services'),
                child: Text(
                  'Event Services',
                  style: GoogleFonts.montserrat(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, size: 24, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  serviceName,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
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
// Desktop body — image+price left, description+lists right
// ---------------------------------------------------------------------------
class _DesktopBody extends StatelessWidget {
  final EventServiceItem service;

  const _DesktopBody({required this.service});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: image + price
        SizedBox(
          width: 272,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with border
              Container(
                width: 272,
                height: 264,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                clipBehavior: Clip.antiAlias,
                child: service.imageUrl != null
                    ? Image.network(
                        service.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),

              const SizedBox(height: 16),

              // Price — Inter Medium 50px
              Text(
                '${_fmt(service.priceUsd)} \$',
                style: GoogleFonts.inter(
                  fontSize: 50,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),

              // Minimum order
              if (service.minOrder > 1) ...[
                const SizedBox(height: 4),
                Text(
                  'Minimum order: ${service.minOrder} sq. m.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Right: description + included/not included
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              if (service.description != null &&
                  service.description!.isNotEmpty) ...[
                Text(
                  service.description!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 26 / 16,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Divider
              Container(height: 0.5, color: const Color(0xFFCACACA)),
              const SizedBox(height: 20),

              // Included + Not Included side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Included
                  if (service.included != null &&
                      service.included!.isNotEmpty)
                    Expanded(
                      child: _IncludedList(
                        title: 'Included',
                        items: service.included!
                            .map((e) => e.toString())
                            .toList(),
                      ),
                    ),

                  if (service.included != null &&
                      service.included!.isNotEmpty &&
                      service.notIncluded != null &&
                      service.notIncluded!.isNotEmpty)
                    const SizedBox(width: 40),

                  // Not Included
                  if (service.notIncluded != null &&
                      service.notIncluded!.isNotEmpty)
                    Expanded(
                      child: _IncludedList(
                        title: 'Not Included',
                        items: service.notIncluded!
                            .map((e) => e.toString())
                            .toList(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Image.asset(
          'assets/event_services/event_detail/event_detail.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Mobile body — stacked layout
// ---------------------------------------------------------------------------
class _MobileBody extends StatelessWidget {
  final EventServiceItem service;

  const _MobileBody({required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 272, maxHeight: 264),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 272 / 264,
              child: service.imageUrl != null
                  ? Image.network(
                      service.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Price
        Text(
          '${_fmt(service.priceUsd)} \$',
          style: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        if (service.minOrder > 1) ...[
          const SizedBox(height: 4),
          Text(
            'Minimum order: ${service.minOrder} sq. m.',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
          ),
        ],
        const SizedBox(height: 20),

        // Description
        if (service.description != null &&
            service.description!.isNotEmpty) ...[
          Text(
            service.description!,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black,
              height: 26 / 16,
            ),
          ),
          const SizedBox(height: 20),
        ],

        Container(height: 0.5, color: const Color(0xFFCACACA)),
        const SizedBox(height: 20),

        // Included
        if (service.included != null && service.included!.isNotEmpty) ...[
          _IncludedList(
            title: 'Included',
            items: service.included!.map((e) => e.toString()).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Not Included
        if (service.notIncluded != null &&
            service.notIncluded!.isNotEmpty)
          _IncludedList(
            title: 'Not Included',
            items:
                service.notIncluded!.map((e) => e.toString()).toList(),
          ),
      ],
    );
  }

  static Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Included / Not Included list with plus-circle icons
// ---------------------------------------------------------------------------
class _IncludedList extends StatelessWidget {
  final String title;
  final List<String> items;

  const _IncludedList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title — Inter SemiBold 20px
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 19,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
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
