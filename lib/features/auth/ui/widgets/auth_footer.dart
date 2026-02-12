import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import 'hover_text.dart';

/// Shared footer for auth pages: "All rights reserved | Privacy Policy | Cookies | Powered by [logo]"
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 5,
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text("All rights reserved", style: AppTextStyles.footer),
        _divider(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {},
            child: HoverText(
              text: "Privacy Policy",
              baseStyle: AppTextStyles.footer,
              hoverColor: AppColors.buttonBackground,
            ),
          ),
        ),
        _divider(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {},
            child: HoverText(
              text: "Cookies",
              baseStyle: AppTextStyles.footer,
              hoverColor: AppColors.buttonBackground,
            ),
          ),
        ),
        _divider(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Powered by", style: AppTextStyles.footer),
            const SizedBox(width: 5),
            Image.asset(
              'assets/login_signup/terms_logo.png',
              width: 24,
              height: 24,
            ),
          ],
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 12, color: AppColors.textFooter);
  }
}
