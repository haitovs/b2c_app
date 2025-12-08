import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/providers/site_context_provider.dart';

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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSpeakers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpeakers() async {
    try {
      final siteId = ref.read(siteContextProvider);
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/speakers/?site_id=$siteId',
            )
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/speakers/');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _speakers = data.cast<Map<String, dynamic>>();
          _filteredSpeakers = _speakers;
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

  void _filterSpeakers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSpeakers = _speakers;
      } else {
        _filteredSpeakers = _speakers.where((speaker) {
          final name = '${speaker['name'] ?? ''} ${speaker['surname'] ?? ''}'
              .toLowerCase();
          final position = (speaker['position'] ?? '').toString().toLowerCase();
          final company = (speaker['company'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              position.contains(query.toLowerCase()) ||
              company.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.tourismApiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isMobile),

            // Search Bar
            _buildSearchBar(isMobile),

            const SizedBox(height: 20),

            // Content Container
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 50),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F1F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3C4494),
                        ),
                      )
                    : _filteredSpeakers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No speakers found for "$_searchQuery"'
                              : 'No speakers available',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : _buildSpeakersGrid(isMobile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 50,
        vertical: isMobile ? 12 : 20,
      ),
      child: Row(
        children: [
          // Menu/Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/events/${widget.eventId}/menu');
                }
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Text(
            'Speakers',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF1F1F6),
            ),
          ),

          const Spacer(),

          // Icons
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.white,
                iconSize: isMobile ? 24 : 30,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.person_outline),
                color: Colors.white,
                iconSize: isMobile ? 24 : 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 50),
      child: Container(
        height: isMobile ? 50 : 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F6).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(width: isMobile ? 16 : 24),
            Icon(
              Icons.search,
              color: const Color(0xFFF1F1F6),
              size: isMobile ? 28 : 36,
            ),
            SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _filterSpeakers,
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 16 : 20,
                  color: const Color(0xFFF1F1F6),
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name or position',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: isMobile ? 16 : 20,
                    color: const Color(0xFFF1F1F6),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakersGrid(bool isMobile) {
    // Calculate columns based on screen width
    int crossAxisCount = isMobile ? 2 : 5;
    if (!isMobile && MediaQuery.of(context).size.width < 1200) {
      crossAxisCount = 4;
    }
    if (!isMobile && MediaQuery.of(context).size.width < 900) {
      crossAxisCount = 3;
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isMobile ? 0.68 : 0.68,
          crossAxisSpacing: isMobile ? 16 : 44,
          mainAxisSpacing: isMobile ? 16 : 30,
        ),
        itemCount: _filteredSpeakers.length,
        itemBuilder: (context, index) {
          final speaker = _filteredSpeakers[index];
          return _buildSpeakerCard(speaker, isMobile);
        },
      ),
    );
  }

  Widget _buildSpeakerCard(Map<String, dynamic> speaker, bool isMobile) {
    final name = speaker['name'] ?? '';
    final surname = speaker['surname'] ?? '';
    final fullName = '$name $surname'.trim();
    final position = speaker['position'] ?? '';
    final photoUrl = _buildImageUrl(speaker['photo']);

    return GestureDetector(
      onTap: () {
        // Navigate to speaker detail
        context.push(
          '/events/${widget.eventId}/speakers/${speaker['id']}',
          extra: speaker,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 5,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Photo - takes ~75% of card
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
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

            // Info section - takes ~25% of card
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 6 : 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unknown Speaker',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Position
                    if (position.isNotEmpty)
                      Text(
                        position,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 10 : 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
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
