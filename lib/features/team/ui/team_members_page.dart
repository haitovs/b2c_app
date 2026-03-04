import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/delete_confirm_dialog.dart';
import '../../company/providers/company_providers.dart';
import '../../company/models/company.dart';
import '../providers/team_providers.dart';
import '../models/team_member.dart';

/// Team Members listing page.
///
/// Loads the current user's companies for the event, provides a company
/// selector when multiple companies exist, and displays the team member
/// list for the selected company. Supports adding, editing, deleting, and
/// changing roles of team members.
class TeamMembersPage extends ConsumerStatefulWidget {
  const TeamMembersPage({super.key});

  @override
  ConsumerState<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends ConsumerState<TeamMembersPage> {
  String? _selectedCompanyId;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final eventId = int.tryParse(eventIdStr) ?? 0;

    final companiesAsync = ref.watch(myCompaniesProvider(eventId));

    return EventSidebarLayout(
      title: 'Team Members',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () => context.go('/events/$eventIdStr/team/add'),
            icon: const Icon(Icons.person_add, size: 18),
            label: Text(
              'Add Member',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
        ),
      ],
      child: companiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, _) => _buildErrorView(error, eventId),
        data: (companies) {
          if (companies.isEmpty) {
            return _buildNoCompanyView(eventIdStr);
          }
          return _buildContent(companies, eventIdStr);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error View
  // ---------------------------------------------------------------------------

  Widget _buildErrorView(Object error, int eventId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load companies',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(myCompaniesProvider(eventId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // No Company State
  // ---------------------------------------------------------------------------

  Widget _buildNoCompanyView(String eventId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_outlined,
                size: 36,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No company profile yet',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a company profile first to start adding team members.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/events/$eventId/company-profile'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Company'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(List<Company> companies, String eventId) {
    // Default to first company if none selected or selected is stale
    if (_selectedCompanyId == null ||
        !companies.any((c) => c.id == _selectedCompanyId)) {
      // Schedule the update after the build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedCompanyId = companies.first.id);
        }
      });
      // Use first company for this frame
      _selectedCompanyId ??= companies.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header
              _buildPageHeader(),
              const SizedBox(height: 20),

              // Company selector (only if multiple companies)
              if (companies.length > 1)
                _buildCompanySelector(companies),
              if (companies.length > 1)
                const SizedBox(height: 20),

              // Team members list
              _buildTeamMembersList(eventId),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.people,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Members',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage the members and roles for your company',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Company Selector
  // ---------------------------------------------------------------------------

  Widget _buildCompanySelector(List<Company> companies) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.business, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            'Company:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCompanyId,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600,
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: companies.map((company) {
                  return DropdownMenuItem<String>(
                    value: company.id,
                    child: Text(
                      company.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCompanyId = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Team Members List
  // ---------------------------------------------------------------------------

  Widget _buildTeamMembersList(String eventId) {
    if (_selectedCompanyId == null) {
      return const SizedBox.shrink();
    }

    final membersAsync = ref.watch(teamMembersProvider(_selectedCompanyId!));

    return membersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (error, _) => _buildMembersError(error),
      data: (members) {
        if (members.isEmpty) {
          return _buildEmptyMembersView(eventId);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Count header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${members.length} member${members.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            // Member cards
            ...members.map(
              (member) => _buildMemberCard(member, eventId),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersError(Object error) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Failed to load team members',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                if (_selectedCompanyId != null) {
                  ref.invalidate(teamMembersProvider(_selectedCompanyId!));
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: AppTheme.secondaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMembersView(String eventId) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_outlined,
                size: 36,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No team members yet',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 320,
              child: Text(
                'Add team members to collaborate on your company profile and manage event participation.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/events/$eventId/team/add'),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Team Member'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Member Card
  // ---------------------------------------------------------------------------

  Widget _buildMemberCard(TeamMember member, String eventId) {
    final initials = _getInitials(member.firstName, member.lastName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            if (isWide) {
              return Row(
                children: [
                  _buildAvatar(member, initials),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMemberInfo(member)),
                  const SizedBox(width: 12),
                  _buildRoleBadge(member),
                  const SizedBox(width: 16),
                  _buildActionButtons(member, eventId),
                ],
              );
            }

            // Narrow layout: stacked
            return Column(
              children: [
                Row(
                  children: [
                    _buildAvatar(member, initials),
                    const SizedBox(width: 14),
                    Expanded(child: _buildMemberInfo(member)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRoleBadge(member),
                    _buildActionButtons(member, eventId),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(TeamMember member, String initials) {
    if (member.profilePhotoUrl != null &&
        member.profilePhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(member.profilePhotoUrl!),
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildMemberInfo(TeamMember member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          member.fullName,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (member.position != null && member.position!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            member.position!,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                member.email,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleBadge(TeamMember member) {
    final isAdmin = member.isAdmin;
    final roleLabel = isAdmin ? 'ADMINISTRATOR' : 'USER';
    final badgeColor =
        isAdmin ? AppTheme.primaryColor : AppTheme.successColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        roleLabel,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(TeamMember member, String eventId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Change role
        _ActionIconButton(
          icon: Icons.swap_horiz,
          tooltip: member.isAdmin ? 'Set as User' : 'Set as Administrator',
          color: Colors.blueGrey,
          onPressed: () => _changeRole(member),
        ),
        const SizedBox(width: 4),
        // Edit
        _ActionIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit member',
          color: AppTheme.primaryColor,
          onPressed: () {
            context.go('/events/$eventId/team/${member.id}/edit');
          },
        ),
        const SizedBox(width: 4),
        // Delete
        _ActionIconButton(
          icon: Icons.delete_outlined,
          tooltip: 'Delete member',
          color: AppTheme.errorColor,
          onPressed: _isDeleting ? null : () => _confirmDelete(member),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _changeRole(TeamMember member) async {
    final newRole =
        member.isAdmin ? 'USER' : 'ADMINISTRATOR';
    final newRoleLabel = member.isAdmin ? 'User' : 'Administrator';

    try {
      final service = ref.read(teamServiceProvider);
      await service.changeRole(member.id, newRole);

      // Refresh the list
      if (_selectedCompanyId != null) {
        ref.invalidate(teamMembersProvider(_selectedCompanyId!));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${member.fullName} is now a $newRoleLabel',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change role: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _confirmDelete(TeamMember member) async {
    final confirmed = await DeleteConfirmDialog.show(
      context,
      title: 'Delete Team Member',
      message:
          'Are you sure you want to remove ${member.fullName} from the team? '
          'This action cannot be undone.',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final service = ref.read(teamServiceProvider);
      await service.deleteTeamMember(member.id);

      // Refresh the list
      if (_selectedCompanyId != null) {
        ref.invalidate(teamMembersProvider(_selectedCompanyId!));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.fullName} has been removed'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete member: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
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
}

// ---------------------------------------------------------------------------
// Small Action Icon Button
// ---------------------------------------------------------------------------

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
