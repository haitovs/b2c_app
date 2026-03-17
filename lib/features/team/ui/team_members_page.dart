import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../shared/widgets/delete_confirm_dialog.dart';
import '../../company/providers/company_providers.dart';
import '../../company/models/company.dart';
import '../providers/team_providers.dart';
import '../models/team_member.dart';

/// "My Team Members" — table listing all team members across companies.
class TeamMembersPage extends ConsumerStatefulWidget {
  const TeamMembersPage({super.key});

  @override
  ConsumerState<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends ConsumerState<TeamMembersPage> {
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
    final membersAsync = ref.watch(allTeamMembersProvider(eventId));
    final companiesAsync = ref.watch(myCompaniesProvider(eventId));

    return membersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (error, _) => _buildError(error, eventId),
      data: (members) {
        final companies = companiesAsync.when(
          data: (c) => c,
          loading: () => <Company>[],
          error: (_, __) => <Company>[],
        );
        return _buildBody(members, companies, eventIdStr, eventId);
      },
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
          Text(error.toString(),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(allTeamMembersProvider(eventId)),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    List<TeamMember> members,
    List<Company> companies,
    String eventIdStr,
    int eventId,
  ) {
    final filtered = _searchQuery.isEmpty
        ? members
        : members.where((m) {
            final q = _searchQuery.toLowerCase();
            return m.fullName.toLowerCase().contains(q) ||
                m.email.toLowerCase().contains(q) ||
                (m.position ?? '').toLowerCase().contains(q);
          }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + Add button
          Row(
            children: [
              Expanded(
                child: Text(
                  isMobile ? 'Team Members' : 'My Team Members',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('/events/$eventIdStr/team/add'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search bar + Sort (only show when there are members)
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        borderSide:
                            const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Sort by: All',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.expand_more,
                          size: 18, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Table or mobile list
          Expanded(
            child: members.isEmpty
                ? _buildEmptyState(eventIdStr)
                : isMobile
                    ? _buildMobileList(filtered, companies, eventIdStr, eventId)
                    : _buildTable(filtered, companies, eventIdStr, eventId),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String eventIdStr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
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
            'Add your first team member to get started',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.go('/events/$eventIdStr/team/add'),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add Team Member'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    List<TeamMember> members,
    List<Company> companies,
    String eventIdStr,
    int eventId,
  ) {
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = members[index];
        final companyName = companies
            .where((c) => c.id == member.companyId)
            .map((c) => c.name)
            .firstOrNull ?? '';
        final initials = _getInitials(member.firstName, member.lastName);

        return ListTile(
          leading: _buildAvatar(member, initials),
          title: Text(
            member.fullName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            [member.position ?? '', companyName]
                .where((e) => e.isNotEmpty)
                .join(' · '),
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  context.go('/events/$eventIdStr/team/${member.id}/edit');
                case 'role':
                  _changeRole(member, eventId);
                case 'delete':
                  _confirmDelete(member, eventId);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'role',
                child: Row(children: [
                  const Icon(Icons.swap_horiz, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    member.isAdmin ? 'Set as User' : 'Set as Admin',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Delete',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.red)),
                ]),
              ),
            ],
          ),
          onTap: () => context.go('/events/$eventIdStr/team/${member.id}/edit'),
        );
      },
    );
  }

  Widget _buildTable(
    List<TeamMember> members,
    List<Company> companies,
    String eventIdStr,
    int eventId,
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
                Expanded(
                  flex: 3,
                  child: Text('Name', style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Company', style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Position', style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Email', style: _headerStyle),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Role', style: _headerStyle),
                ),
                SizedBox(
                  width: 70,
                  child: Text('Attend', style: _headerStyle),
                ),
                const SizedBox(width: 40),
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
                final member = members[index];
                return _buildRow(member, companies, eventIdStr, eventId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    TeamMember member,
    List<Company> companies,
    String eventIdStr,
    int eventId,
  ) {
    final companyName = companies
        .where((c) => c.id == member.companyId)
        .map((c) => c.name)
        .firstOrNull ?? '';
    final initials = _getInitials(member.firstName, member.lastName);

    return InkWell(
      onTap: () => context.go(
          '/events/$eventIdStr/team/${member.id}/edit'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar + Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _buildAvatar(member, initials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      member.fullName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Company
            Expanded(
              flex: 2,
              child: Text(
                companyName,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Position
            Expanded(
              flex: 2,
              child: Text(
                member.position ?? '',
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Email
            Expanded(
              flex: 2,
              child: Text(
                member.email,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Role badge
            Expanded(
              flex: 1,
              child: _buildRoleBadge(member),
            ),
            // Attend indicator
            SizedBox(
              width: 70,
              child: Icon(
                member.willAttend
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                size: 20,
                color: member.willAttend
                    ? AppTheme.successColor
                    : Colors.grey.shade400,
              ),
            ),
            // More menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 20, color: Colors.grey.shade600),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.go(
                        '/events/$eventIdStr/team/${member.id}/edit');
                  case 'role':
                    _changeRole(member, eventId);
                  case 'delete':
                    _confirmDelete(member, eventId);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'role',
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        member.isAdmin ? 'Set as User' : 'Set as Administrator',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(TeamMember member, String initials) {
    if (member.profilePhotoUrl != null &&
        member.profilePhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(member.profilePhotoUrl!),
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(TeamMember member) {
    final isAdmin = member.isAdmin;
    final roleLabel = isAdmin ? 'Admin' : 'User';
    final badgeColor =
        isAdmin ? AppTheme.primaryColor : AppTheme.successColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        roleLabel,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _changeRole(TeamMember member, int eventId) async {
    final newRole = member.isAdmin ? 'USER' : 'ADMINISTRATOR';
    final newRoleLabel = member.isAdmin ? 'User' : 'Administrator';

    try {
      final service = ref.read(teamServiceProvider);
      await service.changeRole(member.id, newRole);
      ref.invalidate(allTeamMembersProvider(eventId));

      if (!mounted) return;
      AppSnackBar.showSuccess(context, '${member.fullName} is now a $newRoleLabel');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Failed to change role: $e');
    }
  }

  Future<void> _confirmDelete(TeamMember member, int eventId) async {
    final confirmed = await DeleteConfirmDialog.show(
      context,
      title: 'Delete Team Member',
      message:
          'Are you sure you want to remove ${member.fullName} from the team? '
          'This action cannot be undone.',
    );

    if (confirmed != true || !mounted) return;

    try {
      final service = ref.read(teamServiceProvider);
      await service.deleteTeamMember(member.id);
      ref.invalidate(allTeamMembersProvider(eventId));

      if (!mounted) return;
      AppSnackBar.showSuccess(context, '${member.fullName} has been removed');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Failed to delete member: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _getInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );
}
