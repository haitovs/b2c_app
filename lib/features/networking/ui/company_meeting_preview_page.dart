import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/meeting_providers.dart';

/// Preview page for a company's meeting-available team members.
/// Rendered inside EventShellLayout (no Scaffold needed).
class CompanyMeetingPreviewPage extends ConsumerStatefulWidget {
  final String eventId;
  final String companyId;
  final Map<String, dynamic>? companyData;

  const CompanyMeetingPreviewPage({
    super.key,
    required this.eventId,
    required this.companyId,
    this.companyData,
  });

  @override
  ConsumerState<CompanyMeetingPreviewPage> createState() =>
      _CompanyMeetingPreviewPageState();
}

class _CompanyMeetingPreviewPageState
    extends ConsumerState<CompanyMeetingPreviewPage> {
  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _visibleMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCompanyDetail();
  }

  Future<void> _fetchCompanyDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final meetingService = ref.read(meetingServiceProvider);
      final data = await meetingService.fetchPublicCompany(widget.companyId);

      if (!mounted) return;

      final allMembers =
          (data['team_members'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      setState(() {
        _company = data;
        _visibleMembers = allMembers
            .where((m) => m['will_attend'] == true && m['allow_meeting_requests'] == true)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load company: $e';
        _isLoading = false;
      });
    }
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
  }

  // --- Computed helpers ---

  String get _companyName =>
      _company?['name'] as String? ??
      widget.companyData?['name'] as String? ??
      '';

  String get _companyCategories {
    final cats = _company?['categories'] ?? widget.companyData?['categories'];
    if (cats is List) return cats.join(', ');
    if (cats is String) return cats;
    return '';
  }

  String get _companyLogoUrl {
    final logo = _company?['brand_icon_url'] as String? ??
        _company?['full_logo_url'] as String? ??
        widget.companyData?['brand_icon_url'] as String? ??
        widget.companyData?['full_logo_url'] as String? ??
        '';
    return _buildImageUrl(logo);
  }

  String? get _companyAbout => _company?['about'] as String?;

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Meetings',
            style: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFCACACA)),
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: GoogleFonts.inter(fontSize: 14, color: Colors.red)),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _fetchCompanyDetail,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyCard(),
          const SizedBox(height: 32),
          _buildTeamMembersSection(),
        ],
      ),
    );
  }

  // --- Company header card ---

  Widget _buildCompanyCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Logo
          _companyLogoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _companyLogoUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                  ),
                )
              : _buildLogoPlaceholder(),
          const SizedBox(height: 16),
          // Name
          Text(
            _companyName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          if (_companyCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _companyCategories,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF747474),
              ),
            ),
          ],
          // About section
          if (_companyAbout != null && _companyAbout!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE0E0E0)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _companyAbout!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF747474),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: Icon(Icons.business, size: 48, color: Colors.grey.shade400),
    );
  }

  // --- Team members ---

  Widget _buildTeamMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Members',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (_visibleMembers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No team members available for meetings',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF747474),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _visibleMembers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _buildTeamMemberCard(_visibleMembers[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    final photoUrl = _buildImageUrl(member['profile_photo_url'] as String?);
    final firstName = member['first_name'] as String? ?? '';
    final lastName = member['last_name'] as String? ?? '';
    final position = member['position'] as String? ?? '';

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          // Avatar
          photoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    photoUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                  ),
                )
              : _buildAvatarPlaceholder(),
          const SizedBox(height: 10),
          // Name
          Text(
            '$firstName $lastName'.trim(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (position.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              position,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const Spacer(),
          // Request Meeting button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () => _onRequestMeeting(member),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Request Meeting'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: Icon(Icons.person, size: 24, color: Colors.grey.shade400),
    );
  }

  void _onRequestMeeting(Map<String, dynamic> teamMember) {
    context.push(
      '/events/${widget.eventId}/meetings/new/${teamMember['user_id']}',
      extra: {
        'first_name': teamMember['first_name'],
        'last_name': teamMember['last_name'],
        'position': teamMember['position'],
        'profile_photo_url': teamMember['profile_photo_url'],
        'company_name': _companyName,
        'company_categories': _companyCategories,
        'company_logo_url': _companyLogoUrl,
      },
    );
  }
}
