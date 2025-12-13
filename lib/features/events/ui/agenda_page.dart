import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/event_context_service.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/profile_dropdown.dart';

class AgendaPage extends ConsumerStatefulWidget {
  final String eventId;
  const AgendaPage({super.key, required this.eventId});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  // Tab state
  bool _isProgramSelected = true;
  int _selectedDayIndex = 0;
  // String _selectedFilter = 'All'; // Commented out - filters hidden for now
  String _searchQuery = '';
  int? _expandedCardIndex;

  // Data
  List<Map<String, dynamic>> _days = [];
  List<Map<String, dynamic>> _episodes = [];
  final Set<int> _favoriteIds = {};
  bool _isLoadingDays = true;
  bool _isLoadingEpisodes = true;

  // Filters - commented out for now
  // final List<String> _filters = [
  //   'All',
  //   'Forum Hall',
  //   'Presentation Hall',
  //   'Hall 50A',
  //   'Hall 50B',
  // ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndFetch();
    });
  }

  Future<void> _initializeAndFetch() async {
    // Ensure the event context is loaded for this event
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await eventContextService.ensureEventContext(eventId);
    }
    _fetchAgendaDays();
  }

  Future<void> _fetchAgendaDays() async {
    try {
      // Use EventContextService for site_id
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/agenda/days?site_id=$siteId',
            )
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/agenda/days');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _days = data.map((d) {
              final date = DateTime.tryParse(d['date'] ?? '');
              return {
                'id': d['id'],
                'date': d['date'],
                'label': d['label'],
                'day': date?.day ?? 0,
                'weekday': _getWeekdayName(date?.weekday ?? 1),
              };
            }).toList();
            _isLoadingDays = false;
          });

          if (_days.isNotEmpty) {
            _fetchEpisodesForDay(_days[0]['id']);
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingDays = false);
      }
    } catch (e) {
      debugPrint('Error fetching agenda days: $e');
      if (mounted) setState(() => _isLoadingDays = false);
    }
  }

  Future<void> _fetchEpisodesForDay(int dayId) async {
    setState(() => _isLoadingEpisodes = true);

    try {
      // Use EventContextService for site_id
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/agenda/day/$dayId/episodes?site_id=$siteId',
            )
          : Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/agenda/day/$dayId/episodes',
            );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _episodes = data.map((e) => _parseEpisode(e)).toList();
            _isLoadingEpisodes = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingEpisodes = false);
      }
    } catch (e) {
      debugPrint('Error fetching episodes: $e');
      if (mounted) setState(() => _isLoadingEpisodes = false);
    }
  }

  /// Build full image URL from relative path
  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Prepend tourism base URL for relative paths
    return '${AppConfig.tourismApiBaseUrl}$path';
  }

  Map<String, dynamic> _parseEpisode(Map<String, dynamic> e) {
    final startTime = DateTime.tryParse(e['start_time'] ?? '');
    final endTime = DateTime.tryParse(e['end_time'] ?? '');

    String timeStr = '';
    if (startTime != null && endTime != null) {
      timeStr = '${_formatTime(startTime)}-${_formatTime(endTime)}';
    }

    // Parse sponsors
    List<Map<String, dynamic>> sponsors = [];
    if (e['sponsors'] != null) {
      sponsors = (e['sponsors'] as List)
          .map(
            (s) => {
              'id': s['id'],
              'name': s['name'] ?? '',
              'logo': _buildImageUrl(s['logo'] ?? s['logo_url']),
              'tier': s['tier'] ?? 'general',
            },
          )
          .toList();
    }

    // Parse speakers
    List<Map<String, dynamic>> speakers = [];
    if (e['speakers'] != null) {
      speakers = (e['speakers'] as List)
          .map(
            (s) => {
              'id': s['id'],
              'name': s['fullname'] ?? s['name'] ?? '',
              'title': s['position'] ?? '',
              'company': s['company'] ?? '',
              'photo': _buildImageUrl(s['photo'] ?? s['photo_url']),
            },
          )
          .toList();
    }

    // Parse moderators
    List<Map<String, dynamic>> moderators = [];
    if (e['moderators'] != null) {
      moderators = (e['moderators'] as List)
          .map(
            (m) => {
              'id': m['id'],
              'name': m['fullname'] ?? m['name'] ?? '',
              'title': m['position'] ?? '',
              'company': m['company'] ?? '',
              'photo': _buildImageUrl(m['photo'] ?? m['photo_url']),
            },
          )
          .toList();
    }

    return {
      'id': e['id'],
      'time': timeStr,
      'title': e['title'] ?? '',
      'date': _formatDate(startTime),
      'location': e['location'] ?? '',
      'description': e['description_md'] ?? '',
      'sponsor': sponsors.isNotEmpty
          ? {
              'name': sponsors[0]['name'],
              'tier': _getTierLabel(sponsors[0]['tier']),
              'logo': sponsors[0]['logo'],
            }
          : null,
      'speakers': speakers,
      'moderator': moderators.isNotEmpty ? moderators[0] : null,
      'isFavorite': _favoriteIds.contains(e['id']),
      'hall': e['location'] ?? '',
    };
  }

  String _getWeekdayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday.clamp(1, 7)];
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _getTierLabel(String tier) {
    final t = tier.toLowerCase();
    if (t == 'gold') return 'Gold Sponsor';
    if (t == 'silver') return 'Silver Sponsor';
    if (t == 'bronze') return 'Bronze Sponsor';
    if (t == 'platinum') return 'Platinum Sponsor';
    if (t == 'diamond') return 'Diamond Sponsor';
    if (t == 'premier') return 'Premier Sponsor';
    return 'Sponsor';
  }

  void _toggleProfile() {
    setState(() => _isProfileOpen = !_isProfileOpen);
  }

  void _closeProfile() {
    if (_isProfileOpen) setState(() => _isProfileOpen = false);
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
      for (var ep in _episodes) {
        if (ep['id'] == id) {
          ep['isFavorite'] = _favoriteIds.contains(id);
        }
      }
    });
  }

  void _toggleExpand(int index) {
    setState(() {
      _expandedCardIndex = _expandedCardIndex == index ? null : index;
    });
  }

  void _selectDay(int index) {
    setState(() {
      _selectedDayIndex = index;
      _expandedCardIndex = null;
    });
    if (_days.isNotEmpty && index < _days.length) {
      _fetchEpisodesForDay(_days[index]['id']);
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    return _episodes.where((item) {
      // Filter by favorites
      if (!_isProgramSelected && !item['isFavorite']) return false;

      // Filter by hall - commented out for now
      // if (_selectedFilter != 'All') {
      //   final hall = (item['hall'] ?? '').toString().toLowerCase();
      //   final filter = _selectedFilter.toLowerCase();
      //   if (!hall.contains(filter.replaceAll(' hall', ''))) return false;
      // }

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return (item['title'] as String).toLowerCase().contains(query) ||
            (item['description'] as String).toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 12.0 : 50.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: GestureDetector(
        onTap: _closeProfile,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: isMobile ? 12 : 20,
                    ),
                    child: _buildHeader(isMobile),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 12 : 20,
                    ),
                    child: _buildSearchBar(isMobile),
                  ),
                ),

                // Filter Chips - Commented out for now
                // SliverToBoxAdapter(
                //   child: Padding(
                //     padding: EdgeInsets.only(
                //       left: horizontalPadding,
                //       right: horizontalPadding,
                //       bottom: 10,
                //     ),
                //     child: _buildFilterChips(isMobile),
                //   ),
                // ),

                // Day Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 10,
                    ),
                    child: _isLoadingDays
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _buildDayTabs(isMobile),
                  ),
                ),

                // Agenda Items
                if (_isLoadingEpisodes)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  )
                else if (_filteredItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No agenda items found',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 15,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _filteredItems[index];
                        final isExpanded = _expandedCardIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildAgendaCard(
                            item,
                            index,
                            isExpanded,
                            isMobile,
                          ),
                        );
                      }, childCount: _filteredItems.length),
                    ),
                  ),
              ],
            ),

            // Profile Dropdown
            if (_isProfileOpen)
              Positioned(
                top: isMobile ? 55 : 70,
                right: horizontalPadding,
                child: ProfileDropdown(
                  onClose: _closeProfile,
                  onLogout: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildMenuButton(isMobile),
                  const SizedBox(width: 10),
                  Text(
                    'Agenda',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF1F1F6),
                    ),
                  ),
                  const Spacer(),
                  CustomAppBar(
                    onProfileTap: _toggleProfile,
                    onNotificationTap: () {
                      _closeProfile();
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                    isMobile: isMobile,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(child: _buildToggle(isMobile)),
            ],
          )
        : Row(
            children: [
              _buildMenuButton(isMobile),
              const SizedBox(width: 20),
              Text(
                'Agenda',
                style: GoogleFonts.montserrat(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF1F1F6),
                ),
              ),
              const Spacer(),
              _buildToggle(isMobile),
              const SizedBox(width: 30),
              CustomAppBar(
                onProfileTap: _toggleProfile,
                onNotificationTap: () {
                  _closeProfile();
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                isMobile: isMobile,
              ),
            ],
          );
  }

  Widget _buildMenuButton(bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/events/${widget.eventId}/menu');
          }
        },
        child: Container(
          width: isMobile ? 36 : 50,
          height: isMobile ? 36 : 50,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 20, height: 2.5, color: const Color(0xFFF1F1F6)),
              const SizedBox(height: 4),
              Container(width: 20, height: 2.5, color: const Color(0xFFF1F1F6)),
              const SizedBox(height: 4),
              Container(width: 20, height: 2.5, color: const Color(0xFFF1F1F6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Program', _isProgramSelected, () {
            setState(() => _isProgramSelected = true);
          }, isMobile),
          _buildToggleButton('Favourite', !_isProgramSelected, () {
            setState(() => _isProgramSelected = false);
          }, isMobile),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 53,
          vertical: isMobile ? 10 : 17,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 14 : 26,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      height: isMobile ? 45 : 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F6).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: const Color(0xFFF1F1F6),
            size: isMobile ? 22 : 36,
          ),
          SizedBox(width: isMobile ? 10 : 20),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : 20,
                color: const Color(0xFFF1F1F6),
              ),
              decoration: InputDecoration(
                hintText: 'Search by event name',
                hintStyle: GoogleFonts.roboto(
                  fontSize: isMobile ? 14 : 20,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFF1F1F6),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filter chips - commented out for now
  // Widget _buildFilterChips(bool isMobile) {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       children: _filters.map((filter) {
  //         final isSelected = _selectedFilter == filter;
  //         return Padding(
  //           padding: const EdgeInsets.only(right: 8),
  //           child: GestureDetector(
  //             onTap: () => setState(() => _selectedFilter = filter),
  //             child: Container(
  //               padding: EdgeInsets.symmetric(
  //                 horizontal: isMobile ? 16 : 47,
  //                 vertical: isMobile ? 8 : 14,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: isSelected ? const Color(0xFF151A4A) : const Color(0xFF9CA4CC),
  //                 borderRadius: BorderRadius.circular(41.5),
  //               ),
  //               child: Text(
  //                 filter,
  //                 style: GoogleFonts.roboto(
  //                   fontSize: isMobile ? 14 : 33,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  Widget _buildDayTabs(bool isMobile) {
    if (_days.isEmpty) {
      return Center(
        child: Text(
          'No agenda days available',
          style: GoogleFonts.roboto(fontSize: 16, color: Colors.white70),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_days.length, (index) {
          final day = _days[index];
          final isSelected = _selectedDayIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _selectDay(index),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 20,
                  vertical: isMobile ? 10 : 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF151A4A) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      '${day['day']}',
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 16 : 25,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFFF4F4F2)
                            : const Color(0xFF20306C),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: isMobile ? 25 : 45,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: isSelected
                          ? const Color(0xFFF4F4F2)
                          : const Color(0xFF20306C),
                    ),
                    Text(
                      day['weekday'],
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 16 : 25,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFFF4F4F2)
                            : const Color(0xFF20306C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAgendaCard(
    Map<String, dynamic> item,
    int index,
    bool isExpanded,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Badge - 86px width for mobile
        Container(
          width: isMobile ? 86 : 236,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 12 : 22,
            horizontal: isMobile ? 8 : 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF9CA4CC),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
          ),
          child: Center(
            child: Text(
              item['time'],
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 12 : 33,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF1F1F6),
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 31),
        // Card Content - clickable to expand/collapse
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleExpand(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
              ),
              child: isExpanded
                  ? _buildExpandedCard(item, index, isMobile)
                  : _buildCollapsedCard(item, index, isMobile),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedCard(
    Map<String, dynamic> item,
    int index,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 10 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildBadge(Icons.calendar_today, item['date'], isMobile),
                    _buildBadge(
                      Icons.location_on_outlined,
                      item['location'],
                      isMobile,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFavorite(item['id']),
                child: Icon(
                  item['isFavorite'] ? Icons.star : Icons.star_border,
                  size: isMobile ? 22 : 30,
                  color: item['isFavorite']
                      ? Colors.amber
                      : const Color(0xFF949494),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 20),
          // Title
          Text(
            item['title'],
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 16 : 35,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151938),
            ),
          ),
          SizedBox(height: isMobile ? 6 : 15),
          // Description
          Text(
            item['description'],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 12 : 14,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          // Sponsor
          if (item['sponsor'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                Column(
                  children: [
                    Container(
                      width: isMobile ? 60 : 120,
                      height: isMobile ? 35 : 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child:
                          item['sponsor']['logo'] != null &&
                              item['sponsor']['logo'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item['sponsor']['logo'],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    item['sponsor']['name'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                      fontSize: isMobile ? 8 : 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                item['sponsor']['name'] ?? '',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  fontSize: isMobile ? 10 : 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['sponsor']['tier'] ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 10 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDDAC17),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          // Expand hint
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_arrow_down,
                size: isMobile ? 20 : 28,
                color: const Color(0xFF9CA4CC),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard(
    Map<String, dynamic> item,
    int index,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 10 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildBadge(Icons.calendar_today, item['date'], isMobile),
                    _buildBadge(
                      Icons.location_on_outlined,
                      item['location'],
                      isMobile,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFavorite(item['id']),
                child: Icon(
                  item['isFavorite'] ? Icons.star : Icons.star_border,
                  size: 30,
                  color: item['isFavorite']
                      ? Colors.amber
                      : const Color(0xFF949494),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 20),
          // Title
          Text(
            item['title'],
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 35,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151938),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 20),
          // Description
          Text(
            item['description'],
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 14 : 20,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Moderator & Sponsor Row
          if (item['moderator'] != null || item['sponsor'] != null)
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                if (item['moderator'] != null)
                  _buildModerator(item['moderator'], isMobile),
                if (item['sponsor'] != null)
                  _buildSponsor(item['sponsor'], isMobile),
              ],
            ),
          // Speakers Section - Carousel
          if (item['speakers'] != null &&
              (item['speakers'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Speakers:',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 16 : 25,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF151938),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: isMobile ? 160 : 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (item['speakers'] as List).length,
                itemBuilder: (context, speakerIndex) {
                  final speaker = item['speakers'][speakerIndex];
                  return _buildSpeakerCard(speaker, isMobile);
                },
              ),
            ),
          ],
          const SizedBox(height: 15),
          // Collapse hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_arrow_up,
                size: isMobile ? 28 : 46,
                color: const Color(0xFF3C4494),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 12,
        vertical: isMobile ? 4 : 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9CA4CC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 14 : 24, color: const Color(0xFF9CA4CC)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 10 : 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerator(Map<String, dynamic> moderator, bool isMobile) {
    final photoUrl = moderator['photo']?.toString() ?? '';

    return Column(
      children: [
        Container(
          width: isMobile ? 80 : 140,
          height: isMobile ? 80 : 130,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
          ),
          child: photoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                )
              : const Icon(Icons.person, size: 40, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          'Moderator',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 14 : 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF151938),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: isMobile ? 100 : 200,
          child: Text(
            moderator['name'] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 11 : 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3C4494),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSponsor(Map<String, dynamic> sponsor, bool isMobile) {
    final logoUrl = sponsor['logo']?.toString() ?? '';

    return Column(
      children: [
        Container(
          width: isMobile ? 80 : 215,
          height: isMobile ? 55 : 134,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: logoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        sponsor['name'] ?? '',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 12 : 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    sponsor['name'] ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: isMobile ? 12 : 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          sponsor['tier'] ?? '',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 12 : 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFDDAC17),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerCard(Map<String, dynamic> speaker, bool isMobile) {
    final photoUrl = speaker['photo']?.toString() ?? '';

    return Container(
      width: isMobile ? 130 : 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
            ),
          ),
          // Info - fixed height to prevent overflow
          Container(
            height: isMobile ? 55 : 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  speaker['name'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 11 : 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    speaker['title'] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: isMobile ? 9 : 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
