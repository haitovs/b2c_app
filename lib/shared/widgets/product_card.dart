import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// A product / service card for the shop section.
///
/// Displays an image, product name, optional subtitle, dual-currency pricing,
/// an optional discount badge, and an "Add to Cart" button.
///
/// ```dart
/// ProductCard(
///   name: 'VIP Ticket',
///   imageUrl: 'https://example.com/ticket.jpg',
///   priceUsd: 100,
///   priceTmt: 350,
///   discountPercent: 15,
///   subtitle: 'Full access pass',
///   onTap: () => context.go('/shop/1'),
///   onAddToCart: () => ref.read(cartProvider.notifier).add(item),
/// )
/// ```
class ProductCard extends StatelessWidget {
  /// Product display name.
  final String name;

  /// Optional image URL shown at the top of the card.
  final String? imageUrl;

  /// Price in US dollars.
  final double priceUsd;

  /// Price in Turkmen manat.
  final double priceTmt;

  /// Discount percentage. When greater than 0 a badge is shown on the image.
  final double discountPercent;

  /// Optional secondary text displayed below the name.
  final String? subtitle;

  /// Callback when the card body is tapped (navigate to detail view).
  final VoidCallback? onTap;

  /// Callback when the "Add to Cart" button is pressed.
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.priceUsd,
    required this.priceTmt,
    this.discountPercent = 0,
    this.subtitle,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
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
            children: [
              // Image section with optional discount badge
              _ImageSection(
                imageUrl: imageUrl,
                discountPercent: discountPercent,
              ),

              // Text and pricing
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Dual currency price
                    Text(
                      '\$${_formatNumber(priceUsd)} / ${_formatNumber(priceTmt)} TMT',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Add to cart button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text(
                      'Add to Cart',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats a number, removing the decimal part when it is `.0`.
  static String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

class _ImageSection extends StatelessWidget {
  final String? imageUrl;
  final double discountPercent;

  const _ImageSection({this.imageUrl, required this.discountPercent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          // Product image or placeholder
          AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),

          // Discount badge
          if (discountPercent > 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${discountPercent.round()}% OFF',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
