import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_theme.dart';
import '../../../auth/services/auth_service.dart';

class ProfileDropdown extends StatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onClose; // Callback to close the dropdown

  const ProfileDropdown({super.key, this.onLogout, this.onClose});

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown>
    with SingleTickerProviderStateMixin {
  bool _isLanguageExpanded = false;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  String _currentLanguage = "RUS";

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
    // Watch auth service for user changes
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
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
                      child: const Icon(Icons.person, color: Colors.grey),
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
                        _buildLangOption("RUS"),
                        const SizedBox(height: 8),
                        _buildLangOption("EN"),
                        const SizedBox(height: 8),
                        _buildLangOption("TKM"),
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
                await authService.logout();
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

  Widget _buildLangOption(String code) {
    bool isSelected = _currentLanguage == code;
    return InkWell(
      onTap: () {
        setState(() {
          _currentLanguage = code;
        });
        // Optionally close after selecting language
        // widget.onClose?.call();
      },
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
          color: isSelected ? AppColors.textPrimary : const Color(0xFF1C1C1C),
        ),
      ),
    );
  }
}
