import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/country_flags.dart';

class SpeakerListPage extends ConsumerStatefulWidget {
  final String eventId;

  const SpeakerListPage({super.key, required this.eventId});

  @override
  ConsumerState<SpeakerListPage> createState() => _SpeakerListPageState();
}

class _SpeakerListPageState extends ConsumerState<SpeakerListPage> {
  List<Map<String, dynamic>> _speakers = [];
  List<Map<String, dynamic>> _filteredSpeakers = [];
  bool _isLoading = true;
  String _sortMode = 'az'; // 'az', 'za', 'country'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await ref
          .read(eventContextProvider.notifier)
          .ensureEventContext(eventId);
    }
    _fetchSpeakers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpeakers() async {
    try {
      final uri = Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/speakers/');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _speakers = data.cast<Map<String, dynamic>>();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch speakers: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching speakers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    var result = _speakers.toList();

    if (query.isNotEmpty) {
      result = result.where((s) {
        final name =
            '${s['name'] ?? ''} ${s['surname'] ?? ''}'.toLowerCase();
        final position = (s['position'] ?? '').toString().toLowerCase();
        final company = (s['company'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            position.contains(query) ||
            company.contains(query);
      }).toList();
    }

    result.sort((a, b) {
      if (_sortMode == 'country') {
        final countryA = (a['country'] ?? '').toString().toLowerCase();
        final countryB = (b['country'] ?? '').toString().toLowerCase();
        if (countryA != countryB) return countryA.compareTo(countryB);
      }
      final nameA =
          '${a['name'] ?? ''} ${a['surname'] ?? ''}'.trim().toLowerCase();
      final nameB =
          '${b['name'] ?? ''} ${b['surname'] ?? ''}'.trim().toLowerCase();
      return _sortMode == 'za' ? nameB.compareTo(nameA) : nameA.compareTo(nameB);
    });

    _filteredSpeakers = result;
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Speakers" title + divider
          Builder(builder: (context) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            return Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, isMobile ? 12 : 20, isMobile ? 16 : 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speakers',
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 22 : 30,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 0.5, color: const Color(0xFFCACACA)),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Search bar + Sort button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 20),
            child: Row(
              children: [
                // Search bar
                Expanded(child: _SearchBar(controller: _searchController, onChanged: (q) {
                  setState(() => _applyFilters());
                })),
                const SizedBox(width: 10),
                // Sort button
                _SortButton(
                  sortMode: _sortMode,
                  onChanged: (mode) => setState(() {
                    _sortMode = mode;
                    _applyFilters();
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _filteredSpeakers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isNotEmpty
                              ? 'No speakers found'
                              : 'No speakers available',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : _buildGrid(),
          ),
        ],
      );
  }

  Widget _buildGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _filteredSpeakers.length,
        itemBuilder: (context, index) {
          final speaker = _filteredSpeakers[index];
          final country = speaker['country'] ?? '';
          return _SpeakerHorizontalCard(
            name: '${speaker['name'] ?? ''} ${speaker['surname'] ?? ''}'.trim(),
            company: speaker['company'] ?? '',
            position: speaker['position'] ?? '',
            country: country,
            photoUrl: _buildImageUrl(speaker['photo']),
            flagUrl: _buildImageUrl(speaker['country_flag']),
            flagEmoji: countryNameToFlag(country),
            onViewProfile: () => context.push(
              '/events/${widget.eventId}/speakers/${speaker['id']}',
              extra: speaker,
            ),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 184 / 246,
      ),
      itemCount: _filteredSpeakers.length,
      itemBuilder: (context, index) {
        final speaker = _filteredSpeakers[index];
        final country = speaker['country'] ?? '';
        return _SpeakerCard(
          name:
              '${speaker['name'] ?? ''} ${speaker['surname'] ?? ''}'.trim(),
          company: speaker['company'] ?? '',
          position: speaker['position'] ?? '',
          country: country,
          photoUrl: _buildImageUrl(speaker['photo']),
          flagUrl: _buildImageUrl(speaker['country_flag']),
          flagEmoji: countryNameToFlag(country),
          onViewProfile: () => context.push(
            '/events/${widget.eventId}/speakers/${speaker['id']}',
            extra: speaker,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar — #E6E7F2 bg, 5px radius, 1px #CBCBCB border, 38px height
// ---------------------------------------------------------------------------
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E7F2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFCBCBCB)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Colors.grey.shade600,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          hintText: 'Search speakers...',
          hintStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort button — 150px, 38px, border #CBCBCB
// ---------------------------------------------------------------------------
class _SortButton extends StatelessWidget {
  final String sortMode;
  final ValueChanged<String> onChanged;

  const _SortButton({required this.sortMode, required this.onChanged});

  static const _modes = ['az', 'za', 'country'];
  static const _labels = {
    'az': 'Sort by: A - Z',
    'za': 'Sort by: Z - A',
    'country': 'Sort by: Country',
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => _modes.map((mode) {
        return PopupMenuItem(
          value: mode,
          child: Text(
            _labels[mode]!,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: sortMode == mode ? FontWeight.w600 : FontWeight.w400,
              color: sortMode == mode ? AppTheme.primaryColor : Colors.black87,
            ),
          ),
        );
      }).toList(),
      child: Container(
        width: isMobile ? 40 : 170,
        height: 38,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFCBCBCB)),
        ),
        child: isMobile
            ? const Center(
                child: Icon(Icons.sort, size: 20, color: Color(0xFF757A8A)),
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      _labels[sortMode]!,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757A8A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.unfold_more,
                    size: 16,
                    color: Color(0xFF757A8A),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Speaker Card — 184x246 proportions, matches Figma
// ---------------------------------------------------------------------------
class _SpeakerCard extends StatelessWidget {
  final String name;
  final String company;
  final String position;
  final String country;
  final String photoUrl;
  final String flagUrl;
  final String flagEmoji;
  final VoidCallback onViewProfile;

  const _SpeakerCard({
    required this.name,
    required this.company,
    required this.position,
    required this.country,
    required this.photoUrl,
    required this.flagUrl,
    this.flagEmoji = '',
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Photo — top ~50%
          Expanded(
            flex: 50,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
              child: SizedBox(
                width: double.infinity,
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
            ),
          ),

          // Info section — bottom ~50%
          Expanded(
            flex: 50,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name — Roboto Medium 16px
                  Text(
                    name.isNotEmpty ? name : 'Unknown',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Company/Position — Roboto Regular 10px
                  Text(
                    position.isNotEmpty && company.isNotEmpty
                        ? '$position, $company'
                        : position.isNotEmpty
                            ? position
                            : company,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Role + Country — Roboto Regular 14px with flag
                  Row(
                    children: [
                      if (flagUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: Image.network(
                            flagUrl,
                            width: 20,
                            height: 14,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                flagEmoji.isNotEmpty
                                    ? Text(flagEmoji, style: const TextStyle(fontSize: 14))
                                    : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ] else if (flagEmoji.isNotEmpty) ...[
                        Text(flagEmoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          country.isNotEmpty ? country : '',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // View Profile button — border #3C4494, 5px radius
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onViewProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View Profile',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _photoPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.person, size: 40, color: Colors.grey.shade400),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal Speaker Card — mobile list layout (photo left, info right)
// ---------------------------------------------------------------------------
class _SpeakerHorizontalCard extends StatelessWidget {
  final String name;
  final String company;
  final String position;
  final String country;
  final String photoUrl;
  final String flagUrl;
  final String flagEmoji;
  final VoidCallback onViewProfile;

  const _SpeakerHorizontalCard({
    required this.name,
    required this.company,
    required this.position,
    required this.country,
    required this.photoUrl,
    required this.flagUrl,
    this.flagEmoji = '',
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              child: SizedBox(
                width: 110,
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Unknown',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position.isNotEmpty && company.isNotEmpty
                          ? '$position, $company'
                          : position.isNotEmpty
                              ? position
                              : company,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Flag + country
                    Row(
                      children: [
                        if (flagUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: Image.network(
                              flagUrl,
                              width: 20,
                              height: 14,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  flagEmoji.isNotEmpty
                                      ? Text(flagEmoji, style: const TextStyle(fontSize: 14))
                                      : const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ] else if (flagEmoji.isNotEmpty) ...[
                          Text(flagEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            country.isNotEmpty ? country : '',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // View Profile button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onViewProfile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
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
