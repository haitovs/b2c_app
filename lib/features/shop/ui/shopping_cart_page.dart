import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/cart_summary_widget.dart';
import '../providers/shop_providers.dart';
import '../models/event_service.dart';

class ShoppingCartPage extends ConsumerStatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  ConsumerState<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends ConsumerState<ShoppingCartPage> {
  final _promocodeController = TextEditingController();
  bool _isApplyingPromocode = false;
  bool _isCheckingOut = false;
  String? _appliedPromocode;

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

    return EventSidebarLayout(
      title: 'Shopping Cart',
      child: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, _) => _CartErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(cartProvider(eventId)),
        ),
        data: (cart) {
          if (cart.items.isEmpty) {
            return _EmptyCartView(
              eventIdStr: eventIdStr,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 800;

              if (isDesktop) {
                return _DesktopCartLayout(
                  cart: cart,
                  eventId: eventId,
                  eventIdStr: eventIdStr,
                  promocodeController: _promocodeController,
                  isApplyingPromocode: _isApplyingPromocode,
                  isCheckingOut: _isCheckingOut,
                  appliedPromocode: _appliedPromocode,
                  onUpdateQuantity: (item, qty) =>
                      _updateQuantity(eventId, item, qty),
                  onRemoveItem: (item) => _removeItem(eventId, item),
                  onApplyPromocode: () => _applyPromocode(eventId),
                  onCheckout: () => _checkout(eventId, eventIdStr),
                );
              }

              return _MobileCartLayout(
                cart: cart,
                eventId: eventId,
                eventIdStr: eventIdStr,
                promocodeController: _promocodeController,
                isApplyingPromocode: _isApplyingPromocode,
                isCheckingOut: _isCheckingOut,
                appliedPromocode: _appliedPromocode,
                onUpdateQuantity: (item, qty) =>
                    _updateQuantity(eventId, item, qty),
                onRemoveItem: (item) => _removeItem(eventId, item),
                onApplyPromocode: () => _applyPromocode(eventId),
                onCheckout: () => _checkout(eventId, eventIdStr),
              );
            },
          );
        },
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update quantity: $e',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeItem(int eventId, CartItem item) async {
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.removeCartItem(item.id);
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.service?.name ?? 'Item'} removed from cart',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: Colors.grey.shade700,
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
              'Failed to remove item: $e',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _applyPromocode(int eventId) async {
    final code = _promocodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingPromocode = true);
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.applyPromocode(eventId, code);
      ref.invalidate(cartProvider(eventId));
      setState(() => _appliedPromocode = code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promocode "$code" applied successfully',
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
              'Invalid promocode: $e',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplyingPromocode = false);
      }
    }
  }

  Future<void> _checkout(int eventId, String eventIdStr) async {
    setState(() => _isCheckingOut = true);
    try {
      final shopService = ref.read(shopServiceProvider);
      await shopService.checkout(eventId, promocode: _appliedPromocode);
      ref.invalidate(cartProvider(eventId));
      ref.invalidate(cartBadgeCountProvider(eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed successfully!',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        context.go('/events/$eventIdStr/services');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Checkout failed: $e',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Desktop layout — two columns
// ---------------------------------------------------------------------------
class _DesktopCartLayout extends StatelessWidget {
  final CartSummary cart;
  final int eventId;
  final String eventIdStr;
  final TextEditingController promocodeController;
  final bool isApplyingPromocode;
  final bool isCheckingOut;
  final String? appliedPromocode;
  final void Function(CartItem item, int qty) onUpdateQuantity;
  final void Function(CartItem item) onRemoveItem;
  final VoidCallback onApplyPromocode;
  final VoidCallback onCheckout;

  const _DesktopCartLayout({
    required this.cart,
    required this.eventId,
    required this.eventIdStr,
    required this.promocodeController,
    required this.isApplyingPromocode,
    required this.isCheckingOut,
    required this.appliedPromocode,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onApplyPromocode,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — Cart items
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CartHeader(itemCount: cart.itemCount),
                const SizedBox(height: 16),
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartItemCard(
                      item: item,
                      onUpdateQuantity: (qty) => onUpdateQuantity(item, qty),
                      onRemove: () => onRemoveItem(item),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Right — Summary
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _PromocodeInput(
                  controller: promocodeController,
                  isApplying: isApplyingPromocode,
                  appliedCode: appliedPromocode,
                  onApply: onApplyPromocode,
                ),
                const SizedBox(height: 16),
                CartSummaryWidget(
                  totalUsd: cart.totalUsd,
                  totalTmt: cart.totalTmt,
                  discountUsd: cart.discountUsd,
                  discountTmt: cart.discountTmt,
                  itemCount: cart.itemCount,
                  onCheckout: isCheckingOut ? null : onCheckout,
                ),
                if (isCheckingOut) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout — single column
// ---------------------------------------------------------------------------
class _MobileCartLayout extends StatelessWidget {
  final CartSummary cart;
  final int eventId;
  final String eventIdStr;
  final TextEditingController promocodeController;
  final bool isApplyingPromocode;
  final bool isCheckingOut;
  final String? appliedPromocode;
  final void Function(CartItem item, int qty) onUpdateQuantity;
  final void Function(CartItem item) onRemoveItem;
  final VoidCallback onApplyPromocode;
  final VoidCallback onCheckout;

  const _MobileCartLayout({
    required this.cart,
    required this.eventId,
    required this.eventIdStr,
    required this.promocodeController,
    required this.isApplyingPromocode,
    required this.isCheckingOut,
    required this.appliedPromocode,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onApplyPromocode,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CartHeader(itemCount: cart.itemCount),
          const SizedBox(height: 16),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartItemCard(
                item: item,
                onUpdateQuantity: (qty) => onUpdateQuantity(item, qty),
                onRemove: () => onRemoveItem(item),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PromocodeInput(
            controller: promocodeController,
            isApplying: isApplyingPromocode,
            appliedCode: appliedPromocode,
            onApply: onApplyPromocode,
          ),
          const SizedBox(height: 16),
          CartSummaryWidget(
            totalUsd: cart.totalUsd,
            totalTmt: cart.totalTmt,
            discountUsd: cart.discountUsd,
            discountTmt: cart.discountTmt,
            itemCount: cart.itemCount,
            onCheckout: isCheckingOut ? null : onCheckout,
          ),
          if (isCheckingOut) ...[
            const SizedBox(height: 12),
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart header
// ---------------------------------------------------------------------------
class _CartHeader extends StatelessWidget {
  final int itemCount;

  const _CartHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Cart',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual cart item card
// ---------------------------------------------------------------------------
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onUpdateQuantity;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = item.service?.name ?? 'Service #${item.serviceId}';
    final subtotalUsd = item.unitPriceUsd * item.quantity;
    final subtotalTmt = item.unitPriceTmt * item.quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.service?.imageUrl != null
                  ? Image.network(
                      item.service!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
                    )
                  : _thumbnailPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  serviceName,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Unit price
                Text(
                  '\$${_fmt(item.unitPriceUsd)} / ${_fmt(item.unitPriceTmt)} TMT each',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),

                // Quantity controls and subtotal
                Row(
                  children: [
                    // Quantity selector
                    _CartQuantitySelector(
                      quantity: item.quantity,
                      onDecrement: item.quantity > 1
                          ? () => onUpdateQuantity(item.quantity - 1)
                          : null,
                      onIncrement: () =>
                          onUpdateQuantity(item.quantity + 1),
                    ),
                    const Spacer(),

                    // Subtotal
                    Text(
                      '\$${_fmt(subtotalUsd)} / ${_fmt(subtotalTmt)} TMT',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove',
            icon: Icon(
              Icons.delete_outline,
              size: 22,
              color: AppTheme.errorColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  static String _fmt(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

// ---------------------------------------------------------------------------
// Cart quantity selector (compact)
// ---------------------------------------------------------------------------
class _CartQuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _CartQuantitySelector({
    required this.quantity,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.remove,
                size: 16,
                color: onDecrement != null
                    ? Colors.black87
                    : Colors.grey.shade400,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(6),
            ),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add, size: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promocode input
// ---------------------------------------------------------------------------
class _PromocodeInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isApplying;
  final String? appliedCode;
  final VoidCallback onApply;

  const _PromocodeInput({
    required this.controller,
    required this.isApplying,
    required this.appliedCode,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Promocode',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter promocode',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isApplying ? null : onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isApplying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
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
            ],
          ),
          if (appliedCode != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Code "$appliedCode" applied',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty cart state
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
            ElevatedButton.icon(
              onPressed: () => context.go('/events/$eventIdStr/services'),
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              label: Text(
                'Browse Services',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart error view with retry
// ---------------------------------------------------------------------------
class _CartErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CartErrorView({
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
