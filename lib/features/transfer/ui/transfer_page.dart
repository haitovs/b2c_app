import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_service.dart';
import '../models/car.dart';
import '../models/shuttle.dart';
import '../services/transfer_service.dart';
import '../widgets/car_card.dart';
import '../widgets/shuttle_card.dart';
import 'car_detail_page.dart';
import 'shuttle_detail_page.dart';

/// Main transfer page with 3 tabs: Shuttle, Individual Car, Rent Car
class TransferPage extends StatefulWidget {
  final int eventId;

  const TransferPage({super.key, required this.eventId});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransferService? _transferService;

  List<Shuttle> _shuttles = [];
  List<Car> _individualCars = [];
  List<Car> _rentalCars = [];

  bool _isLoadingShuttles = true;
  bool _isLoadingIndividual = true;
  bool _isLoadingRental = true;

  String? _shuttleError;
  String? _individualError;
  String? _rentalError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_transferService == null) {
      final authService = context.read<AuthService>();
      _transferService = TransferService(authService);
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadShuttles();
    _loadIndividualCars();
    _loadRentalCars();
  }

  Future<void> _loadShuttles() async {
    try {
      final shuttles = await _transferService!.getShuttles();
      setState(() {
        _shuttles = shuttles;
        _isLoadingShuttles = false;
      });
    } catch (e) {
      setState(() {
        _shuttleError = e.toString();
        _isLoadingShuttles = false;
      });
    }
  }

  Future<void> _loadIndividualCars() async {
    try {
      final cars = await _transferService!.getIndividualCars();
      setState(() {
        _individualCars = cars;
        _isLoadingIndividual = false;
      });
    } catch (e) {
      setState(() {
        _individualError = e.toString();
        _isLoadingIndividual = false;
      });
    }
  }

  Future<void> _loadRentalCars() async {
    try {
      final cars = await _transferService!.getRentalCars();
      setState(() {
        _rentalCars = cars;
        _isLoadingRental = false;
      });
    } catch (e) {
      setState(() {
        _rentalError = e.toString();
        _isLoadingRental = false;
      });
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/events/${widget.eventId}/menu'),
        ),
        title: const Text(
          'Transfer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.directions_bus), text: 'Free Shuttle'),
            Tab(icon: Icon(Icons.directions_car), text: 'With Driver'),
            Tab(icon: Icon(Icons.car_rental), text: 'Rent Car'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildShuttleTab(),
            _buildIndividualTab(),
            _buildRentalTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildShuttleTab() {
    if (_isLoadingShuttles) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_shuttleError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_shuttleError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingShuttles = true;
                  _shuttleError = null;
                });
                _loadShuttles();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_shuttles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No shuttles available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShuttles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shuttles.length,
        itemBuilder: (context, index) {
          final shuttle = _shuttles[index];
          return ShuttleCard(
            shuttle: shuttle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShuttleDetailPage(
                  shuttle: shuttle,
                  eventId: widget.eventId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndividualTab() {
    if (_isLoadingIndividual) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_individualError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_individualError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingIndividual = true;
                  _individualError = null;
                });
                _loadIndividualCars();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_individualCars.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No cars with drivers available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIndividualCars,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _individualCars.length,
        itemBuilder: (context, index) {
          final car = _individualCars[index];
          return CarCard(
            car: car,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CarDetailPage(car: car, eventId: widget.eventId),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRentalTab() {
    if (_isLoadingRental) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rentalError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_rentalError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingRental = true;
                  _rentalError = null;
                });
                _loadRentalCars();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_rentalCars.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.car_rental_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No rental cars available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRentalCars,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rentalCars.length,
        itemBuilder: (context, index) {
          final car = _rentalCars[index];
          return CarCard(
            car: car,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CarDetailPage(car: car, eventId: widget.eventId),
              ),
            ),
          );
        },
      ),
    );
  }
}
