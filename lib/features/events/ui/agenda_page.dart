import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import '../providers/event_providers.dart';

class AgendaPage extends ConsumerStatefulWidget {
  final String eventId;
  const AgendaPage({super.key, required this.eventId});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  bool _isProgramSelected = true;
  int _selectedDayIndex = 0;
  String _searchQuery = '';
  String _selectedLocation = 'All';
  int? _expandedCardIndex;
  bool _showSortDropdown = false;

  List<Map<String, dynamic>> _days = [];
  List<Map<String, dynamic>> _episodes = [];
  final Set<int> _favoriteIds = {};
  bool _isLoadingDays = true;
  bool _isLoadingEpisodes = true;

  String get _favoritesKey => 'agenda_favorites_${widget.eventId}';

  List<String> get _availableLocations {
    final locations = <String>{'All'};
    for (final ep in _episodes) {
      final loc = ep['location'] as String? ?? '';
      if (loc.isNotEmpty) locations.add(loc);
    }
    return locations.toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
      _fetchAgendaDays();
    });
  }

  void _loadFavorites() {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = prefs.getString(_favoritesKey);
    if (json != null) {
      try {
        final List<dynamic> ids = jsonDecode(json);
        _favoriteIds.addAll(ids.cast<int>());
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading favorites: $e');
      }
    }
  }

  void _saveFavorites() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_favoritesKey, jsonEncode(_favoriteIds.toList()));
  }

  Future<void> _fetchAgendaDays() async {
    try {
      final eventId = int.tryParse(widget.eventId) ?? 0;
      final agendaService = ref.read(agendaServiceProvider);
      final data = await agendaService.fetchAgendaDays(eventId: eventId);

      if (mounted) {
        setState(() {
          _days = data.map((d) {
            final raw = d as Map<String, dynamic>;
            final date = DateTime.tryParse(raw['date'] ?? '');
            return {
              'id': raw['id'],
              'date': raw['date'],
              'label': raw['label'],
              'day': date?.day ?? 0,
              'weekday': _getWeekdayShort(date?.weekday ?? 1),
            };
          }).toList();
          _isLoadingDays = false;
        });

        if (_days.isNotEmpty) {
          _fetchEpisodesForDay(_days[0]['id']);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching agenda days: $e');
      if (mounted) setState(() => _isLoadingDays = false);
    }
  }

  Future<void> _fetchEpisodesForDay(int dayId) async {
    setState(() => _isLoadingEpisodes = true);

    try {
      final agendaService = ref.read(agendaServiceProvider);
      final data = await agendaService.fetchEpisodesForDay(dayId);

      if (mounted) {
        setState(() {
          _episodes = data
              .map((e) => _parseEpisode(e as Map<String, dynamic>))
              .toList();
          _isLoadingEpisodes = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching episodes: $e');
      if (mounted) setState(() => _isLoadingEpisodes = false);
    }
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Relative paths are from Tourism API
    return '${AppConfig.tourismApiBaseUrl}$path';
  }

  Map<String, dynamic> _parseEpisode(Map<String, dynamic> e) {
    final startTime = DateTime.tryParse(e['start_time'] ?? '');
    final endTime = DateTime.tryParse(e['end_time'] ?? '');

    String startStr = '';
    String endStr = '';
    if (startTime != null) startStr = _formatTime(startTime);
    if (endTime != null) endStr = _formatTime(endTime);

    List<Map<String, dynamic>> sponsors = [];
    if (e['sponsors'] != null) {
      sponsors = (e['sponsors'] as List)
          .map((s) => {
                'id': s['id'],
                'name': s['name'] ?? '',
                'logo': _buildImageUrl(s['logo'] ?? s['logo_url']),
                'tier': (s['tier'] ?? 'general').toString().toLowerCase(),
              })
          .toList();
    }

    List<Map<String, dynamic>> speakers = [];
    if (e['speakers'] != null) {
      speakers = (e['speakers'] as List)
          .map((s) => {
                'id': s['id'],
                'name': s['fullname'] ?? s['name'] ?? '',
                'position': s['position'] ?? '',
                'company': s['company'] ?? '',
                'country': s['country'] ?? '',
                'photo': _buildImageUrl(s['photo'] ?? s['photo_url']),
              })
          .toList();
    }

    List<Map<String, dynamic>> moderators = [];
    if (e['moderators'] != null) {
      moderators = (e['moderators'] as List)
          .map((m) => {
                'id': m['id'],
                'name': m['fullname'] ?? m['name'] ?? '',
                'position': m['position'] ?? '',
                'company': m['company'] ?? '',
                'photo': _buildImageUrl(m['photo'] ?? m['photo_url']),
              })
          .toList();
    }

    return {
      'id': e['id'],
      'startTime': startStr,
      'endTime': endStr,
      'title': e['title'] ?? '',
      'date': _formatDate(startTime),
      'location': e['location'] ?? '',
      'description': e['description_md'] ?? '',
      'speech_theme': e['speech_theme'] ?? '',
      'sponsor': sponsors.isNotEmpty ? sponsors[0] : null,
      'speakers': speakers,
      'moderator': moderators.isNotEmpty ? moderators[0] : null,
      'isFavorite': _favoriteIds.contains(e['id']),
    };
  }

  String _getWeekdayShort(int weekday) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday.clamp(1, 7)];
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${dt.day} ${months[dt.month].substring(0, 3).toLowerCase()} ${dt.year}';
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
    _saveFavorites();
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
      if (!_isProgramSelected && !item['isFavorite']) return false;
      if (_selectedLocation != 'All') {
        final loc = item['location'] as String? ?? '';
        if (loc != _selectedLocation) return false;
      }
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
    final hPad = isMobile ? 16.0 : 32.0;

    return GestureDetector(
      onTap: () {
        if (_showSortDropdown) setState(() => _showSortDropdown = false);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: CustomScrollView(
          slivers: [
            // Top divider
            SliverToBoxAdapter(
              child: Container(
                height: 1,
                color: const Color(0xFFCACACA),
              ),
            ),

            // Title + Toggle Row
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile) ...[
                      Text(
                        'Event Agenda',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFCACACA), height: 1),
                      const SizedBox(height: 16),
                      _ProgramToggle(
                        isProgramSelected: _isProgramSelected,
                        isMobile: isMobile,
                        onProgramTap: () =>
                            setState(() => _isProgramSelected = true),
                        onFavouriteTap: () =>
                            setState(() => _isProgramSelected = false),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            'Event Agenda',
                            style: GoogleFonts.montserrat(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 430,
                            child: _ProgramToggle(
                              isProgramSelected: _isProgramSelected,
                              isMobile: isMobile,
                              onProgramTap: () =>
                                  setState(() => _isProgramSelected = true),
                              onFavouriteTap: () =>
                                  setState(() => _isProgramSelected = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFCACACA), height: 1),
                    ],
                  ],
                ),
              ),
            ),

            // Search + Sort Row
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                child: _SearchSortRow(
                  isMobile: isMobile,
                  selectedLocation: _selectedLocation,
                  locations: _availableLocations,
                  showDropdown: _showSortDropdown,
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  onSortTap: () =>
                      setState(() => _showSortDropdown = !_showSortDropdown),
                  onLocationSelected: (loc) => setState(() {
                    _selectedLocation = loc;
                    _showSortDropdown = false;
                  }),
                ),
              ),
            ),

            // Day Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                child: _isLoadingDays
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : isMobile
                        ? _MobileDaySelector(
                            days: _days,
                            selectedIndex: _selectedDayIndex,
                            onDaySelected: _selectDay,
                          )
                        : _StepperDaySelector(
                            days: _days,
                            selectedIndex: _selectedDayIndex,
                            onDaySelected: _selectDay,
                          ),
              ),
            ),

            // Agenda Items
            if (_isLoadingEpisodes)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                ),
              )
            else if (_filteredItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      _isProgramSelected
                          ? 'No agenda items found'
                          : 'No favourited items yet',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: const Color(0xFF757A8A),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _filteredItems[index];
                      final isExpanded = _expandedCardIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: isMobile
                            ? _MobileEpisodeCard(
                                item: item,
                                isExpanded: isExpanded,
                                onToggleExpand: () => _toggleExpand(index),
                                onToggleFavorite: () =>
                                    _toggleFavorite(item['id']),
                                eventId: widget.eventId,
                              )
                            : _DesktopEpisodeRow(
                                item: item,
                                isExpanded: isExpanded,
                                onToggleExpand: () => _toggleExpand(index),
                                onToggleFavorite: () =>
                                    _toggleFavorite(item['id']),
                                eventId: widget.eventId,
                              ),
                      );
                    },
                    childCount: _filteredItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Program Toggle
