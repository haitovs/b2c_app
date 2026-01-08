import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/flight.dart';

/// Card widget for displaying a flight in the search results.
class FlightCard extends StatelessWidget {
  final Flight flight;
  final VoidCallback onBookPressed;

  const FlightCard({
    super.key,
    required this.flight,
    required this.onBookPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompact) ...[
                  // Compact mobile layout
                  _buildCompactHeader(),
                ] else ...[
                  // Wide layout: Logo + Schedule + Price in a row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAirlineLogo(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFlightSchedule()),
                      _buildPriceSection(),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Baggage section
                _buildBaggageSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Compact header layout for mobile
  Widget _buildCompactHeader() {
    return Column(
      children: [
        // Top row: Logo and Price/Book button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactAirlineLogo(),
            const Spacer(),
            _buildCompactPriceSection(),
          ],
        ),
        const SizedBox(height: 12),

        // Flight schedule row
        _buildCompactFlightSchedule(),
      ],
    );
  }

  /// Compact airline logo for mobile
  Widget _buildCompactAirlineLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: flight.airlineLogo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                flight.airlineLogo!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
              ),
            )
          : _buildPlaceholderLogo(),
    );
  }

  /// Compact price section for mobile
  Widget _buildCompactPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          flight.priceFormatted,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: onBookPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9CA4CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Book and pay',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Compact flight schedule for mobile
  Widget _buildCompactFlightSchedule() {
    final departureTime = DateFormat('h:mm a').format(flight.departureTime);
    final arrivalTime = DateFormat('h:mm a').format(flight.arrivalTime);
    final departureDate = DateFormat('MMM d').format(flight.departureTime);
    final arrivalDate = DateFormat('MMM d').format(flight.arrivalTime);

    return Row(
      children: [
        // Departure
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                departureTime,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                '${flight.originCode} $departureDate',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Timeline (compact)
        Expanded(child: _buildCompactTimeline()),

        // Arrival
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                arrivalTime,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                '${flight.destinationCode} $arrivalDate',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact timeline for mobile
  Widget _buildCompactTimeline() {
    return Column(
      children: [
        // Direct/Stops badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF9CA4CC),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            flight.stopLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 3),

        // Timeline line
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(height: 2, color: const Color(0xFFD9D9D9)),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),

        // Duration
        Text(
          flight.durationFormatted,
          style: const TextStyle(fontSize: 10, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildAirlineLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: flight.airlineLogo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                flight.airlineLogo!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
              ),
            )
          : _buildPlaceholderLogo(),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Center(
      child: Icon(Icons.flight, color: const Color(0xFF3C4494), size: 30),
    );
  }

  Widget _buildFlightSchedule() {
    final departureTime = DateFormat('h:mm a').format(flight.departureTime);
    final arrivalTime = DateFormat('h:mm a').format(flight.arrivalTime);
    final departureDate = DateFormat('MMM d').format(flight.departureTime);
    final arrivalDate = DateFormat('MMM d').format(flight.arrivalTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Times row
        Row(
          children: [
            // Departure
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  departureTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${flight.originCode} $departureDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Timeline with Direct badge
            Expanded(child: _buildTimeline()),

            const SizedBox(width: 12),

            // Arrival
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  arrivalTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${flight.destinationCode} $arrivalDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        // Direct/Stops badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF9CA4CC),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            flight.stopLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Timeline line
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(height: 2, color: const Color(0xFFD9D9D9)),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Duration
        Text(
          flight.durationFormatted,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFD9D9D9), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            flight.priceFormatted,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onBookPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9CA4CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Book and pay',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaggageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Included baggage',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            if (flight.personalItem)
              _buildBaggageItem(Icons.shopping_bag_outlined, 'Personal item'),
            if (flight.carryOn)
              _buildBaggageItem(Icons.luggage_outlined, 'Carry-on bag'),
            if (flight.checkedBag)
              _buildBaggageItem(Icons.work_outline, 'Checked bag'),
          ],
        ),
      ],
    );
  }

  Widget _buildBaggageItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }
}
