import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// An order summary card for the shopping cart / checkout flow.
///
/// Displays item count, subtotals per currency (USD / TMT — only currencies
/// present in the cart), an optional discount row, a bold total, and a
/// full-width checkout button.
class CartSummaryWidget extends StatelessWidget {
  /// Grand total in US dollars (after discount). 0 if no USD items.
  final double totalUsd;

  /// Grand total in Turkmen manat (after discount). 0 if no TMT items.
  final double totalTmt;

  /// Discount amount in US dollars. Hidden when 0.
  final double discountUsd;

  /// Discount amount in Turkmen manat. Hidden when 0.
  final double discountTmt;

  /// Number of items in the cart.
  final int itemCount;

  /// Called when the checkout button is pressed. When `null` the button is
  /// disabled.
  final VoidCallback? onCheckout;

  const CartSummaryWidget({
    super.key,
    required this.totalUsd,
    required this.totalTmt,
    this.discountUsd = 0,
    this.discountTmt = 0,
    required this.itemCount,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final subtotalUsd = totalUsd + discountUsd;
    final subtotalTmt = totalTmt + discountTmt;
    final hasDiscount = discountUsd > 0 || discountTmt > 0;
    final hasUsd = subtotalUsd > 0 || totalUsd > 0;
    final hasTmt = subtotalTmt > 0 || totalTmt > 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
          // Heading
          Text(
            'Order Summary',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Items count
          _SummaryRow(
            label: 'Items',
            value: itemCount.toString(),
          ),
          const SizedBox(height: 10),

          // Subtotal per currency
          if (hasUsd)
            _SummaryRow(
              label: 'Subtotal (USD)',
              value: '\$${_fmt(subtotalUsd)}',
            ),
          if (hasUsd && hasTmt) const SizedBox(height: 4),
          if (hasTmt)
            _SummaryRow(
              label: 'Subtotal (TMT)',
              value: '${_fmt(subtotalTmt)} TMT',
            ),

          // Discount (shown only when > 0)
          if (hasDiscount) ...[
            const SizedBox(height: 10),
            if (discountUsd > 0)
              _SummaryRow(
                label: 'Discount (USD)',
                value: '-\$${_fmt(discountUsd)}',
                valueColor: AppTheme.successColor,
              ),
            if (discountTmt > 0)
              _SummaryRow(
                label: 'Discount (TMT)',
                value: '-${_fmt(discountTmt)} TMT',
                valueColor: AppTheme.successColor,
              ),
          ],

          const SizedBox(height: 14),

          // Divider
          Divider(color: Colors.grey.shade300, height: 1),

          const SizedBox(height: 14),

          // Total per currency
          if (hasUsd)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (USD)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '\$${_fmt(totalUsd)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          if (hasUsd && hasTmt) const SizedBox(height: 4),
          if (hasTmt)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (TMT)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${_fmt(totalTmt)} TMT',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Place Order'),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a number, removing the decimal part when it is `.0`.
  static String _fmt(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

/// A single label–value row inside the summary card.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
