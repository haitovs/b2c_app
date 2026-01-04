/// Booking model for transfer feature
class TransferBooking {
  final String id;
  final String reservationNumber;
  final String serviceType;
  final String status;
  final double amountTotal;
  final Map<String, dynamic> bookingDetails;
  final String createdAt;
  final String? resourceName;
  final String? resourceImage;

  TransferBooking({
    required this.id,
    required this.reservationNumber,
    required this.serviceType,
    required this.status,
    required this.amountTotal,
    required this.bookingDetails,
    required this.createdAt,
    this.resourceName,
    this.resourceImage,
  });

  factory TransferBooking.fromJson(Map<String, dynamic> json) {
    return TransferBooking(
      id: json['id'] as String,
      reservationNumber: json['reservation_number'] as String? ?? '',
      serviceType: json['service_type'] as String,
      status: json['status'] as String,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
      bookingDetails: json['booking_details'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String? ?? '',
      resourceName: json['resource_name'] as String?,
      resourceImage: json['resource_image'] as String?,
    );
  }

  String get pickupDateTime =>
      bookingDetails['pickup_datetime'] as String? ?? '';
  String get dropoffDateTime =>
      bookingDetails['dropoff_datetime'] as String? ?? '';
  String get pickupLocation =>
      bookingDetails['pickup_location'] as String? ?? '';
  String get dropoffLocation =>
      bookingDetails['dropoff_location'] as String? ?? '';
  int get passengerCount => bookingDetails['passenger_count'] as int? ?? 1;

  bool get isShuttle => serviceType == 'TRANSFER_SHUTTLE';
  bool get isIndividual => serviceType == 'TRANSFER_INDIVIDUAL';
  bool get isRental => serviceType == 'TRANSFER_RENT';

  bool get isPaid => status == 'PAID' || status == 'CONFIRMED';
  bool get isPending => status == 'PENDING_PAYMENT';
}
