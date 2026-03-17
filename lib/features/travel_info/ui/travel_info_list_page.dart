import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/travel_info_providers.dart';

/// Lists team members with their travel information status.
class TravelInfoListPage extends ConsumerStatefulWidget {
  const TravelInfoListPage({super.key});

  @override
  ConsumerState<TravelInfoListPage> createState() => _TravelInfoListPageState();
}

class _TravelInfoListPageState extends ConsumerState<TravelInfoListPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;
    final membersAsync = ref.watch(travelTeamMembersProvider(eventId));

    return membersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, _) => _buildError(error, eventId),
      data: (members) => _buildBody(members, eventIdStr, eventId),
    );
  }

  Widget _buildError(Object error, int eventId) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load team members',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.invalidate(travelTeamMembersProvider(eventId)),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    List<Map<String, dynamic>> members,
    String eventIdStr,
    int eventId,
  ) {
    final filtered = _searchQuery.isEmpty
        ? members
        : members.where((m) {
            final q = _searchQuery.toLowerCase();
            final name = (m['first_name'] ?? '').toString().toLowerCase();
            final surname = (m['last_name'] ?? '').toString().toLowerCase();
            final email = (m['email'] ?? '').toString().toLowerCase();
            final company =
                (m['company_name'] ?? '').toString().toLowerCase();
            return name.contains(q) ||
                surname.contains(q) ||
                email.contains(q) ||
                company.contains(q);
          }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Travel Information',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Search bar
          if (members.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search team members...',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Table or mobile list
          Expanded(
            child: members.isEmpty
                ? _buildEmptyState()
                : isMobile
                    ? _buildMobileList(filtered, eventIdStr)
                    : _buildTable(filtered, eventIdStr),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No team members yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Team members will appear here once added',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile card list
  // ---------------------------------------------------------------------------

  Widget _buildMobileList(
    List<Map<String, dynamic>> members,
    String eventIdStr,
  ) {
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = members[index];
        final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
        final email = (m['email'] ?? '').toString();
        final company = (m['company_name'] ?? '').toString();
        final status = (m['travel_status'] ?? 'NOT_STARTED').toString();
        final memberId = (m['team_member_id'] ?? '').toString();
        final initials = _getInitials(
          (m['first_name'] ?? '').toString(),
          (m['last_name'] ?? '').toString(),
        );
        final photoUrl = (m['profile_photo_url'] ?? '').toString();

        return ListTile(
          leading: _buildAvatar(photoUrl, initials),
          title: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (email.isNotEmpty)
                Text(
                  email,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (company.isNotEmpty)
                Text(
                  company,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: _buildStatusChip(status),
          onTap: () =>
              context.go('/events/$eventIdStr/travel/$memberId'),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop table
  // ---------------------------------------------------------------------------

  Widget _buildTable(
    List<Map<String, dynamic>> members,
    String eventIdStr,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48), // avatar space
                Expanded(flex: 2, child: Text('Name', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Surname', style: _headerStyle)),
                Expanded(flex: 3, child: Text('Email', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Phone', style: _headerStyle)),
                Expanded(
                    flex: 2, child: Text('Company', style: _headerStyle)),
                const SizedBox(
                    width: 120, child: Text('Status')),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Data rows
          Expanded(
            child: ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final m = members[index];
                return _buildTableRow(m, eventIdStr);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> m, String eventIdStr) {
    final firstName = (m['first_name'] ?? '').toString();
    final lastName = (m['last_name'] ?? '').toString();
    final email = (m['email'] ?? '').toString();
    final phone = (m['mobile'] ?? '').toString();
    final company = (m['company_name'] ?? '').toString();
    final status = (m['travel_status'] ?? 'NOT_STARTED').toString();
    final memberId = (m['team_member_id'] ?? '').toString();
    final photoUrl = (m['profile_photo_url'] ?? '').toString();
    final initials = _getInitials(firstName, lastName);

    return InkWell(
      onTap: () => context.go('/events/$eventIdStr/travel/$memberId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(photoUrl, initials),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                firstName,
                style: GoogleFonts.inter(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                lastName,
                style: GoogleFonts.inter(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                email,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                phone,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                company,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 120, child: _buildStatusChip(status)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'COMPLETED':
        bgColor = AppTheme.primaryColor.withValues(alpha: 0.1);
        textColor = AppTheme.primaryColor;
        label = 'Completed';
      case 'IN_PROGRESS':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'In Progress';
      default: // NOT_STARTED
        bgColor = AppTheme.successColor.withValues(alpha: 0.1);
        textColor = AppTheme.successColor;
        label = 'Fill in';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAvatar(String photoUrl, String initials) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: Colors.grey.shade200,
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  String _getInitials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l';
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      );
}
