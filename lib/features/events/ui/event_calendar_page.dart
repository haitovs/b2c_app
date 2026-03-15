import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../events/providers/event_providers.dart';
import 'widgets/event_card.dart';

class EventCalendarPage extends ConsumerStatefulWidget {
  const EventCalendarPage({super.key});

  @override
  ConsumerState<EventCalendarPage> createState() => _EventCalendarPageState();
}

class _EventCalendarPageState extends ConsumerState<EventCalendarPage> {
  // Search Controller
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Cached event state
  List<dynamic> _allEvents = [];
  List<dynamic> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEvents);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await ref.read(eventServiceProvider).fetchEvents();
      if (mounted) {
        setState(() {
          _allEvents = events;
          _filteredEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterEvents() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents.where((event) {
          final title = (event['title'] ?? '').toString().toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEvents);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: title + profile icon
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: isMobile ? 16 : 24,
              ),
              child: Row(
                children: [
                  Text(
                    'Events',
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.go('/profile'),
                    icon: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: isMobile ? 26 : 30,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
              ),
              child: Container(
                height: isMobile ? 45.0 : 50.0,
                constraints: BoxConstraints(maxWidth: 1310),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white70,
                      size: isMobile ? 24 : 28,
                    ),
                    hintText: "Search by event name",
                    hintStyle: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 16 : 18,
                      color: Colors.white54,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            SizedBox(height: isMobile ? 20 : 32),

            // Scrollable Event List
            Expanded(
              child: _buildEventList(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(bool isMobile) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildEventListContent(isMobile),
    );
  }

  Widget _buildEventListContent(bool isMobile) {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Text(
          "Error: $_error",
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Text(
          _searchController.text.trim().isEmpty
              ? "No events found"
              : "No events match your search",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Scrollbar(
      key: const ValueKey('list'),
      controller: _scrollController,
      thumbVisibility: true,
      thickness: isMobile ? 4 : 8,
      radius: const Radius.circular(12),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: 50,
          right: 10,
          left: isMobile ? 20 : 40,
        ),
        child: Column(
          children: _filteredEvents.map((event) {
            return Column(
              children: [
                EventCard(
                  title: event['title'] ?? 'No Title',
                  date: event['date_str'] ?? '',
                  location: event['location'] ?? '',
                  imageUrl: event['image_url'] ?? '',
                  logoUrl: event['logo_url'],
                  eventStartTime:
                      DateTime.tryParse(event['start_time'] ?? '') ??
                      DateTime.now(),
                  onTap: () {
                    final id = event['id'];
                    if (id != null) {
                      context.go('/events/$id');
                    } else {
                      AppSnackBar.showInfo(context, 'Event ID missing');
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
