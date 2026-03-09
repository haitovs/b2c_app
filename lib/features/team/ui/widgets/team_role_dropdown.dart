import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

// =============================================================================
// TeamRoleDropdown — overlay-based role selector
// =============================================================================

class TeamRoleDropdown extends StatefulWidget {
  final String currentRole;
  final ValueChanged<String> onRoleChanged;

  const TeamRoleDropdown({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
  });

  @override
  State<TeamRoleDropdown> createState() => _TeamRoleDropdownState();
}

class _TeamRoleDropdownState extends State<TeamRoleDropdown> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final label =
        widget.currentRole == 'ADMINISTRATOR' ? 'Administrator' : 'User';

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (_) => _buildOverlay(),
        child: InkWell(
          onTap: () => _overlayController.toggle(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/team/gear.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade600,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _overlayController.hide(),
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRoleItem(
                      role: 'USER',
                      title: 'User',
                      description:
                          'can view and edit only\ntheir own information.',
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildRoleItem(
                      role: 'ADMINISTRATOR',
                      title: 'Administrator',
                      description:
                          'can view and edit\ninformation for all users.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem({
    required String role,
    required String title,
    required String description,
  }) {
    final isSelected = widget.currentRole == role;

    return InkWell(
      onTap: () {
        _overlayController.hide();
        if (role != widget.currentRole) {
          widget.onRoleChanged(role);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
                color: isSelected ? AppTheme.primaryColor : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
