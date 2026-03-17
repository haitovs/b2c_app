import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';

class ProfileDropdown extends ConsumerStatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onClose; // Callback to close the dropdown

  const ProfileDropdown({super.key, this.onLogout, this.onClose});

  @override
  ConsumerState<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends ConsumerState<ProfileDropdown>
    with SingleTickerProviderStateMixin {
  bool _isLanguageExpanded = false;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  String _currentLanguage = "EN";

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(_rotationController);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _isLanguageExpanded = !_isLanguageExpanded;
      if (_isLanguageExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    });
  }

  void _closeAndNavigate(VoidCallback action) {
    // Close the dropdown first, then perform the action
    widget.onClose?.call();
    action();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for user changes
    final authState = ref.watch(authNotifierProvider);
    final user = authState.currentUser;
    final String fullName = user != null
        ? "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}"
        : "Guest";

    return Container(
      width: 406,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF9CA4CC),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 10),
            blurRadius: 10,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User Info Card
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              onTap: () => _closeAndNavigate(() => context.push('/profile')),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 57,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          user?['photo_url'] != null &&
                              (user!['photo_url'] as String).isNotEmpty
                          ? Image.network(
                              user['photo_url'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: Colors.grey),
                            )
                          : const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF1C1C1C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Language Selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: _toggleLanguage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.language, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Language",
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        const Spacer(),
                        RotationTransition(
                          turns: _rotationAnimation,
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLanguageExpanded)
                  Container(
                    padding: const EdgeInsets.only(left: 63, bottom: 10),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLangOption("EN"),
                        const SizedBox(height: 8),
                        _buildLangOption("RUS", comingSoon: true),
                        const SizedBox(height: 8),
                        _buildLangOption("TKM", comingSoon: true),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Logout Button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              onTap: () => _closeAndNavigate(() async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 57,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 20),
                    Text(
                      "Log out",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF1C1C1C),
                      ),
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

  Widget _buildLangOption(String code, {bool comingSoon = false}) {
    bool isSelected = _currentLanguage == code;
    return InkWell(
      onTap: comingSoon
          ? null
          : () {
              setState(() {
                _currentLanguage = code;
              });
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: comingSoon
                  ? Colors.grey
                  : isSelected
                      ? AppColors.textPrimary
                      : const Color(0xFF1C1C1C),
            ),
          ),
          if (comingSoon) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Coming soon',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
