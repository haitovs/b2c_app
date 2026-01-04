import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';
import '../services/transfer_service.dart';
import 'booking_confirmation_page.dart';

/// Booking page for all transfer types
class TransferBookingPage extends StatefulWidget {
  final String serviceType; // "shuttle", "individual", "rental"
  final int resourceId;
  final String resourceName;
  final String? resourceImage;
  final int eventId;
  final double amount;
  final double? pricePerHour;

  const TransferBookingPage({
    super.key,
    required this.serviceType,
    required this.resourceId,
    required this.resourceName,
    this.resourceImage,
    required this.eventId,
    required this.amount,
    this.pricePerHour,
  });

  @override
  State<TransferBookingPage> createState() => _TransferBookingPageState();
}

class _TransferBookingPageState extends State<TransferBookingPage> {
  final _formKey = GlobalKey<FormState>();
  TransferService? _transferService;

  // Common fields
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _pickupTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime? _dropoffDate;
  TimeOfDay _dropoffTime = const TimeOfDay(hour: 18, minute: 0);
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  int _passengerCount = 1;
  final _specialRequestsController = TextEditingController();

  // Duration type
  final String _durationType = 'daily';
  int _days = 1;
  final int _hours = 1;

  // License fields (for rentals)
  final _licenseNumberController = TextEditingController();
  final _licenseCountryController = TextEditingController();
  DateTime? _licenseExpiry;

  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    if (widget.serviceType == 'rental') {
      _dropoffDate = _pickupDate.add(const Duration(days: 1));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_transferService == null) {
      final authService = context.read<AuthService>();
      _transferService = TransferService(authService);
    }
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _specialRequestsController.dispose();
    _licenseNumberController.dispose();
    _licenseCountryController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    if (widget.serviceType == 'shuttle') return 0;
    if (_durationType == 'hourly' && widget.pricePerHour != null) {
      return widget.pricePerHour! * _hours;
    }
    return widget.amount * _days;
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isPickup ? _pickupDate : (_dropoffDate ?? _pickupDate),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          if (_dropoffDate != null && _dropoffDate!.isBefore(_pickupDate)) {
            _dropoffDate = _pickupDate.add(const Duration(days: 1));
          }
        } else {
          _dropoffDate = picked;
        }
        _calculateDays();
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isPickup ? _pickupTime : _dropoffTime,
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _dropoffTime = picked;
        }
      });
    }
  }

  void _calculateDays() {
    if (_dropoffDate != null) {
      _days = _dropoffDate!.difference(_pickupDate).inDays;
      if (_days < 1) _days = 1;
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pickupDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );

      String? dropoffDateTime;
      if (_dropoffDate != null) {
        final dt = DateTime(
          _dropoffDate!.year,
          _dropoffDate!.month,
          _dropoffDate!.day,
          _dropoffTime.hour,
          _dropoffTime.minute,
        );
        dropoffDateTime = dt.toIso8601String();
      }

      final result = await _transferService!.createBooking(
        serviceType: widget.serviceType,
        resourceId: widget.resourceId,
        pickupDatetime: pickupDateTime.toIso8601String(),
        dropoffDatetime: dropoffDateTime,
        pickupLocation: _pickupLocationController.text,
        dropoffLocation: _dropoffLocationController.text.isEmpty
            ? null
            : _dropoffLocationController.text,
        passengerCount: _passengerCount,
        specialRequests: _specialRequestsController.text.isEmpty
            ? null
            : _specialRequestsController.text,
        durationType: _durationType,
        hours: _durationType == 'hourly' ? _hours : null,
        days: _days,
        // License info for rentals
        licenseNumber: widget.serviceType == 'rental'
            ? _licenseNumberController.text
            : null,
        licenseCountry: widget.serviceType == 'rental'
            ? _licenseCountryController.text
            : null,
        licenseExpiry: _licenseExpiry?.toIso8601String(),
      );

      if (!mounted) return;

      // Navigate to confirmation page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(
            reservationNumber: result['reservation_number'] as String,
            serviceType: widget.serviceType,
            resourceName: widget.resourceName,
            pickupDateTime: pickupDateTime,
            dropoffDateTime: dropoffDateTime != null
                ? DateTime.parse(dropoffDateTime)
                : null,
            pickupLocation: _pickupLocationController.text,
            dropoffLocation: _dropoffLocationController.text,
            amount: _totalAmount,
            eventId: widget.eventId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C4494),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selected vehicle card
            _buildVehicleCard(),
            const SizedBox(height: 16),

            // Date & Time section
            _buildSectionCard('Date & Time', Icons.calendar_today, [
              _buildDateTimeRow('Pick-up', true),
              if (widget.serviceType != 'shuttle') ...[
                const Divider(),
                _buildDateTimeRow('Drop-off', false),
              ],
            ]),
            const SizedBox(height: 16),

            // Location section
            _buildSectionCard('Location', Icons.location_on, [
              TextFormField(
                controller: _pickupLocationController,
                decoration: const InputDecoration(
                  labelText: 'Pick-up Location *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              if (widget.serviceType != 'shuttle') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dropoffLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Drop-off Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // Passengers
            _buildSectionCard('Passengers', Icons.people, [
              Row(
                children: [
                  const Text('Number of passengers:'),
                  const Spacer(),
                  IconButton(
                    onPressed: _passengerCount > 1
                        ? () => setState(() => _passengerCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_passengerCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _passengerCount++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),

            // License info (for rentals)
            if (widget.serviceType == 'rental') ...[
              _buildSectionCard('Driver License', Icons.badge, [
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'License Number *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _licenseCountryController,
                  decoration: const InputDecoration(
                    labelText: 'Issue Country *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() => _licenseExpiry = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'License Expiry Date *',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _licenseExpiry != null
                          ? DateFormat('MMM dd, yyyy').format(_licenseExpiry!)
                          : 'Select date',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            // Special requests
            _buildSectionCard('Special Requests', Icons.note, [
              TextFormField(
                controller: _specialRequestsController,
                decoration: const InputDecoration(
                  labelText: 'Any special requests?',
                  border: OutlineInputBorder(),
                  hintText: 'Child seat, wheelchair access, etc.',
                ),
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 16),

            // Price summary
            if (widget.serviceType != 'shuttle') _buildPriceSummary(),

            const SizedBox(height: 16),

            // Terms checkbox
            CheckboxListTile(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              title: const Text(
                'I agree to the terms and conditions',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Confirm button
            ElevatedButton(
              onPressed: _isLoading ? null : _createBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C4494),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.serviceType == 'shuttle'
                          ? 'Confirm Booking'
                          : 'Continue to Payment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF3C4494).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.serviceType == 'shuttle'
                    ? Icons.directions_bus
                    : Icons.directions_car,
                color: const Color(0xFF3C4494),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.resourceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.serviceType == 'shuttle'
                        ? 'Free Shuttle'
                        : widget.serviceType == 'individual'
                        ? 'Car with Driver'
                        : 'Self-drive Rental',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF3C4494)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(String label, bool isPickup) {
    final date = isPickup ? _pickupDate : (_dropoffDate ?? _pickupDate);
    final time = isPickup ? _pickupTime : _dropoffTime;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, isPickup),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '$label Date',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Text(DateFormat('MMM dd, yyyy').format(date)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(context, isPickup),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '$label Time',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Text(time.format(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF3C4494).withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.amount.toStringAsFixed(0)}/day × $_days day${_days > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '\$${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C4494),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
