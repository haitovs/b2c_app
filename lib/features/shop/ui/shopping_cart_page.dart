import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../providers/shop_providers.dart';
import '../models/event_service.dart';

class ShoppingCartPage extends ConsumerStatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  ConsumerState<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends ConsumerState<ShoppingCartPage> {
  final _promocodeController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _promocodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final eventIdStr = routerState.pathParameters['id'] ?? '0';
    final eventId = int.tryParse(eventIdStr) ?? 0;
    final cartAsync = ref.watch(cartProvider(eventId));

    return cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, _) => _CartErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(cartProvider(eventId)),
        ),
        data: (cart) {
          if (cart.items.isEmpty) {
            return _EmptyCartView(eventIdStr: eventIdStr);
          }
          return _CartContent(
            cart: cart,
            eventId: eventId,
            eventIdStr: eventIdStr,
            promocodeController: _promocodeController,
            isCheckingOut: _isCheckingOut,
            onRemoveItem: (item) => _removeItem(eventId, item),
            onRemoveAll: () => _removeAll(eventId, cart),
            onUpdateQuantity: (item, qty) =>
                _updateQuantity(eventId, item, qty),
            onCheckout: () => _checkout(eventId, eventIdStr),
          );
        },
      );
  }

  Future<void> _updateQuantity(
      int eventId, CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.updateCartItem(item.id, newQuantity);
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to update quantity: $e');
      }
    }
  }

  Future<void> _removeItem(int eventId, CartItem item) async {
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.removeCartItem(item.id);
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to remove item: $e');
      }
    }
  }

  Future<void> _removeAll(int eventId, CartSummary cart) async {
    try {
      final shopService = ref.read(shopServiceProvider);
      for (final item in cart.items) {
        await shopService.removeCartItem(item.id);
      }
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to clear cart: $e');
      }
    }
  }

  Future<void> _checkout(int eventId, String eventIdStr) async {
    setState(() => _isCheckingOut = true);
    try {
      final shopService = ref.read(shopServiceProvider);
      final code = _promocodeController.text.trim();
      await shopService.checkout(
        eventId,
        promocode: code.isNotEmpty ? code : null,
      );
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
      ref.invalidate(purchaseStatusProvider(eventId));
      ref.invalidate(ordersProvider(eventId));
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Order placed successfully!');
        context.go('/events/$eventIdStr/services');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Checkout failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Cart content — header + grid of cards (left) + summary (right)
// ---------------------------------------------------------------------------
class _CartContent extends StatelessWidget {
  final CartSummary cart;
  final int eventId;
  final String eventIdStr;
  final TextEditingController promocodeController;
  final bool isCheckingOut;
  final void Function(CartItem) onRemoveItem;
  final VoidCallback onRemoveAll;
  final void Function(CartItem, int) onUpdateQuantity;
  final VoidCallback onCheckout;

  const _CartContent({
    required this.cart,
    required this.eventId,
    required this.eventIdStr,
    required this.promocodeController,
    required this.isCheckingOut,
    required this.onRemoveItem,
    required this.onRemoveAll,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: breadcrumb + Delete all
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () =>
                                context.go('/events/$eventIdStr/services'),
                            child: Text(
                              'Event Services',
                              style: GoogleFonts.montserrat(
                                fontSize: isMobile ? 20 : 30,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.chevron_right,
                              size: isMobile ? 20 : 24,
                              color: Colors.black54),
                        ),
                        Text(
                          'Shopping Cart',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 14 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Delete all row
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onRemoveAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 16, color: AppTheme.errorColor),
                      const SizedBox(width: 4),
                      Text(
                        'Delete all',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 0.5, color: const Color(0xFFCACACA)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Body
        Expanded(
          child: isMobile
              ? _MobileCartBody(
                  cart: cart,
                  eventId: eventId,
                  eventIdStr: eventIdStr,
                  promocodeController: promocodeController,
                  isCheckingOut: isCheckingOut,
                  onRemoveItem: onRemoveItem,
                  onUpdateQuantity: onUpdateQuantity,
                  onCheckout: onCheckout,
                )
              : _DesktopCartBody(
                  cart: cart,
                  eventId: eventId,
                  eventIdStr: eventIdStr,
                  promocodeController: promocodeController,
                  isCheckingOut: isCheckingOut,
                  onRemoveItem: onRemoveItem,
                  onUpdateQuantity: onUpdateQuantity,
                  onCheckout: onCheckout,
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop body — card grid (left) + summary panel (right)
// ---------------------------------------------------------------------------
class _DesktopCartBody extends StatelessWidget {
  final CartSummary cart;
  final int eventId;
  final String eventIdStr;
  final TextEditingController promocodeController;
  final bool isCheckingOut;
  final void Function(CartItem) onRemoveItem;
  final void Function(CartItem, int) onUpdateQuantity;
  final VoidCallback onCheckout;

  const _DesktopCartBody({
    required this.cart,
    required this.eventId,
    required this.eventIdStr,
    required this.promocodeController,
    required this.isCheckingOut,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — product card grid
          Expanded(
            flex: 6,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 184 / 246,
              ),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return _CartProductCard(
                  item: item,
                  onRemove: () => onRemoveItem(item),
                  onIncrement: () =>
                      onUpdateQuantity(item, item.quantity + 1),
                  onDecrement: item.quantity > 1
                      ? () => onUpdateQuantity(item, item.quantity - 1)
                      : null,
                  onTap: () => context.go(
                    '/events/$eventIdStr/services/${item.serviceId}',
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 24),

          // Right — cart summary + promocode
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _CartSummaryPanel(cart: cart),
                const SizedBox(height: 24),
                _PromocodeSection(
                  controller: promocodeController,
                  isCheckingOut: isCheckingOut,
                  onSend: onCheckout,
                  eventId: eventId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile body — stacked
// ---------------------------------------------------------------------------
class _MobileCartBody extends StatelessWidget {
  final CartSummary cart;
  final int eventId;
  final String eventIdStr;
  final TextEditingController promocodeController;
  final bool isCheckingOut;
  final void Function(CartItem) onRemoveItem;
  final void Function(CartItem, int) onUpdateQuantity;
  final VoidCallback onCheckout;

  const _MobileCartBody({
    required this.cart,
    required this.eventId,
    required this.eventIdStr,
    required this.promocodeController,
    required this.isCheckingOut,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal cart item cards
          ...cart.items.map((item) {
            return _CartHorizontalCard(
              item: item,
              onRemove: () => onRemoveItem(item),
              onIncrement: () => onUpdateQuantity(item, item.quantity + 1),
              onDecrement: item.quantity > 1
                  ? () => onUpdateQuantity(item, item.quantity - 1)
                  : null,
              onTap: () => context.go(
                '/events/$eventIdStr/services/${item.serviceId}',
              ),
            );
          }),
          const SizedBox(height: 24),
          _CartSummaryPanel(cart: cart),
          const SizedBox(height: 24),
          _PromocodeSection(
            controller: promocodeController,
            isCheckingOut: isCheckingOut,
            onSend: onCheckout,
            eventId: eventId,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart product card — same style as product card + red trash icon
// ---------------------------------------------------------------------------
class _CartProductCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onTap;

  const _CartProductCard({
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    this.onDecrement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = item.service;
    final name = service?.name ?? 'Service #${item.serviceId}';
    final hasDiscount = (service?.discountPercent ?? 0) > 0;
    final originalPrice = service?.price ?? item.unitPrice;
    final discountedPrice = hasDiscount
        ? originalPrice * (1 - (service!.discountPercent / 100))
        : originalPrice;
    final qty = item.quantity;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFFDDDDDD),
                          width: 0.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: service?.imageUrl != null
                          ? Image.network(
                              service!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Name
                  SizedBox(
                    height: 38,
                    child: Text(
                      name,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Price row
                  SizedBox(
                    height: 20,
                    child: Row(
                      children: [
                        Text(
                          '${_fmt(discountedPrice)} ${item.currency == "TMT" ? "TMT" : "\$"}',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${_fmt(originalPrice)} ${item.currency == "TMT" ? "TMT" : "\$"}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '-${service!.discountPercent.round()}%',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Cart button or quantity controls
                  SizedBox(
                    height: 29,
                    child: qty > 0
                        ? _QuantityBar(
                            quantity: qty,
                            onIncrement: onIncrement,
                            onDecrement: onDecrement,
                          )
                        : _AddToCartButton(onPressed: onIncrement),
                  ),
                ],
              ),
            ),
          ),

          // Red trash icon — top right
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Horizontal cart card for mobile — image left, info right
// ---------------------------------------------------------------------------
class _CartHorizontalCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onTap;

  const _CartHorizontalCard({
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    this.onDecrement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = item.service;
    final name = service?.name ?? 'Service #${item.serviceId}';
    final hasDiscount = (service?.discountPercent ?? 0) > 0;
    final originalPrice = service?.price ?? item.unitPrice;
    final discountedPrice = hasDiscount
        ? originalPrice * (1 - (service!.discountPercent / 100))
        : originalPrice;
    final qty = item.quantity;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              child: SizedBox(
                width: 100,
                height: 110,
                child: service?.imageUrl != null
                    ? Image.network(
                        service!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      name,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price row
                    Row(
                      children: [
                        Text(
                          '${_fmt(discountedPrice)} ${item.currency == "TMT" ? "TMT" : "\$"}',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${_fmt(originalPrice)} ${item.currency == "TMT" ? "TMT" : "\$"}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '-${service!.discountPercent.round()}%',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quantity bar
                    SizedBox(
                      height: 29,
                      child: _QuantityBar(
                        quantity: qty,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child:
            Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Quantity bar (green: – count +)
// ---------------------------------------------------------------------------
class _QuantityBar extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  const _QuantityBar({
    required this.quantity,
    required this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF519672),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onDecrement,
              child: Center(
                child: Text(
                  '–',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Text(
            quantity.toString(),
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onIncrement,
              child: Center(
                child: Text(
                  '+',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add to cart button (green)
// ---------------------------------------------------------------------------
class _AddToCartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddToCartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 29,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF519672),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          elevation: 0,
        ),
        child: Image.asset(
          'assets/event_services/shopping-cart.png',
          width: 16,
          height: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart summary panel — Price, Discount, Total
// ---------------------------------------------------------------------------
class _CartSummaryPanel extends StatelessWidget {
  final CartSummary cart;

  const _CartSummaryPanel({required this.cart});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMobile ? AppTheme.primaryColor : const Color(0xFFDDDDDD),
          width: isMobile ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cart',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (cart.totalUsd + cart.discountUsd > 0)
            _summaryRow('Price (USD):', '\$${_fmt(cart.totalUsd + cart.discountUsd)}'),
          if (cart.totalTmt + cart.discountTmt > 0) ...[
            const SizedBox(height: 4),
            _summaryRow('Price (TMT):', '${_fmt(cart.totalTmt + cart.discountTmt)} TMT'),
          ],
          const SizedBox(height: 8),
          if (cart.discountUsd > 0) ...[
            _summaryRow('Discount (USD):', '- \$${_fmt(cart.discountUsd)}'),
            const SizedBox(height: 4),
          ],
          if (cart.discountTmt > 0) ...[
            _summaryRow('Discount (TMT):', '- ${_fmt(cart.discountTmt)} TMT'),
            const SizedBox(height: 4),
          ],
          const Divider(height: 1, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 12),
          if (cart.totalUsd > 0)
            _summaryRow(
              'Total (USD):',
              '\$${_fmt(cart.totalUsd)}',
              bold: true,
            ),
          if (cart.totalTmt > 0) ...[
            if (cart.totalUsd > 0) const SizedBox(height: 4),
            _summaryRow(
              'Total (TMT):',
              '${_fmt(cart.totalTmt)} TMT',
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Promocode section + Apply button + Send button
// ---------------------------------------------------------------------------
class _PromocodeSection extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final bool isCheckingOut;
  final VoidCallback onSend;
  final int eventId;

  const _PromocodeSection({
    required this.controller,
    required this.isCheckingOut,
    required this.onSend,
    required this.eventId,
  });

  @override
  ConsumerState<_PromocodeSection> createState() => _PromocodeSectionState();
}

class _PromocodeSectionState extends ConsumerState<_PromocodeSection> {
  bool _isApplying = false;
  String? _promoMessage;
  bool? _promoValid;

  Future<void> _applyPromocode() async {
    final code = widget.controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _promoMessage = 'Please enter a promocode';
        _promoValid = false;
      });
      return;
    }

    setState(() => _isApplying = true);
    try {
      final shopService = ref.read(shopServiceProvider);
      final result = await shopService.applyPromocode(widget.eventId, code);
      if (!mounted) return;
      final valid = result['valid'] == true;
      final message = result['message'] as String? ?? '';
      final discountType = result['discount_type'] as String?;
      final discountValue = result['discount_value'];

      String displayMsg = message;
      if (valid && discountType != null && discountValue != null) {
        final dv = (discountValue is num) ? discountValue : 0;
        if (discountType == 'PERCENTAGE') {
          displayMsg = '$message (${dv.toStringAsFixed(0)}% off)';
        } else if (discountType == 'FIXED_USD') {
          displayMsg = '$message (\$${dv.toStringAsFixed(0)} off)';
        } else if (discountType == 'FIXED_TMT') {
          displayMsg = '$message (${dv.toStringAsFixed(0)} TMT off)';
        }
      }

      setState(() {
        _promoValid = valid;
        _promoMessage = displayMsg;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Failed to verify promocode';
      setState(() {
        _promoValid = false;
        _promoMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promocode:',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Apply your discount code below to save on your booking.',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Promocode input + Apply button
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFCBCBCB)),
                ),
                child: TextField(
                  controller: widget.controller,
                  style: GoogleFonts.inter(fontSize: 14),
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: (_) {
                    // Reset status when user edits the code
                    if (_promoMessage != null) {
                      setState(() {
                        _promoMessage = null;
                        _promoValid = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Enter code',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isApplying ? null : _applyPromocode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF519672),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isApplying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Apply',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
        // Promo validation result
        if (_promoMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _promoValid == true ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: _promoValid == true
                    ? const Color(0xFF519672)
                    : AppTheme.errorColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _promoMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _promoValid == true
                        ? const Color(0xFF519672)
                        : AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Checkout button
        SizedBox(
          width: double.infinity,
          height: 47,
          child: ElevatedButton(
            onPressed: widget.isCheckingOut ? null : widget.onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 0,
            ),
            child: widget.isCheckingOut
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Send',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty cart
// ---------------------------------------------------------------------------
class _EmptyCartView extends StatelessWidget {
  final String eventIdStr;

  const _EmptyCartView({required this.eventIdStr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse available services and add them to your cart.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/events/$eventIdStr/services'),
              style: AppTheme.primaryButtonStyle,
              child: const Text('Browse Services'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------
class _CartErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CartErrorView({required this.message, required this.onRetry});

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
              'Could not load cart',
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
