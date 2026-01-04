import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Booking confirmation page matching the reference design
class BookingConfirmationPage extends StatelessWidget {
  final String reservationNumber;
  final String serviceType;
  final String resourceName;
  final DateTime pickupDateTime;
  final DateTime? dropoffDateTime;
  final String pickupLocation;
  final String? dropoffLocation;
  final double amount;
  final int eventId;

  const BookingConfirmationPage({
    super.key,
    required this.reservationNumber,
    required this.serviceType,
    required this.resourceName,
    required this.pickupDateTime,
    this.dropoffDateTime,
    required this.pickupLocation,
    this.dropoffLocation,
    required this.amount,
    required this.eventId,
  });

  String get _title {
    switch (serviceType) {
      case 'shuttle':
        return 'Shuttle Booking Confirmation!';
      case 'individual':
        return 'Car with Driver Confirmation!';
      default:
        return 'Car Rental Booking Confirmation!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C4494),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Transfer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3C4494), width: 2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your Reservation No. $reservationNumber is Confirmed!',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Details cards row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reservation Details
                  Expanded(child: _buildReservationDetails()),
                  const SizedBox(width: 16),
                  // Driver/Contact Information
                  Expanded(child: _buildDriverInfo()),
                ],
              ),
              const SizedBox(height: 16),

              // Pick-up & Drop-off Times
              _buildPickupDropoffCard(),
              const SizedBox(height: 24),

              // Amount (if paid)
              if (amount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Amount Paid: \$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Back to Event button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Go back to event menu
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C4494),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildReservationDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reservation Details:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Parameter:', 'Information:'),
          const Divider(height: 16),
          _buildDetailRow('Reservation Number:', reservationNumber),
          const SizedBox(height: 8),
          _buildDetailRow('Service Type:', _serviceTypeLabel),
          const SizedBox(height: 8),
          _buildDetailRow('Vehicle:', resourceName),
          if (serviceType == 'rental') ...[
            const SizedBox(height: 8),
            _buildDetailRow('Transmission:', 'Automatic'),
            const SizedBox(height: 8),
            _buildDetailRow('Mileage Included:', 'Unlimited'),
          ],
        ],
      ),
    );
  }

  String get _serviceTypeLabel {
    switch (serviceType) {
      case 'shuttle':
        return 'Free Shuttle';
      case 'individual':
        return 'Car with Driver';
      default:
        return 'Self-drive Rental';
    }
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceType == 'rental' ? 'Driver Information:' : 'Contact Info:',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Main Driver:', 'Your Name'),
          const SizedBox(height: 8),
          _buildDetailRow('Country:', 'Your Country'),
          const SizedBox(height: 8),
          _buildDetailRow('Email:', 'your@email.com'),
          const SizedBox(height: 8),
          _buildDetailRow('Phone:', 'Your Phone'),
        ],
      ),
    );
  }

  Widget _buildPickupDropoffCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pick-up & Drop-off Times:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Header row
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Parameter',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const Expanded(
                flex: 3,
                child: Text(
                  'Pick-up:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              if (dropoffDateTime != null)
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Drop-off:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
            ],
          ),
          const Divider(height: 16),
          // Date & Time row
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text('Date & Time:', style: TextStyle(fontSize: 12)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  DateFormat('MMM dd, yyyy, h:mm a').format(pickupDateTime),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (dropoffDateTime != null)
                Expanded(
                  flex: 3,
                  child: Text(
                    DateFormat('MMM dd, yyyy, h:mm a').format(dropoffDateTime!),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Location row
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text('Location:', style: TextStyle(fontSize: 12)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  pickupLocation,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (dropoffDateTime != null)
                Expanded(
                  flex: 3,
                  child: Text(
                    dropoffLocation ?? '-',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
      ],
    );
  }
}
