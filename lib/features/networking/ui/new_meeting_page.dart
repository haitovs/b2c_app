import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../company/providers/company_providers.dart';
import '../providers/meeting_providers.dart';

/// New Meeting Page - Grid of participants/entities to select for meeting
/// Rendered inside EventShellLayout (sidebar + top bar already provided)
class NewMeetingPage extends ConsumerStatefulWidget {
  final String eventId;
  final bool initialIsB2G;

  const NewMeetingPage({
    super.key,
    required this.eventId,
    this.initialIsB2G = false,
  });

  @override
  ConsumerState<NewMeetingPage> createState() => _NewMeetingPageState();
}

class _NewMeetingPageState extends ConsumerState<NewMeetingPage> {
  late bool _isB2B;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'all';

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _govEntities = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isB2B = !widget.initialIsB2G;
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await ref
          .read(eventContextProvider.notifier)
          .ensureEventContext(eventId);
    }
    _fetchData();
  }

  void _onToggleChanged(bool isB2B) {
    setState(() {
      _isB2B = isB2B;
      _applyFilters();
    });
    if (!isB2B && _govEntities.isEmpty) {
      _fetchGovEntities();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      try {
        final meetingService = ref.read(meetingServiceProvider);
        final eventId = int.tryParse(widget.eventId) ?? 0;
        _companies = await meetingService.fetchPublicCompanies(eventId: eventId);

        // Filter out user's own companies
        try {
          final myCompanies = await ref.read(myCompaniesProvider(eventId).future);
          final myCompanyIds = myCompanies.map((c) => c.id).toSet();
          _companies = _companies
              .where((c) => !myCompanyIds.contains(c['id']?.toString()))
              .toList();
        } catch (_) {
          // If we can't fetch own companies, show all (safe fallback)
        }
      } catch (companiesError) {
        if (kDebugMode) debugPrint('Error fetching public companies: $companiesError');
      }
      if (!_isB2B) {
        await _fetchGovEntities();
      }
      setState(() {
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGovEntities() async {
    if (_govEntities.isNotEmpty) return;
    try {
      final meetingService = ref.read(meetingServiceProvider);
      final entities = await meetingService.fetchGovEntities();
      setState(() {
        _govEntities = entities;
        _applyFilters();
      });
    } catch (govError) {
      if (kDebugMode) debugPrint('Error fetching gov entities: $govError');
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> source =
        _isB2B ? _companies : _govEntities;
    List<Map<String, dynamic>> result = List.from(source);

    if (_searchQuery.isNotEmpty) {
      result = result.where((item) {
        if (_isB2B) {
          final companyName =
              (item['name'] ?? '').toString().toLowerCase();
          final categories =
              (item['categories'] ?? []).toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return companyName.contains(query) ||
              categories.contains(query);
        } else {
          final name = (item['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }
      }).toList();
    }

    // Sort by name if selected
    if (_sortBy == 'name') {
      result.sort((a, b) {
        final aName = (a['name'] ?? '').toString();
        final bName = (b['name'] ?? '').toString();
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });
    }

    setState(() {
      _filteredItems = result;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${AppConfig.b2cApiBaseUrl}$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row: "Meetings" + B2B/B2G toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Text(
                'Meetings',
                style: GoogleFonts.montserrat(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4494),
                ),
              ),
              const Spacer(),
              _buildMeetingTypeToggle(isMobile),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            color: Color(0xFFCACACA),
            thickness: 0.5,
            height: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        // Search + Sort row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchSortRow(isMobile),
        ),
        const SizedBox(height: 16),
        // Grid content
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildItemsGrid(),
                ),
        ),
      ],
    );
  }

  Widget _buildMeetingTypeToggle(bool isMobile) {
    final fontSize = isMobile ? 14.0 : 20.0;
    final toggleWidth = isMobile ? 80.0 : 113.0;
    final toggleHeight = isMobile ? 32.0 : 38.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onToggleChanged(true),
          child: Container(
            width: toggleWidth,
            height: toggleHeight,
            alignment: Alignment.center,
            color: _isB2B
                ? const Color(0xFF3C4494)
                : const Color(0xFFE6E7F2),
            child: Text(
              'B2B',
              style: GoogleFonts.montserrat(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: _isB2B ? Colors.white : const Color(0xFF3C4494),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _onToggleChanged(false),
          child: Container(
            width: toggleWidth,
            height: toggleHeight,
            alignment: Alignment.center,
            color: !_isB2B
                ? const Color(0xFF3C4494)
                : const Color(0xFFE6E7F2),
            child: Text(
              'B2G',
              style: GoogleFonts.montserrat(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: !_isB2B ? Colors.white : const Color(0xFF3C4494),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSortRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSortDropdown()),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: 5, child: _buildSearchBar()),
        const SizedBox(width: 12),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: _isB2B ? 'Search companies...' : 'Search entities...',
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: const Color(0xFFE6E7F2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCBCBCB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCBCBCB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFCBCBCB), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Color(0xFF6B7280)),
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF757A8A),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Sort by: All')),
            DropdownMenuItem(value: 'name', child: Text('Sort by: Name')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _sortBy = v;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildItemsGrid() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No companies found',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 1100) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        // Figma cards: 184x183 ~ 1:1
        const childAspectRatio = 184.0 / 183.0;
        // Figma gap between cards: ~10px
        const gridSpacing = 10.0;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredItems.length,
          itemBuilder: (context, index) {
            return _buildItemCard(_filteredItems[index]);
          },
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    String name;
    String? imageUrl;
    String? subtitle;

    if (_isB2B) {
      name = (item['name'] ?? '').toString();
      if (name.isEmpty) name = 'Unknown Company';
      final categories = item['categories'];
      if (categories is List && categories.isNotEmpty) {
        subtitle = categories.join(', ');
      }
      imageUrl = _buildImageUrl(
        (item['brand_icon_url'] ?? item['full_logo_url']) as String?,
      );
    } else {
      name = item['name'] ?? 'Unknown Entity';
      imageUrl = _buildImageUrl(item['logo_url'] as String?);
    }

    final itemId = item['id'];

    return GestureDetector(
      onTap: () async {
        dynamic result;
        if (_isB2B) {
          result = await context.push(
            '/events/${widget.eventId}/meetings/company/$itemId',
            extra: item,
          );
        } else {
          result = await context.push(
            '/events/${widget.eventId}/meetings/new/b2g/$itemId',
            extra: item,
          );
        }
        if (result == true && mounted) {
          context.pop(true);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image area with padding (Figma: ~5.43% sides, ~5.46% top)
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5C5C5),
                    border: Border.all(
                      color: const Color(0xFFDDDDDD),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPhotoPlaceholder(),
                        )
                      : _buildPhotoPlaceholder(),
                ),
              ),
            ),
            // Name section
            Expanded(
              flex: 25,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Center(
      child: Icon(
        _isB2B ? Icons.business : Icons.account_balance,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }
}
