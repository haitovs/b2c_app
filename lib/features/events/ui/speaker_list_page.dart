import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';

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
  bool _sortAZ = true;
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
      final siteId = ref.read(eventContextProvider).siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/speakers/?site_id=$siteId')
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/speakers/');

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
      final nameA =
          '${a['name'] ?? ''} ${a['surname'] ?? ''}'.trim().toLowerCase();
      final nameB =
          '${b['name'] ?? ''} ${b['surname'] ?? ''}'.trim().toLowerCase();
      return _sortAZ ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
    });

    _filteredSpeakers = result;
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.tourismApiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    return EventSidebarLayout(
      title: 'Speakers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Speakers" title + divider
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speakers',
                  style: GoogleFonts.montserrat(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 0.5, color: const Color(0xFFCACACA)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search bar + Sort button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Search bar
                Expanded(child: _SearchBar(controller: _searchController, onChanged: (q) {
                  setState(() => _applyFilters());
                })),
                const SizedBox(width: 10),
                // Sort button
                _SortButton(
                  isAZ: _sortAZ,
                  onTap: () => setState(() {
                    _sortAZ = !_sortAZ;
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
      ),
    );
  }

  Widget _buildGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: isMobile ? 10 : 12,
        mainAxisSpacing: isMobile ? 10 : 12,
        childAspectRatio: 184 / 246,
      ),
      itemCount: _filteredSpeakers.length,
      itemBuilder: (context, index) {
        final speaker = _filteredSpeakers[index];
        return _SpeakerCard(
          name:
              '${speaker['name'] ?? ''} ${speaker['surname'] ?? ''}'.trim(),
          company: speaker['company'] ?? '',
          position: speaker['position'] ?? '',
          country: speaker['country'] ?? '',
          photoUrl: _buildImageUrl(speaker['photo']),
          flagUrl: _buildImageUrl(speaker['country_flag']),
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
  final bool isAZ;
  final VoidCallback onTap;

  const _SortButton({required this.isAZ, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 150,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFCBCBCB)),
        ),
        child: Row(
          children: [
            Text(
              isAZ ? 'Sort by: A - Z' : 'Sort by: Z - A',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757A8A),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: const Color(0xFF757A8A),
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
  final VoidCallback onViewProfile;

  const _SpeakerCard({
    required this.name,
    required this.company,
    required this.position,
    required this.country,
    required this.photoUrl,
    required this.flagUrl,
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
                                const SizedBox.shrink(),
                          ),
                        ),
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
