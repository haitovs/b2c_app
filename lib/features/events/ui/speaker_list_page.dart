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
  String _sortMode = 'az';
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
      return _sortMode == 'za'
          ? nameB.compareTo(nameA)
          : nameA.compareTo(nameB);
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hPad = isMobile ? 16.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, isMobile ? 12 : 20, hPad, 0),
          child: Text(
            'Speakers',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Container(height: 0.5, color: const Color(0xFFCACACA)),
        ),
        const SizedBox(height: 16),

        // ── Search + Sort ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            children: [
              Expanded(
                child: _SearchBar(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _applyFilters()),
                ),
              ),
              const SizedBox(width: 12),
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
        const SizedBox(height: 20),

        // ── Content ──
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                )
              : _filteredSpeakers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_off_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No speakers found'
                                : 'No speakers available',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(isMobile, hPad),
        ),
      ],
    );
  }

  Widget _buildContent(bool isMobile, double hPad) {
    if (isMobile) {
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
        itemCount: _filteredSpeakers.length,
        itemBuilder: (context, index) => _buildMobileCard(index),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fixed card width 184, calculate columns
        const cardWidth = 184.0;
        const gap = 16.0;
        final cols =
            ((constraints.maxWidth + gap) / (cardWidth + gap)).floor().clamp(2, 8);

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: 184 / 246,
          ),
          itemCount: _filteredSpeakers.length,
          itemBuilder: (context, index) => _buildDesktopCard(index),
        );
      },
    );
  }

  Widget _buildDesktopCard(int index) {
    final s = _filteredSpeakers[index];
    final country = s['country'] as String? ?? '';
    return _SpeakerCard(
      name: '${s['name'] ?? ''} ${s['surname'] ?? ''}'.trim(),
      company: s['company'] as String? ?? '',
      position: s['position'] as String? ?? '',
      country: country,
      photoUrl: _buildImageUrl(s['photo'] as String?),
      flagEmoji: countryNameToFlag(country),
      onViewProfile: () => context.push(
        '/events/${widget.eventId}/speakers/${s['id']}',
        extra: s,
      ),
    );
  }

  Widget _buildMobileCard(int index) {
    final s = _filteredSpeakers[index];
    final country = s['country'] as String? ?? '';
    return _SpeakerMobileCard(
      name: '${s['name'] ?? ''} ${s['surname'] ?? ''}'.trim(),
      company: s['company'] as String? ?? '',
      position: s['position'] as String? ?? '',
      country: country,
      photoUrl: _buildImageUrl(s['photo'] as String?),
      flagEmoji: countryNameToFlag(country),
      onViewProfile: () => context.push(
        '/events/${widget.eventId}/speakers/${s['id']}',
        extra: s,
      ),
    );
  }
}

// =============================================================================
// Search bar
// =============================================================================
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search speakers...',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: const Color(0xFFE6E7F2),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sort button
// =============================================================================
class _SortButton extends StatelessWidget {
  final String sortMode;
  final ValueChanged<String> onChanged;

  const _SortButton({required this.sortMode, required this.onChanged});

  static const _modes = ['az', 'za', 'country'];
  static const _labels = {
    'az': 'Sort: A – Z',
    'za': 'Sort: Z – A',
    'country': 'Sort: Country',
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (_) => _modes.map((mode) {
        return PopupMenuItem(
          value: mode,
          child: Text(
            _labels[mode]!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight:
                  sortMode == mode ? FontWeight.w600 : FontWeight.w400,
              color:
                  sortMode == mode ? AppTheme.primaryColor : Colors.black87,
            ),
          ),
        );
      }).toList(),
      child: Container(
        width: isMobile ? 40 : 150,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE6E7F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isMobile
            ? const Center(
                child: Icon(Icons.sort, size: 20, color: Color(0xFF5A5E6E)),
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      _labels[sortMode]!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5A5E6E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.unfold_more,
                      size: 16, color: Color(0xFF5A5E6E)),
                ],
              ),
      ),
    );
  }
}

// =============================================================================
// Desktop Speaker Card — 184×246 fixed proportions
// =============================================================================
class _SpeakerCard extends StatelessWidget {
  final String name;
  final String company;
  final String position;
  final String country;
  final String photoUrl;
  final String flagEmoji;
  final VoidCallback onViewProfile;

  const _SpeakerCard({
    required this.name,
    required this.company,
    required this.position,
    required this.country,
    required this.photoUrl,
    this.flagEmoji = '',
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final photoH = constraints.maxHeight * 0.50;

          return Column(
            children: [
              // ── Photo ──
              SizedBox(
                height: photoH,
                width: double.infinity,
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),

              // ── Info ──
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name + Position + Company
                      Column(
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Unknown',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (position.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              position,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          if (company.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              company,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: OutlinedButton(
                          onPressed: onViewProfile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'View Profile',
                            style: GoogleFonts.inter(
                              fontSize: 11,
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
          );
        },
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: const Color(0xFFF0F0F4),
      child: Center(
        child: Icon(Icons.person, size: 36, color: Colors.grey.shade400),
      ),
    );
  }
}

// =============================================================================
// Mobile Speaker Card — horizontal layout
// =============================================================================
class _SpeakerMobileCard extends StatelessWidget {
  final String name;
  final String company;
  final String position;
  final String country;
  final String photoUrl;
  final String flagEmoji;
  final VoidCallback onViewProfile;

  const _SpeakerMobileCard({
    required this.name,
    required this.company,
    required this.position,
    required this.country,
    required this.photoUrl,
    this.flagEmoji = '',
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
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
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Photo
          SizedBox(
            width: 100,
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF0F0F4),
                      child: Icon(Icons.person,
                          size: 36, color: Colors.grey.shade400),
                    ),
                  )
                : Container(
                    color: const Color(0xFFF0F0F4),
                    child: Icon(Icons.person,
                        size: 36, color: Colors.grey.shade400),
                  ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name + position + company
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (position.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          position,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Flag + country
                  if (country.isNotEmpty)
                    Row(
                      children: [
                        if (flagEmoji.isNotEmpty) ...[
                          Text(flagEmoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            country,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: OutlinedButton(
                      onPressed: onViewProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'View Profile',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
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
}
