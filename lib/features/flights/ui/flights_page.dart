import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';
import '../models/flight.dart';
import '../services/flight_service.dart';
import '../widgets/flight_card.dart';
import '../widgets/flight_search_bar.dart';

/// Main flights search and listing page.
class FlightsPage extends StatefulWidget {
  final int? eventId;

  const FlightsPage({super.key, this.eventId});

  @override
  State<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends State<FlightsPage> {
  FlightService? _service;
  List<Flight> _flights = [];
  bool _isLoading = true;
  String? _error;

  String _origin = '';
  String _destination = '';
  DateTime? _date;
  int _passengers = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      _service = FlightService(authService);
      _loadFlights();
    });
  }

  Future<void> _loadFlights() async {
    if (_service == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flights = await _service!.searchFlights(
        origin: _origin.isNotEmpty ? _origin : null,
        destination: _destination.isNotEmpty ? _destination : null,
        date: _date != null ? DateFormat('yyyy-MM-dd').format(_date!) : null,
        passengers: _passengers,
      );
      setState(() {
        _flights = flights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToBooking(Flight flight) {
    context.push('/flights/${flight.id}/book');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FlightSearchBar(
                initialOrigin: _origin,
                initialDestination: _destination,
                onOriginChanged: (v) => _origin = v,
                onDestinationChanged: (v) => _destination = v,
                onDateChanged: (d) => _date = d,
                onPassengersChanged: (p) => _passengers = p,
                onSearch: _loadFlights,
                onSwap: (o, d) {
                  _origin = o;
                  _destination = d;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Flight list
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFlightsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (widget.eventId != null) {
                context.go('/events/${widget.eventId}/menu');
              } else {
                context.pop();
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Text(
            'Flights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load flights',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadFlights, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight_takeoff, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              'No flights found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _flights.length,
      itemBuilder: (context, index) {
        final flight = _flights[index];
        return FlightCard(
          flight: flight,
          onBookPressed: () => _navigateToBooking(flight),
        );
      },
    );
  }
}
