import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Product card — pixel-matched to Figma (184x246 proportions).
/// Card: 5px radius, shadow 0 1 5 rgba(0,0,0,0.25)
/// Image border: 0.5px #DDD, 5px radius, 10px inset
/// Name: Roboto 16px Regular
/// Price: Roboto 16px SemiBold + discount badge
/// Cart button: #519672, 5px radius, 29px height
class ProductCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double price;
  final String currency; // USD or TMT
  final double discountPercent;
  final String? subtitle;
  final int cartQuantity;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ProductCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.currency,
    this.discountPercent = 0,
    this.subtitle,
    this.cartQuantity = 0,
    this.onTap,
    this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountPercent > 0;

    return RepaintBoundary(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image border box — expands to fill available space
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              cacheWidth: 300,
                              errorBuilder: (_, __, ___) => _placeholder(),
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded || frame != null) {
                                  return child;
                                }
                                return _placeholder();
                              },
                            )
                          : _placeholder(),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Name — Roboto Regular 16px
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

                const SizedBox(height: 4),

                // Price row — single currency
                _PriceRow(
                  currentPrice: hasDiscount
                      ? price * (1 - discountPercent / 100)
                      : price,
                  currency: currency,
                  originalPrice: hasDiscount ? price : null,
                  discountPercent: hasDiscount ? discountPercent : null,
                ),

                const SizedBox(height: 8),

                // Cart button or quantity controls — 29px height
                SizedBox(
                  height: 29,
                  child: cartQuantity > 0
                      ? _QuantityControls(
                          quantity: cartQuantity,
                          onIncrement: onIncrement,
                          onDecrement: onDecrement,
                        )
                      : _CartButton(onPressed: onAddToCart),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price row: single currency + optional strikethrough + discount badge
// ---------------------------------------------------------------------------
class _PriceRow extends StatelessWidget {
  final double currentPrice;
  final String currency;
  final double? originalPrice;
  final double? discountPercent;

  const _PriceRow({
    required this.currentPrice,
    required this.currency,
    this.originalPrice,
    this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final suffix = currency == 'TMT' ? ' TMT' : ' \$';

    return Row(
      children: [
        Text(
          '${_fmt(currentPrice)}$suffix',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        if (originalPrice != null) ...[
          const SizedBox(width: 4),
          Text(
            '${_fmt(originalPrice!)}$suffix',
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: const Color(0xFFB2B2B2),
              decoration: TextDecoration.lineThrough,
              decorationColor: const Color(0xFF828282),
            ),
          ),
        ],
        const Spacer(),
        if (discountPercent != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '-${discountPercent!.round()}%',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Green cart button — #519672, 5px radius, 29px tall
// ---------------------------------------------------------------------------
class _CartButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CartButton({this.onPressed});

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
// Quantity controls — green – count + bar, 29px tall
// ---------------------------------------------------------------------------
class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const _QuantityControls({
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 29,
      decoration: BoxDecoration(
        color: const Color(0xFF519672),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onDecrement,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
              child: const Center(
                child: Text(
                  '\u2013',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, color: Colors.white.withValues(alpha: 0.3)),
          Expanded(
            child: Center(
              child: Text(
                quantity.toString(),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(width: 1, color: Colors.white.withValues(alpha: 0.3)),
          Expanded(
            child: InkWell(
              onTap: onIncrement,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
              child: const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
