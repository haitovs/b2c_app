import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';

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
  int? _expandedCardIndex;

  List<Map<String, dynamic>> _days = [];
  List<Map<String, dynamic>> _episodes = [];
  final Set<int> _favoriteIds = {};
  bool _isLoadingDays = true;
  bool _isLoadingEpisodes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndFetch();
    });
  }

  Future<void> _initializeAndFetch() async {
    _fetchAgendaDays();
  }

  Future<void> _fetchAgendaDays() async {
    try {
      final eventId = widget.eventId;
      final uri = Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/agenda/days?event_id=$eventId');
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
                'weekday': _getWeekdayShort(date?.weekday ?? 1),
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
      final uri = Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/agenda/day/$dayId/episodes');
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

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
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
                'tier': s['tier'] ?? 'general',
              })
          .toList();
    }

    List<Map<String, dynamic>> speakers = [];
    if (e['speakers'] != null) {
      speakers = (e['speakers'] as List)
          .map((s) => {
                'id': s['id'],
                'name': s['fullname'] ?? s['name'] ?? '',
                'title': s['position'] ?? '',
                'company': s['company'] ?? '',
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
                'title': m['position'] ?? '',
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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

  Color _getTierColor(String tierLabel) {
    if (tierLabel.contains('Gold')) return const Color(0xFFDDAC17);
    if (tierLabel.contains('Silver')) return const Color(0xFF9E9E9E);
    if (tierLabel.contains('Bronze')) return const Color(0xFFCD7F32);
    if (tierLabel.contains('Platinum')) return const Color(0xFF607D8B);
    if (tierLabel.contains('Diamond')) return const Color(0xFF00BCD4);
    return const Color(0xFFDDAC17);
  }

  Color _getTierBgColor(String tierLabel) {
    if (tierLabel.contains('Gold')) return const Color(0xFFFDE875);
    if (tierLabel.contains('Silver')) return const Color(0xFFE0E0E0);
    if (tierLabel.contains('Bronze')) return const Color(0xFFFFE0B2);
    return const Color(0xFFFDE875);
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
      if (!_isProgramSelected && !item['isFavorite']) return false;
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

    return CustomScrollView(
      slivers: [
        // Title + Divider
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 32, 24, isMobile ? 16 : 32, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Agenda',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 20 : 30,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300, height: 1),
              ],
            ),
          ),
        ),

        // Program / Favourite Toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 32, 16, isMobile ? 16 : 32, 0,
            ),
            child: _ProgramToggle(
              isProgramSelected: _isProgramSelected,
              isMobile: isMobile,
              onProgramTap: () => setState(() => _isProgramSelected = true),
              onFavouriteTap: () => setState(() => _isProgramSelected = false),
            ),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 32, 12, isMobile ? 16 : 32, 0,
            ),
            child: _SearchBar(
              isMobile: isMobile,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),

        // Day Selector
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 32, 16, isMobile ? 16 : 32, 0,
            ),
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
                    ? _CalendarDaySelector(
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
                child:
                    CircularProgressIndicator(color: AppTheme.primaryColor),
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 32, 20, isMobile ? 16 : 32, 32,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _filteredItems[index];
                  final isExpanded = _expandedCardIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AgendaCard(
                      item: item,
                      index: index,
                      isExpanded: isExpanded,
                      isMobile: isMobile,
                      onToggleExpand: () => _toggleExpand(index),
                      onToggleFavorite: () => _toggleFavorite(item['id']),
                      getTierColor: _getTierColor,
                      getTierBgColor: _getTierBgColor,
                    ),
                  );
                },
                childCount: _filteredItems.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Program / Favourite Toggle ─────────────────────────────────────────────

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
    return Container(
      height: isMobile ? 44 : 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onProgramTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isProgramSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE6E7F2),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(isMobile ? 10 : 12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Event Program',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 14 : 20,
                    fontWeight: FontWeight.w600,
                    color: isProgramSelected
                        ? Colors.white
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onFavouriteTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isProgramSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE6E7F2),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(isMobile ? 10 : 12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'My Program',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 14 : 20,
                    fontWeight: FontWeight.w600,
                    color: !isProgramSelected
                        ? Colors.white
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final bool isMobile;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.isMobile, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isMobile ? 38 : 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E6F2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFCACACA)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: const Color(0xFF757A8A),
            size: isMobile ? 18 : 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : 16,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search by event name or ID',
                hintStyle: GoogleFonts.roboto(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757A8A),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Day Selector (Mobile) ─────────────────────────────────────────