// =============================================================================

class _ProgramToggle extends StatelessWidget {
  final bool isProgramSelected;
  final bool isMobile;
  final VoidCallback onProgramTap;
  final VoidCallback onFavouriteTap;

  const _ProgramToggle({
    required this.isProgramSelected,
    required this.isMobile,
    required this.onProgramTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = isMobile ? 40.0 : 43.0;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          _toggleButton(
            label: 'Event Program',
            isActive: isProgramSelected,
            onTap: onProgramTap,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
          ),
          _toggleButton(
            label: 'My Program',
            isActive: !isProgramSelected,
            onTap: onFavouriteTap,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(5)),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required BorderRadius borderRadius,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : const Color(0xFFE6E7F2),
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Search + Sort Row
// =============================================================================

class _SearchSortRow extends StatelessWidget {
  final bool isMobile;
  final String selectedLocation;
  final List<String> locations;
  final bool showDropdown;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSortTap;
  final ValueChanged<String> onLocationSelected;

  const _SearchSortRow({
    required this.isMobile,
    required this.selectedLocation,
    required this.locations,
    required this.showDropdown,
    required this.onSearchChanged,
    required this.onSortTap,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            // Search bar
            Expanded(
              child: TextField(
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by event name or ID',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFCBCBCB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFCBCBCB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sort button
            if (isMobile)
              GestureDetector(
                onTap: onSortTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFCACACA)),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    size: 20,
                    color: Color(0xFF757A8A),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onSortTap,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFCACACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sort by: $selectedLocation',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF757A8A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Color(0xFF757A8A),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        // Dropdown overlay
        if (showDropdown)
          Positioned(
            top: 52,
            right: 0,
            child: Container(
              width: isMobile ? 200 : 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB5B5B5).withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: locations.map((loc) {
                  final isSelected = selectedLocation == loc;
                  return InkWell(
                    onTap: () => onLocationSelected(loc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFF757A8A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : const Color(0xFF292D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Mobile Day Selector (horizontal scroll pills)
// =============================================================================

class _MobileDaySelector extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  const _MobileDaySelector({
    required this.days,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Center(
        child: Text(
          'No agenda days available',
          style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF757A8A)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(days.length, (index) {
          final isSelected = selectedIndex == index;
          final prevSelected = index > 0 && selectedIndex == index - 1;
          final isFirst = index == 0;
          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: SizedBox(
              width: 110,
              height: 36,
              child: CustomPaint(
                painter: _ArrowTabPainter(
                  isSelected: isSelected,
                  isFirst: isFirst,
                  prevSelected: prevSelected,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFCED4E3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFF345790),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Day ${index + 1}',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF345790),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Desktop Stepper Day Selector
// =============================================================================

class _StepperDaySelector extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  const _StepperDaySelector({
    required this.days,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Center(
        child: Text(
          'No agenda days available',
          style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF757A8A)),
        ),
      );
    }

    return Container(
      height: 43,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD4D4D4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(days.length, (index) {
          final isSelected = selectedIndex == index;
          final prevSelected = index > 0 && selectedIndex == index - 1;
          final isFirst = index == 0;

          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: SizedBox(
              width: 120,
              child: CustomPaint(
                painter: _ArrowTabPainter(
                  isSelected: isSelected,
                  isFirst: isFirst,
                  prevSelected: prevSelected,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFCED4E3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFF345790),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Day ${index + 1}',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF345790),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Custom painter for arrow/chevron day tabs.
///
/// Selected tab: solid blue arrow shape (full rectangle + arrow tip on right,
/// left side has inward notch if previous tab exists).
///
/// Unselected tab: transparent, only draws the chevron divider line on right
/// (unless previous tab was selected — then left side gets a notch cutout).
class _ArrowTabPainter extends CustomPainter {
  final bool isSelected;
  final bool isFirst;
  final bool prevSelected;

  static const _arrow = 12.0;
  static const _primaryColor = AppTheme.primaryColor;
  static const _dividerColor = Color(0xFFD4D4D4);

  _ArrowTabPainter({
    required this.isSelected,
    required this.isFirst,
    required this.prevSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    if (isSelected) {
      final paint = Paint()
        ..color = _primaryColor
        ..style = PaintingStyle.fill;
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Fill entire rectangle blue
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

      // Cut out white notch on left (inward arrow) if not first tab
      if (!isFirst) {
        final leftNotch = Path()
          ..moveTo(0, 0)
          ..lineTo(_arrow, h / 2)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(leftNotch, whitePaint);
      }

      // Cut out white triangles on right to form the arrow tip
      // Top-right triangle
      final topRight = Path()
        ..moveTo(w - _arrow, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h / 2)
        ..close();
      canvas.drawPath(topRight, whitePaint);

      // Bottom-right triangle
      final bottomRight = Path()
        ..moveTo(w - _arrow, h)
        ..lineTo(w, h)
        ..lineTo(w, h / 2)
        ..close();
      canvas.drawPath(bottomRight, whitePaint);
    } else {
      // --- UNSELECTED: transparent background ---

      // If previous tab was selected, paint white over the left notch area
      // to cover the blue rectangle that bleeds from the previous tab
      if (prevSelected) {
        final whitePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final notch = Path()
          ..moveTo(0, 0)
          ..lineTo(_arrow, h / 2)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(notch, whitePaint);
      }

      // Draw chevron divider line on the right
      final linePaint = Paint()
        ..color = _dividerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final line = Path()
        ..moveTo(w - _arrow, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w - _arrow, h);
      canvas.drawPath(line, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowTabPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.prevSelected != prevSelected;
  }
}

// =============================================================================
// Desktop Episode Row (time LEFT, card RIGHT)
// =============================================================================

class _DesktopEpisodeRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleFavorite;
  final String eventId;

  const _DesktopEpisodeRow({
    required this.item,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleFavorite,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column — single line, no wrap
        SizedBox(
          width: 160,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${item['startTime']} - ${item['endTime']}',
                maxLines: 1,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Card
        Expanded(
          child: GestureDetector(
            onTap: onToggleExpand,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                children: [
                  isExpanded
                      ? _ExpandedCardContent(
                          item: item,
                          isMobile: false,
                          onToggleFavorite: onToggleFavorite,
                          eventId: eventId,
                        )
                      : _CollapsedCardContent(
                          item: item,
                          isMobile: false,
                          onToggleFavorite: onToggleFavorite,
                          eventId: eventId,
                        ),
                  if (isExpanded)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF9CA4CC),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(100),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Mobile Episode Card (time above, card below)
// =============================================================================

class _MobileEpisodeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleFavorite;
  final String eventId;

  const _MobileEpisodeCard({
    required this.item,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleFavorite,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        Text(
          '${item['startTime']} - ${item['endTime']}',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        // Card
        GestureDetector(
          onTap: onToggleExpand,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 3.4,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  isExpanded
                      ? _ExpandedCardContent(
                          item: item,
                          isMobile: true,
                          onToggleFavorite: onToggleFavorite,
                          eventId: eventId,
                        )
                      : _CollapsedCardContent(
                          item: item,
                          isMobile: true,
                          onToggleFavorite: onToggleFavorite,
                          eventId: eventId,
                        ),
                  if (isExpanded)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF9CA4CC),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(100),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Collapsed Card Content
// =============================================================================

class _CollapsedCardContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isMobile;
  final VoidCallback onToggleFavorite;
  final String eventId;

  const _CollapsedCardContent({
    required this.item,
    required this.isMobile,
    required this.onToggleFavorite,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final sponsor = item['sponsor'] as Map<String, dynamic>?;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if ((item['date'] as String?)?.isNotEmpty == true)
                      _MetaBadge(
                        icon: Icons.calendar_today_outlined,
                        text: item['date'],
                        isMobile: isMobile,
                      ),
                    if ((item['location'] as String?)?.isNotEmpty == true)
                      _MetaBadge(
                        icon: Icons.location_on_outlined,
                        text: item['location'],
                        isMobile: isMobile,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  item['title'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151838),
                  ),
                ),
                const SizedBox(height: 8),

                // Description (truncated to 3 lines)
                Text(
                  item['description'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Read more
                Row(
                  children: [
                    Text(
                      'Read more',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA4CC),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xFF9CA4CC),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right column: star + sponsor
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Favorite star
              GestureDetector(
                onTap: onToggleFavorite,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Icon(
                    item['isFavorite'] == true
                        ? Icons.star
                        : Icons.star_border,
                    size: isMobile ? 22 : 28,
                    color: item['isFavorite'] == true
                        ? Colors.amber
                        : const Color(0xFF939393),
                  ),
                ),
              ),
              // Sponsor below star
              if (sponsor != null)
                _SponsorWidget(sponsor: sponsor, isMobile: isMobile, eventId: eventId),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Expanded Card Content
// =============================================================================

class _ExpandedCardContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isMobile;
  final VoidCallback onToggleFavorite;
  final String eventId;

  const _ExpandedCardContent({
    required this.item,
    required this.isMobile,
    required this.onToggleFavorite,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final speakers = (item['speakers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final moderator = item['moderator'] as Map<String, dynamic>?;
    final sponsor = item['sponsor'] as Map<String, dynamic>?;
    final speechTheme = item['speech_theme'] as String? ?? '';

    if (isMobile) {
      return _buildMobileLayout(speakers, moderator, sponsor, speechTheme);
    }
    return _buildDesktopLayout(
        context, speakers, moderator, sponsor, speechTheme);
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<Map<String, dynamic>> speakers,
    Map<String, dynamic>? moderator,
    Map<String, dynamic>? sponsor,
    String speechTheme,
  ) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if ((item['date'] as String?)?.isNotEmpty == true)
                          _MetaBadge(
                            icon: Icons.calendar_today_outlined,
                            text: item['date'],
                            isMobile: false,
                          ),
                        if ((item['location'] as String?)?.isNotEmpty == true)
                          _MetaBadge(
                            icon: Icons.location_on_outlined,
                            text: item['location'],
                            isMobile: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF151938),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      item['description'] ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.6,
                      ),
                    ),

                    // Topic
                    if (speechTheme.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Topic: $speechTheme',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF151938),
                        ),
                      ),
                    ],

                    // Speakers
                    if (speakers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Speakers:',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF151938),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SpeakerCarouselDesktop(
                          speakers: speakers, eventId: eventId),
                    ],

                    // Collapse hint
                    const SizedBox(height: 16),
                    Center(
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: sponsor + moderator column
              const SizedBox(width: 20),
              SizedBox(
                width: 160,
                child: Column(
                  children: [
                    // Spacing to account for star in top-right
                    const SizedBox(height: 40),

                    // Sponsor
                    if (sponsor != null) ...[
                      _SponsorWidget(
                          sponsor: sponsor, isMobile: false, eventId: eventId),
                      const SizedBox(height: 20),
                    ],

                    // Moderator
                    if (moderator != null) ...[
                      Text(
                        'Moderator',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF151938),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ModeratorCardCompact(
                          moderator: moderator, eventId: eventId),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Favorite star — always top-right corner
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onToggleFavorite,
            child: Icon(
              item['isFavorite'] == true
                  ? Icons.star
                  : Icons.star_border,
              size: 28,
              color: item['isFavorite'] == true
                  ? Colors.amber
                  : const Color(0xFF939393),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    List<Map<String, dynamic>> speakers,
    Map<String, dynamic>? moderator,
    Map<String, dynamic>? sponsor,
    String speechTheme,
  ) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if ((item['date'] as String?)?.isNotEmpty == true)
                    _MetaBadge(
                      icon: Icons.calendar_today_outlined,
                      text: item['date'],
                      isMobile: true,
                    ),
                  if ((item['location'] as String?)?.isNotEmpty == true)
                    _MetaBadge(
                      icon: Icons.location_on_outlined,
                      text: item['location'],
                      isMobile: true,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Padding(
                padding: const EdgeInsets.only(right: 32),
                child: Text(
                  item['title'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151938),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                item['description'] ?? '',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.6,
                ),
              ),

              // Topic
              if (speechTheme.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Topic: $speechTheme',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151938),
                  ),
                ),
              ],

              // Sponsor
              if (sponsor != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: _SponsorWidget(
                      sponsor: sponsor, isMobile: true, eventId: eventId),
                ),
              ],

              // Speakers
              if (speakers.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Speakers:',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151938),
                  ),
                ),
                const SizedBox(height: 12),
                _SpeakerScrollMobile(speakers: speakers, eventId: eventId),
              ],

              // Moderator
              if (moderator != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Moderator',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151938),
                  ),
                ),
                const SizedBox(height: 12),
                _ModeratorCard(
                    moderator: moderator, isMobile: true, eventId: eventId),
              ],

              // Collapse hint
              const SizedBox(height: 16),
              Center(
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Favorite star — always top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onToggleFavorite,
            child: Icon(
              item['isFavorite'] == true
                  ? Icons.star
                  : Icons.star_border,
              size: 22,
              color: item['isFavorite'] == true
                  ? Colors.amber
                  : const Color(0xFF939393),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Meta Badge (date / location pill)
// =============================================================================

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isMobile;

  const _MetaBadge({
    required this.icon,
    required this.text,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF9CA4CC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 12 : 16, color: const Color(0xFF9CA4CC)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sponsor Widget
// =============================================================================

class _SponsorWidget extends StatelessWidget {
  final Map<String, dynamic> sponsor;
  final bool isMobile;
  final String eventId;

  const _SponsorWidget({required this.sponsor, required this.isMobile, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final logoUrl = sponsor['logo']?.toString() ?? '';
    final tier = (sponsor['tier'] ?? 'general').toString().toLowerCase();
    final tierLabel = _tierLabel(tier);
    final tierBg = _tierBgColor(tier);
    final tierText = _tierTextColor(tier);

    return GestureDetector(
      onTap: () {
        final id = sponsor['id'];
        if (id != null) context.push('/events/$eventId/participants/$id');
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tier badge on top
        Container(
          width: isMobile ? 80 : 120,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: tierBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(5)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                blurRadius: 5,
                offset: const Offset(0, -1),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Text(
            tierLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: tierText,
            ),
          ),
        ),
        // Logo below tier
        Container(
          width: isMobile ? 80 : 120,
          height: isMobile ? 50 : 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(5)),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: logoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(4)),
                  child: AppCachedImage(
                    imageUrl: logoUrl,
                    fit: BoxFit.contain,
                    placeholder: Center(
                      child: Text(
                        sponsor['name'] ?? '',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 8 : 11,
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
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
        ),
      ],
    ),
    );
  }

  static String _tierLabel(String tier) {
    switch (tier) {
      case 'gold':
        return 'Gold Sponsor';
      case 'silver':
        return 'Silver Sponsor';
      case 'bronze':
        return 'Bronze Sponsor';
      case 'platinum':
        return 'Platinum Sponsor';
      case 'diamond':
        return 'Diamond Sponsor';
      default:
        return 'Sponsor';
    }
  }

  static Color _tierBgColor(String tier) {
    switch (tier) {
      case 'gold':
        return const Color(0xFFFDE875);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFECC5A0);
      case 'platinum':
        return const Color(0xFFE0E4E8);
      case 'diamond':
        return const Color(0xFFE0F7FA);
      default:
        return const Color(0xFFFDE875);
    }
  }

  static Color _tierTextColor(String tier) {
    switch (tier) {
      case 'gold':
        return const Color(0xFFAE7600);
      case 'silver':
        return const Color(0xFF6E6E6E);
      case 'bronze':
        return const Color(0xFF8B5E3C);
      case 'platinum':
        return const Color(0xFF607D8B);
      case 'diamond':
        return const Color(0xFF00838F);
      default:
        return const Color(0xFFAE7600);
    }
  }
}

// =============================================================================
// Moderator Card
// =============================================================================

class _ModeratorCard extends StatelessWidget {
  final Map<String, dynamic> moderator;
  final bool isMobile;
  final String eventId;

  const _ModeratorCard({required this.moderator, required this.isMobile, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final photoUrl = moderator['photo']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        final id = moderator['id'];
        if (id != null) context.push('/events/$eventId/speakers/$id');
      },
      child: Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 64 : 110,
            height: isMobile ? 64 : 110,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
            child: photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: AppCachedImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: const Icon(
                          Icons.person, size: 32, color: Colors.grey),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.person, size: 32, color: Colors.grey),
                  ),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moderator['name'] ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  moderator['position'] ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ModeratorCardCompact extends StatelessWidget {
  final Map<String, dynamic> moderator;
  final String eventId;

  const _ModeratorCardCompact({required this.moderator, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final photoUrl = moderator['photo']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        final id = moderator['id'];
        if (id != null) context.push('/events/$eventId/speakers/$id');
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
              child: photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: AppCachedImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: const Icon(
                            Icons.person, size: 32, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, size: 32, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              moderator['position'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              moderator['name'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Speaker Scroll (Mobile) -- horizontal scroll mini-cards
// =============================================================================

class _SpeakerScrollMobile extends StatelessWidget {
  final List<Map<String, dynamic>> speakers;
  final String eventId;

  const _SpeakerScrollMobile({required this.speakers, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: speakers.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SpeakerMiniCard(
              speaker: speakers[index],
              width: 150,
              eventId: eventId,
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Speaker Carousel (Desktop) -- with chevron
// =============================================================================

class _SpeakerCarouselDesktop extends StatefulWidget {
  final List<Map<String, dynamic>> speakers;
  final String eventId;

  const _SpeakerCarouselDesktop({required this.speakers, required this.eventId});

  @override
  State<_SpeakerCarouselDesktop> createState() =>
      _SpeakerCarouselDesktopState();
}

class _SpeakerCarouselDesktopState extends State<_SpeakerCarouselDesktop> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 246,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.speakers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _SpeakerMiniCard(
                    speaker: widget.speakers[index],
                    width: 184,
                    eventId: widget.eventId,
                  ),
                );
              },
            ),
          ),
          if (widget.speakers.length > 3)
            GestureDetector(
              onTap: _scrollRight,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Speaker Mini Card
// =============================================================================

class _SpeakerMiniCard extends StatelessWidget {
  final Map<String, dynamic> speaker;
  final double width;
  final String eventId;

  const _SpeakerMiniCard({required this.speaker, required this.width, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final photoUrl = speaker['photo']?.toString() ?? '';
    final position = speaker['position'] ?? '';
    final country = speaker['country'] ?? '';

    return GestureDetector(
      onTap: () {
        final id = speaker['id'];
        if (id != null) context.push('/events/$eventId/speakers/$id');
      },
      child: Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          Container(
            height: width * 0.65,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(5)),
                    child: SizedBox.expand(
                      child: AppCachedImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: const Icon(
                            Icons.person, size: 40, color: Colors.grey),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speaker['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    position,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  if (country.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Keynote \u2022 $country',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'View Profile',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
