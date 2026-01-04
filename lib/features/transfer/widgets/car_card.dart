import 'package:flutter/material.dart';

import '../models/car.dart';

/// Card widget for displaying a car in the list
class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;

  const CarCard({super.key, required this.car, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: car.imageUrl != null
                        ? Image.network(
                            car.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.directions_car,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(
                              0xFF3C4494,
                            ).withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.directions_car,
                                size: 64,
                                color: Color(0xFF3C4494),
                              ),
                            ),
                          ),
                  ),
                ),
                // Type badge
                if (car.isIndividual)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'With Driver',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    car.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Specs row
                  Row(
                    children: [
                      if (car.transmission != null) ...[
                        _buildSpecChip(Icons.settings, car.transmission!),
                        const SizedBox(width: 8),
                      ],
                      if (car.seats != null)
                        _buildSpecChip(Icons.person_outline, '${car.seats}'),
                      if (car.baggage != null) ...[
                        const SizedBox(width: 8),
                        _buildSpecChip(Icons.luggage, '${car.baggage}'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Driver info (for individual cars)
                  if (car.isIndividual && car.driverName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Driver: ${car.driverName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                        if (car.driverLanguages != null) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Expanded(
                            child: Text(
                              car.driverLanguages!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        car.priceDisplay,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3C4494),
                        ),
                      ),
                      if (car.pricePerHour != null)
                        Text(
                          '\$${car.pricePerHour!.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