class _CalendarDaySelector extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  const _CalendarDaySelector({
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
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onDaySelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 65,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF20306C)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day['weekday'],
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF20306C),
                      ),
                    ),
                    Container(
                      width: isSelected ? 48 : 50,
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF20306C),
                    ),
                    Text(
                      '${day['day']}',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
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
}

// ─── Stepper Day Selector (Desktop) ─────────────────────────────────────────

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
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    }

    return Container(
      height: 43,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD3D3D3)),
      ),
      child: Row(
        children: List.generate(days.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected(index),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: index == 0
                      ? const BorderRadius.horizontal(
                          left: Radius.circular(4))
                      : index == days.length - 1
                          ? const BorderRadius.horizontal(
                              right: Radius.circular(4))
                          : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFCED4E3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
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
                    if (index < days.length - 1 && !isSelected)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFCED4E3),
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
}

// ─── Agenda Card ────────────────────────────────────────────────────────────

class _AgendaCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isExpanded;
  final bool isMobile;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleFavorite;
  final Color Function(String) getTierColor;
  final Color Function(String) getTierBgColor;

  const _AgendaCard({
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.isMobile,
    required this.onToggleExpand,
    required this.onToggleFavorite,
    required this.getTierColor,
    required this.getTierBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column
        _TimeBadge(
          startTime: item['startTime'] ?? '',
          endTime: item['endTime'] ?? '',
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 8 : 16),
        // Card
        Expanded(
          child: GestureDetector(
            onTap: onToggleExpand,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 5 : 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isExpanded
                  ? _ExpandedContent(
                      item: item,
                      isMobile: isMobile,
                      onToggleFavorite: onToggleFavorite,
                      getTierColor: getTierColor,
                      getTierBgColor: getTierBgColor,
                    )
                  : _CollapsedContent(
                      item: item,
                      isMobile: isMobile,
                      onToggleFavorite: onToggleFavorite,
                      getTierColor: getTierColor,
                      getTierBgColor: getTierBgColor,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Time Badge ─────────────────────────────────────────────────────────────

class _TimeBadge extends StatelessWidget {
  final String startTime;
  final String endTime;
  final bool isMobile;

  const _TimeBadge({
    required this.startTime,
    required this.endTime,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return SizedBox(
        width: 42,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Text(
                startTime,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                endTime,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: 130,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          '$startTime - $endTime',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

// ─── Collapsed Card Content ─────────────────────────────────────────────────

class _CollapsedContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isMobile;
  final VoidCallback onToggleFavorite;
  final Color Function(String) getTierColor;
  final Color Function(String) getTierBgColor;

  const _CollapsedContent({
    required this.item,
    required this.isMobile,
    required this.onToggleFavorite,
    required this.getTierColor,
    required this.getTierBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badges + star
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaBadge(
                      icon: Icons.calendar_today_outlined,
                      text: item['date'] ?? '',
                      isMobile: isMobile,
                    ),
                    _MetaBadge(
                      icon: Icons.location_on_outlined,
                      text: item['location'] ?? '',
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleFavorite,
                child: Icon(
                  item['isFavorite'] ? Icons.star : Icons.star_border,
                  size: isMobile ? 22 : 30,
                  color: item['isFavorite']
                      ? Colors.amber
                      : const Color(0xFF939393),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 16),
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
          // Description (truncated)
          Text(
            item['description'] ?? '',
            maxLines: isMobile ? 4 : 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.5,
            ),
          ),
          // Sponsor
          if (item['sponsor'] != null) ...[
            const SizedBox(height: 12),
            _SponsorBadge(
              sponsor: item['sponsor'],
              isMobile: isMobile,
              getTierColor: getTierColor,
              getTierBgColor: getTierBgColor,
            ),
          ],
          // Read more hint
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'READ MORE',
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 8 : 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF20306C),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: isMobile ? 12 : 16,
                color: const Color(0xFF20306C),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Expanded Card Content ──────────────────────────────────────────────────

class _ExpandedContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isMobile;
  final VoidCallback onToggleFavorite;
  final Color Function(String) getTierColor;
  final Color Function(String) getTierBgColor;

  const _ExpandedContent({
    required this.item,
    required this.isMobile,
    required this.onToggleFavorite,
    required this.getTierColor,
    required this.getTierBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final speakers = item['speakers'] as List? ?? [];
    final moderator = item['moderator'] as Map<String, dynamic>?;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badges + star
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaBadge(
                      icon: Icons.calendar_today_outlined,
                      text: item['date'] ?? '',
                      isMobile: isMobile,
                    ),
                    _MetaBadge(
                      icon: Icons.location_on_outlined,
                      text: item['location'] ?? '',
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleFavorite,
                child: Icon(
                  item['isFavorite'] ? Icons.star : Icons.star_border,
                  size: isMobile ? 22 : 30,
                  color: item['isFavorite']
                      ? Colors.amber
                      : const Color(0xFF939393),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 16),
          // Title
          Text(
            item['title'] ?? '',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151838),
            ),
          ),
          const SizedBox(height: 12),
          // Full description
          Text(
            item['description'] ?? '',
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.6,
            ),
          ),

          // Moderator
          if (moderator != null) ...[
            const SizedBox(height: 20),
            Divider(color: const Color(0xFF20306C).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Moderator',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 16 : 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF151838),
              ),
            ),
            const SizedBox(height: 12),
            _ModeratorCard(moderator: moderator, isMobile: isMobile),
          ],

          // Speakers
          if (speakers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: const Color(0xFF20306C).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Speakers:',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 16 : 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF151838),
              ),
            ),
            const SizedBox(height: 12),
            isMobile
                ? _SpeakerListMobile(speakers: speakers)
                : _SpeakerCarouselDesktop(speakers: speakers),
          ],

          // Sponsor
          if (item['sponsor'] != null) ...[
            const SizedBox(height: 20),
            Divider(color: const Color(0xFF20306C).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            _SponsorBadge(
              sponsor: item['sponsor'],
              isMobile: isMobile,
              getTierColor: getTierColor,
              getTierBgColor: getTierBgColor,
            ),
          ],

          // Collapse hint
          const SizedBox(height: 16),
          Center(
            child: Icon(
              Icons.keyboard_arrow_up,
              size: isMobile ? 24 : 32,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta Badge (date / location) ───────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(isMobile ? 10 : 5),
        border: Border.all(color: const Color(0xFF9CA4CC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 12 : 16,
            color: const Color(0xFF9CA4CC),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 10 : 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sponsor Badge ──────────────────────────────────────────────────────────

class _SponsorBadge extends StatelessWidget {
  final Map<String, dynamic> sponsor;
  final bool isMobile;
  final Color Function(String) getTierColor;
  final Color Function(String) getTierBgColor;

  const _SponsorBadge({
    required this.sponsor,
    required this.isMobile,
    required this.getTierColor,
    required this.getTierBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = sponsor['logo']?.toString() ?? '';
    final tierLabel = sponsor['tier'] ?? 'Sponsor';

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? 80 : 161,
            height: isMobile ? 50 : 109,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: logoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          sponsor['name'] ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 8 : 12,
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
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 10 : 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
          ),
          Container(
            width: isMobile ? 80 : 161,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: getTierBgColor(tierLabel),
              border: Border.all(color: const Color(0xFFD3D3D3)),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
            ),
            child: Text(
              tierLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: getTierColor(tierLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Moderator Card ─────────────────────────────────────────────────────────

class _ModeratorCard extends StatelessWidget {
  final Map<String, dynamic> moderator;
  final bool isMobile;

  const _ModeratorCard({required this.moderator, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final photoUrl = moderator['photo']?.toString() ?? '';

    return Container(
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
              borderRadius: BorderRadius.circular(isMobile ? 10 : 3),
            ),
            child: photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 3),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child:
                            Icon(Icons.person, size: 32, color: Colors.grey),
                      ),
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
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  moderator['title'] ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.primaryColor,
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

// ─── Speaker List (Mobile) ──────────────────────────────────────────────────

class _SpeakerListMobile extends StatelessWidget {
  final List speakers;

  const _SpeakerListMobile({required this.speakers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: speakers.map<Widget>((speaker) {
        final photoUrl = speaker['photo']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker['name'] ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      speaker['title'] ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C6C6F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Speaker Carousel (Desktop) ─────────────────────────────────────────────

class _SpeakerCarouselDesktop extends StatelessWidget {
  final List speakers;

  const _SpeakerCarouselDesktop({required this.speakers});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 246,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: speakers.length,
        itemBuilder: (context, index) {
          final speaker = speakers[index];
          final photoUrl = speaker['photo']?.toString() ?? '';

          return Container(
            width: 184,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Photo
                Container(
                  height: 122,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                  child: photoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.person,
                                  size: 40, color: Colors.grey),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.person,
                              size: 40, color: Colors.grey),
                        ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                          speaker['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
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
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
