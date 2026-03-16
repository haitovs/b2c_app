import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../shared/widgets/country_city_picker.dart';
import '../providers/travel_info_providers.dart';

class TravelInfoFormPage extends ConsumerStatefulWidget {
  const TravelInfoFormPage({super.key});

  @override
  ConsumerState<TravelInfoFormPage> createState() =>
      _TravelInfoFormPageState();
}

class _TravelInfoFormPageState extends ConsumerState<TravelInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _dataLoaded = false;

  // -- Arrival --
  String _arrivalMethod = 'airport';
  String? _arrivalCountry;
  String? _arrivalCity;
  String? _selectedArrivalAirport;
  final _arrivalBorderController = TextEditingController();
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  final _arrivalTransportController = TextEditingController();

  // -- Departure --
  String _departureMethod = 'airport';
  String? _departureCountry;
  String? _departureCity;
  String? _selectedDepartureAirport;
  final _departureBorderController = TextEditingController();
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  final _departureTransportController = TextEditingController();

  // -- Transfer --
  String _transferChoice = 'shuttle';
  final _transportCompanyController = TextEditingController();
  final _transportContactController = TextEditingController();
  final _transportPhoneController = TextEditingController();
  final _transportEmailController = TextEditingController();
  final _transportDriverController = TextEditingController();
  final _transportPlateController = TextEditingController();

  // -- Hotel --
  String? _selectedHotel;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  final _specialRequestsController = TextEditingController();

  String _memberName = '';

  @override
  void dispose() {
    _arrivalBorderController.dispose();
    _arrivalTransportController.dispose();
    _departureBorderController.dispose();
    _departureTransportController.dispose();
    _transportCompanyController.dispose();
    _transportContactController.dispose();
    _transportPhoneController.dispose();
    _transportEmailController.dispose();
    _transportDriverController.dispose();
    _transportPlateController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final memberId =
        GoRouterState.of(context).pathParameters['memberId'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;

    final travelAsync = ref.watch(
      travelInfoProvider((memberId: memberId, eventId: eventId)),
    );
    final airportsAsync = ref.watch(airportsProvider);
    final hotelsAsync = ref.watch(hotelsProvider);

    return travelAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, _) => _buildErrorState(error, memberId, eventId),
      data: (data) {
        if (!_dataLoaded) {
          _populateFields(data);
          _dataLoaded = true;
        }

        final airports = airportsAsync.when(
          data: (a) => a,
          loading: () => <Map<String, dynamic>>[],
          error: (_, __) => <Map<String, dynamic>>[],
        );
        final hotels = hotelsAsync.when(
          data: (h) => h,
          loading: () => <Map<String, dynamic>>[],
          error: (_, __) => <Map<String, dynamic>>[],
        );

        return _buildForm(
          eventIdStr: eventIdStr,
          memberId: memberId,
          eventId: eventId,
          airports: airports,
          hotels: hotels,
        );
      },
    );
  }

  // ===========================================================================
  // Populate
  // ===========================================================================

  void _populateFields(Map<String, dynamic> data) {
    _memberName = (data['team_member_name'] ?? '').toString();

    final arrMethod = data['arrival_method']?.toString();
    _arrivalMethod = (arrMethod == 'LAND_BORDER') ? 'land_border' : 'airport';
    _arrivalCountry = data['arrival_origin_country']?.toString();
    _arrivalCity = data['arrival_origin_city']?.toString();
    _selectedArrivalAirport = data['arrival_airport']?.toString();
    _arrivalBorderController.text =
        (data['arrival_border_crossing'] ?? '').toString();
    if (data['arrival_date'] != null) {
      _arrivalDate = DateTime.tryParse(data['arrival_date'].toString());
    }
    if (data['arrival_time'] != null) {
      final parts = data['arrival_time'].toString().split(':');
      if (parts.length >= 2) {
        _arrivalTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    _arrivalTransportController.text =
        (data['arrival_transport_number'] ?? '').toString();

    final depMethod = data['departure_method']?.toString();
    _departureMethod =
        (depMethod == 'LAND_BORDER') ? 'land_border' : 'airport';
    _departureCountry = data['departure_destination_country']?.toString();
    _departureCity = data['departure_destination_city']?.toString();
    _selectedDepartureAirport = data['departure_airport']?.toString();
    _departureBorderController.text =
        (data['departure_border_crossing'] ?? '').toString();
    if (data['departure_date'] != null) {
      _departureDate = DateTime.tryParse(data['departure_date'].toString());
    }
    if (data['departure_time'] != null) {
      final parts = data['departure_time'].toString().split(':');
      if (parts.length >= 2) {
        _departureTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    _departureTransportController.text =
        (data['departure_transport_number'] ?? '').toString();

    final tp = data['transfer_preference']?.toString();
    _transferChoice = (tp == 'OWN_TRANSPORT') ? 'own' : 'shuttle';
    _transportCompanyController.text =
        (data['transport_company'] ?? '').toString();
    _transportContactController.text =
        (data['transport_contact_person'] ?? '').toString();
    _transportPhoneController.text =
        (data['transport_phone'] ?? '').toString();
    _transportEmailController.text =
        (data['transport_email'] ?? '').toString();
    _transportDriverController.text =
        (data['transport_driver_name'] ?? '').toString();
    _transportPlateController.text =
        (data['transport_vehicle_plate'] ?? '').toString();

    if (data['hotel_id'] != null) {
      _selectedHotel = data['hotel_id'].toString();
    }
    if (data['hotel_check_in'] != null) {
      _checkInDate = DateTime.tryParse(data['hotel_check_in'].toString());
    }
    if (data['hotel_check_out'] != null) {
      _checkOutDate = DateTime.tryParse(data['hotel_check_out'].toString());
    }
    _specialRequestsController.text =
        (data['hotel_special_requests'] ?? '').toString();
  }

  // ===========================================================================
  // Error
  // ===========================================================================

  Widget _buildErrorState(Object error, String memberId, int eventId) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Failed to load travel info',
              style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error.toString(),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(
                travelInfoProvider((memberId: memberId, eventId: eventId))),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Main form
  // ===========================================================================

  Widget _buildForm({
    required String eventIdStr,
    required String memberId,
    required int eventId,
    required List<Map<String, dynamic>> airports,
    required List<Map<String, dynamic>> hotels,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(eventIdStr),
            const SizedBox(height: 24),
            _buildArrivalCard(airports, isMobile),
            const SizedBox(height: 20),
            _buildDepartureCard(airports, isMobile),
            const SizedBox(height: 20),
            _buildTransferCard(hotels, isMobile),
            const SizedBox(height: 20),
            _buildHotelCard(hotels, isMobile),
            const SizedBox(height: 32),
            _buildActionButtons(eventIdStr, memberId, eventId),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Breadcrumb — matches Figma: blue title > member name, divider below
  // ===========================================================================

  Widget _buildBreadcrumb(String eventIdStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => context.go('/events/$eventIdStr/travel'),
              child: Text(
                'Travel Information',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '>',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Flexible(
              child: Text(
                _memberName.isNotEmpty ? _memberName : 'Member',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade300, height: 1),
      ],
    );
  }

  // ===========================================================================
  // Section card wrapper
  // ===========================================================================

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Divider(color: Colors.grey.shade300, height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Arrival card
  // ===========================================================================

  Widget _buildArrivalCard(
      List<Map<String, dynamic>> airports, bool isMobile) {
    return _sectionCard(
      title: 'ARRIVAL INFORMATION',
      children: [
        _buildMethodField(
          label: 'Arrival Method:',
          value: _arrivalMethod,
          onChanged: (v) => setState(() => _arrivalMethod = v),
        ),
        const SizedBox(height: 20),

        // Inline: City/Country + Arrival Location
        if (isMobile) ...[
          _buildFieldWithSubtitle(
            label: 'Arrival From (City / Country):',
            subtitle: 'Where are you traveling from?',
            child: CountryCityPicker(
              selectedCountry: _arrivalCountry,
              selectedCity: _arrivalCity,
              onCountryChanged: (c) =>
                  setState(() { _arrivalCountry = c; _arrivalCity = null; }),
              onCityChanged: (c) => setState(() => _arrivalCity = c),
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldWithSubtitle(
            label: 'Arrival Location:',
            subtitle: 'Select airport or border crossing',
            child: _arrivalMethod == 'airport'
                ? _buildDropdown(
                    value: _selectedArrivalAirport,
                    items: _airportNames(airports),
                    hint: 'Select airport',
                    onChanged: (v) =>
                        setState(() => _selectedArrivalAirport = v),
                  )
                : AppTextField(
                    hintText: 'Enter border crossing',
                    controller: _arrivalBorderController,
                  ),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Country + City (CountryCityPicker is already a Row internally)
              Expanded(
                flex: 3,
                child: _buildFieldWithSubtitle(
                  label: 'Arrival From (City / Country):',
                  subtitle: 'Where are you traveling from?',
                  child: CountryCityPicker(
                    selectedCountry: _arrivalCountry,
                    selectedCity: _arrivalCity,
                    onCountryChanged: (c) => setState(
                        () { _arrivalCountry = c; _arrivalCity = null; }),
                    onCityChanged: (c) => setState(() => _arrivalCity = c),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Arrival Location
              Expanded(
                flex: 2,
                child: _buildFieldWithSubtitle(
                  label: 'Arrival Location:',
                  subtitle: 'Select airport or border crossing',
                  child: _arrivalMethod == 'airport'
                      ? _buildDropdown(
                          value: _selectedArrivalAirport,
                          items: _airportNames(airports),
                          hint: 'Select airport',
                          onChanged: (v) =>
                              setState(() => _selectedArrivalAirport = v),
                        )
                      : AppTextField(
                          hintText: 'Enter border crossing',
                          controller: _arrivalBorderController,
                        ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // Three-column: Date + Time + Transport Number
        if (isMobile) ...[
          _buildDateField(
            label: 'Arrival Date:',
            value: _arrivalDate,
            onPicked: (d) => setState(() => _arrivalDate = d),
          ),
          const SizedBox(height: 16),
          _buildTimeField(
            label: 'Arrival Time:',
            value: _arrivalTime,
            onPicked: (t) => setState(() => _arrivalTime = t),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Flight / Transport Number:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: 'e.g. TK123',
            controller: _arrivalTransportController,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'Arrival Date:',
                        value: _arrivalDate,
                        onPicked: (d) => setState(() => _arrivalDate = d),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeField(
                        label: 'Arrival Time:',
                        value: _arrivalTime,
                        onPicked: (t) => setState(() => _arrivalTime = t),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Flight / Transport Number:'),
                    const SizedBox(height: 8),
                    AppTextField(
                      hintText: 'e.g. TK123',
                      controller: _arrivalTransportController,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ===========================================================================
  // Departure card
  // ===========================================================================

  Widget _buildDepartureCard(
      List<Map<String, dynamic>> airports, bool isMobile) {
    return _sectionCard(
      title: 'DEPARTURE INFORMATION',
      children: [
        _buildMethodField(
          label: 'Departure From:',
          value: _departureMethod,
          onChanged: (v) => setState(() => _departureMethod = v),
        ),
        const SizedBox(height: 20),

        if (isMobile) ...[
          _buildFieldWithSubtitle(
            label: 'Destination (City / Country):',
            subtitle: 'Where are you traveling to?',
            child: CountryCityPicker(
              selectedCountry: _departureCountry,
              selectedCity: _departureCity,
              onCountryChanged: (c) => setState(
                  () { _departureCountry = c; _departureCity = null; }),
              onCityChanged: (c) => setState(() => _departureCity = c),
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldWithSubtitle(
            label: 'Departure Location:',
            subtitle: 'Select airport or border crossing',
            child: _departureMethod == 'airport'
                ? _buildDropdown(
                    value: _selectedDepartureAirport,
                    items: airports
                        .map((a) => (a['name'] ?? '').toString())
                        .where((n) => n.isNotEmpty)
                        .toList(),
                    hint: 'Select airport',
                    onChanged: (v) =>
                        setState(() => _selectedDepartureAirport = v),
                  )
                : AppTextField(
                    hintText: 'Enter border crossing',
                    controller: _departureBorderController,
                  ),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: _buildFieldWithSubtitle(
                  label: 'Destination (City / Country):',
                  subtitle: 'Where are you traveling to?',
                  child: CountryCityPicker(
                    selectedCountry: _departureCountry,
                    selectedCity: _departureCity,
                    onCountryChanged: (c) => setState(
                        () { _departureCountry = c; _departureCity = null; }),
                    onCityChanged: (c) => setState(() => _departureCity = c),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildFieldWithSubtitle(
                  label: 'Departure Location:',
                  subtitle: 'Select airport or border crossing',
                  child: _departureMethod == 'airport'
                      ? _buildDropdown(
                          value: _selectedDepartureAirport,
                          items: _airportNames(airports),
                          hint: 'Select airport',
                          onChanged: (v) =>
                              setState(() => _selectedDepartureAirport = v),
                        )
                      : AppTextField(
                          hintText: 'Enter border crossing',
                          controller: _departureBorderController,
                        ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        if (isMobile) ...[
          _buildDateField(
            label: 'Departure Date:',
            value: _departureDate,
            onPicked: (d) => setState(() => _departureDate = d),
          ),
          const SizedBox(height: 16),
          _buildTimeField(
            label: 'Departure Time:',
            value: _departureTime,
            onPicked: (t) => setState(() => _departureTime = t),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Flight / Transport Number:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: 'e.g. TK124',
            controller: _departureTransportController,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'Departure Date:',
                        value: _departureDate,
                        onPicked: (d) => setState(() => _departureDate = d),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeField(
                        label: 'Departure Time:',
                        value: _departureTime,
                        onPicked: (t) => setState(() => _departureTime = t),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Flight / Transport Number:'),
                    const SizedBox(height: 8),
                    AppTextField(
                      hintText: 'e.g. TK124',
                      controller: _departureTransportController,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ===========================================================================
  // Transfer card
  // ===========================================================================

  Widget _buildTransferCard(
      List<Map<String, dynamic>> hotels, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FREE TRANSFER card — route diagram
        _sectionCard(
          title: 'FREE TRANSFER',
          children: [
            _buildRouteDiagram(hotels),
          ],
        ),
        const SizedBox(height: 20),
        // TRANSFER USAGE card — choice + private transport details
        _sectionCard(
          title: 'TRANSFER USAGE',
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side — question + checkboxes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Will you use the official event shuttle service?',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _transferCheckbox(
                          label: 'I will use the official shuttle service',
                          selected: _transferChoice == 'shuttle',
                          onTap: () =>
                              setState(() => _transferChoice = 'shuttle'),
                        ),
                        const SizedBox(height: 8),
                        _transferCheckbox(
                          label: 'I will arrange my own transportation',
                          selected: _transferChoice == 'own',
                          onTap: () => setState(() => _transferChoice = 'own'),
                        ),
                      ],
                    ),
                  ),
                  // Right side — shuttle info message
                  if (!isMobile && _transferChoice == 'shuttle')
                    Expanded(
                      child: _buildShuttleInfoMessage(),
                    ),
                ],
              ),
            ),
            if (isMobile && _transferChoice == 'shuttle') ...[
              const SizedBox(height: 16),
              _buildShuttleInfoMessage(),
            ],
            // Private transport details — shown when "own" is selected
            if (_transferChoice == 'own') ...[
              const SizedBox(height: 24),
              Text(
                'Private Transportation Details',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildTransportFields(isMobile),
            ],
          ],
        ),
      ],
    );
  }

  /// Route diagram: Airport ↔ Official Hotel ↔ Venue Center ↔ Official Events
  Widget _buildRouteDiagram(List<Map<String, dynamic>> hotels) {
    final officialHotels = hotels
        .where((h) => h['name'] != null)
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Airport
          Expanded(
            child: _routeStop(
              pngAsset: 'assets/travel_info/airport.png',
              title: 'Airport',
              subtitles: const ['Ashgabat International', 'Airport'],
            ),
          ),
          _routeArrow(),
          // Official Hotel
          Expanded(
            child: _routeStop(
              pngAsset: 'assets/travel_info/official-hotel.png',
              title: 'Official Hotel',
              subtitleWidgets: officialHotels.map((h) {
                final name = h['name'].toString();
                final stars = h['stars'];
                if (stars != null && stars is int && stars > 0) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SvgPicture.asset(
                        'assets/travel_info/star.svg',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$stars',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  );
                }
                return Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              }).toList(),
            ),
          ),
          _routeArrow(),
          // Venue Center
          Expanded(
            child: _routeStop(
              title: 'Venue Center',
              subtitles: const ['CCTT Expo Center'],
            ),
          ),
          _routeArrow(),
          // Official Events
          Expanded(
            child: _routeStop(
              title: 'Official Events',
              subtitles: const ['CCTT Expo Center'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeStop({
    String? pngAsset,
    required String title,
    List<String>? subtitles,
    List<Widget>? subtitleWidgets,
  }) {
    final subs = subtitles ?? [];
    final subWidgets = subtitleWidgets ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pngAsset != null) ...[
              Image.asset(pngAsset, width: 24, height: 24),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (subWidgets.isNotEmpty)
          ...subWidgets.map((w) => Padding(
                padding: EdgeInsets.only(left: pngAsset != null ? 32 : 0),
                child: w,
              ))
        else
          ...subs.map((s) => Padding(
                padding: EdgeInsets.only(left: pngAsset != null ? 32 : 0),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              )),
      ],
    );
  }

  Widget _routeArrow() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Image.asset(
          'assets/travel_info/arrows.png',
          width: 120,
          height: 48,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Shuttle info message card
  Widget _buildShuttleInfoMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Text(
                'You are welcome to use the official event shuttle service between the airport, hotels, Expo Center, and social program venues.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Checkbox-style transfer option (matches Figma)
  Widget _transferCheckbox({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Private transport detail fields — 3 rows of 2 columns
  Widget _buildTransportFields(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildFieldLabel('Company / Organization:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: '',
            controller: _transportCompanyController,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Contact Person Name:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: '',
            controller: _transportContactController,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Phone Number:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: '',
            controller: _transportPhoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Email:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: '',
            controller: _transportEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Driver Name:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: '',
            controller: _transportDriverController,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Vehicle Plate Number:'),
          const SizedBox(height: 8),
          AppTextField(
            hintText: '',
            controller: _transportPlateController,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Company / Organization:'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hintText: '',
                    controller: _transportCompanyController,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Contact Person Name:'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hintText: '',
                    controller: _transportContactController,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Phone Number:'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hintText: '',
                    controller: _transportPhoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Email:'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hintText: '',
                    controller: _transportEmailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Driver Name:'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hintText: '',
                    controller: _transportDriverController,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Vehicle Plate Number:'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hintText: '',
                    controller: _transportPlateController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Hotel card
  // ===========================================================================

  Widget _buildHotelCard(
      List<Map<String, dynamic>> hotels, bool isMobile) {
    final hotelItems =
        hotels.where((h) => h['id'] != null && h['name'] != null).toList();

    return _sectionCard(
      title: 'HOTEL INFORMATION',
      children: [
        _buildFieldLabel('Hotel Name:'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue:
              hotelItems.any((h) => h['id'].toString() == _selectedHotel)
                  ? _selectedHotel
                  : null,
          hint: Text('Select hotel', style: AppTextStyles.placeholder),
          isExpanded: true,
          decoration: _dropdownDecoration(),
          items: hotelItems.map((h) {
            return DropdownMenuItem<String>(
              value: h['id'].toString(),
              child:
                  Text(h['name'].toString(), style: AppTextStyles.inputText),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedHotel = v),
        ),
        const SizedBox(height: 16),
        if (isMobile) ...[
          _buildDateField(
            label: 'Check-in Date:',
            value: _checkInDate,
            onPicked: (d) => setState(() => _checkInDate = d),
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Check-out Date:',
            value: _checkOutDate,
            onPicked: (d) => setState(() => _checkOutDate = d),
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Check-in Date:',
                  value: _checkInDate,
                  onPicked: (d) => setState(() => _checkInDate = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'Check-out Date:',
                  value: _checkOutDate,
                  onPicked: (d) => setState(() => _checkOutDate = d),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        _buildFieldLabel('Special Requests:'),
        const SizedBox(height: 8),
        AppTextField(
          hintText: 'Any special requirements...',
          controller: _specialRequestsController,
          maxLines: 3,
        ),
      ],
    );
  }

  // ===========================================================================
  // Action buttons — right-aligned: Cancel (outlined) + Submit (filled)
  // ===========================================================================

  Widget _buildActionButtons(
      String eventIdStr, String memberId, int eventId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSubmitting
              ? null
              : () => context.go('/events/$eventIdStr/travel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Cancel',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () => _submit(memberId, eventId, eventIdStr),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text('Submit',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ===========================================================================
  // Submit
  // ===========================================================================

  Future<void> _submit(
      String memberId, int eventId, String eventIdStr) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final dateFmt = DateFormat('yyyy-MM-dd');
    final data = <String, dynamic>{
      'arrival_method':
          _arrivalMethod == 'airport' ? 'AIRPORT' : 'LAND_BORDER',
      'arrival_origin_country': _arrivalCountry,
      'arrival_origin_city': _arrivalCity,
      'arrival_airport':
          _arrivalMethod == 'airport' ? _selectedArrivalAirport : null,
      'arrival_border_crossing': _arrivalMethod == 'land_border'
          ? _arrivalBorderController.text.trim()
          : null,
      'arrival_date':
          _arrivalDate != null ? dateFmt.format(_arrivalDate!) : null,
      'arrival_time': _arrivalTime != null
          ? '${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'arrival_transport_number':
          _arrivalTransportController.text.trim().isNotEmpty
              ? _arrivalTransportController.text.trim()
              : null,
      'departure_method':
          _departureMethod == 'airport' ? 'AIRPORT' : 'LAND_BORDER',
      'departure_destination_country': _departureCountry,
      'departure_destination_city': _departureCity,
      'departure_airport':
          _departureMethod == 'airport' ? _selectedDepartureAirport : null,
      'departure_border_crossing': _departureMethod == 'land_border'
          ? _departureBorderController.text.trim()
          : null,
      'departure_date':
          _departureDate != null ? dateFmt.format(_departureDate!) : null,
      'departure_time': _departureTime != null
          ? '${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'departure_transport_number':
          _departureTransportController.text.trim().isNotEmpty
              ? _departureTransportController.text.trim()
              : null,
      'transfer_preference':
          _transferChoice == 'shuttle' ? 'OFFICIAL_SHUTTLE' : 'OWN_TRANSPORT',
      'transport_company': _transferChoice == 'own' &&
              _transportCompanyController.text.trim().isNotEmpty
          ? _transportCompanyController.text.trim()
          : null,
      'transport_contact_person': _transferChoice == 'own' &&
              _transportContactController.text.trim().isNotEmpty
          ? _transportContactController.text.trim()
          : null,
      'transport_phone': _transferChoice == 'own' &&
              _transportPhoneController.text.trim().isNotEmpty
          ? _transportPhoneController.text.trim()
          : null,
      'transport_email': _transferChoice == 'own' &&
              _transportEmailController.text.trim().isNotEmpty
          ? _transportEmailController.text.trim()
          : null,
      'transport_driver_name': _transferChoice == 'own' &&
              _transportDriverController.text.trim().isNotEmpty
          ? _transportDriverController.text.trim()
          : null,
      'transport_vehicle_plate': _transferChoice == 'own' &&
              _transportPlateController.text.trim().isNotEmpty
          ? _transportPlateController.text.trim()
          : null,
      'hotel_id':
          _selectedHotel != null ? int.tryParse(_selectedHotel!) : null,
      'hotel_check_in':
          _checkInDate != null ? dateFmt.format(_checkInDate!) : null,
      'hotel_check_out':
          _checkOutDate != null ? dateFmt.format(_checkOutDate!) : null,
      'hotel_special_requests':
          _specialRequestsController.text.trim().isNotEmpty
              ? _specialRequestsController.text.trim()
              : null,
    };

    try {
      final service = ref.read(travelInfoServiceProvider);
      await service.saveTravelInfo(memberId, eventId, data);
      if (!mounted) return;
      AppSnackBar.showSuccess(
          context, 'Travel information saved successfully');
      ref.invalidate(travelTeamMembersProvider(eventId));
      context.go('/events/$eventIdStr/travel');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ===========================================================================
  // Shared field builders
  // ===========================================================================

  /// Bold field label with colon (matches Figma)
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  /// Field with bold label + grey subtitle + child widget
  Widget _buildFieldWithSubtitle({
    required String label,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// Arrival/Departure method radio — standard radio circles
  Widget _buildMethodField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        Row(
          children: [
            _radioOption(
              label: 'Airport',
              selected: value == 'airport',
              onTap: () => onChanged('airport'),
            ),
            const SizedBox(width: 32),
            _radioOption(
              label: 'Land Border',
              selected: value == 'land_border',
              onTap: () => onChanged('land_border'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _radioOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            selected
                ? 'assets/travel_info/check-circle.svg'
                : 'assets/travel_info/check-circle-off.svg',
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Shared dropdown decoration
  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: AppColors.buttonBackground, width: 2),
      ),
    );
  }

  /// Extract airport name strings from the airports list
  List<String> _airportNames(List<Map<String, dynamic>> airports) {
    return airports
        .map((a) => (a['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  /// Reusable string-value dropdown
  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      hint: Text(hint, style: AppTextStyles.placeholder),
      isExpanded: true,
      decoration: _dropdownDecoration(),
      items: items
          .map((name) => DropdownMenuItem(
              value: name,
              child: Text(name, style: AppTextStyles.inputText)))
          .toList(),
      onChanged: onChanged,
    );
  }

  /// Date picker field with calendar icon
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    final display =
        value != null ? DateFormat('dd/MM/yyyy').format(value) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2050),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: AppTheme.primaryColor),
                ),
                child: child!,
              ),
            );
            if (picked != null) onPicked(picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display.isEmpty ? 'dd/mm/yyyy' : display,
                    style: display.isEmpty
                        ? AppTextStyles.placeholder
                        : AppTextStyles.inputText,
                  ),
                ),
                SvgPicture.asset(
                    'assets/travel_info/calendar.svg',
                    width: 18, height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Time picker field with clock icon
  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    final display = value != null
        ? '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value ?? TimeOfDay.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: AppTheme.primaryColor),
                ),
                child: child!,
              ),
            );
            if (picked != null) onPicked(picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display.isEmpty ? 'HH:MM' : display,
                    style: display.isEmpty
                        ? AppTextStyles.placeholder
                        : AppTextStyles.inputText,
                  ),
                ),
                SvgPicture.asset(
                    'assets/travel_info/clock.svg',
                    width: 18, height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
