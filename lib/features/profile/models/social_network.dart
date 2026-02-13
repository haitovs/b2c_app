import 'package:flutter/material.dart';

enum SocialNetwork {
  instagram(
    key: 'INSTAGRAM',
    label: 'Instagram',
    icon: Icons.camera_alt_outlined,
    hintText: '@username',
  ),
  whatsapp(
    key: 'WHATSAPP',
    label: 'WhatsApp',
    icon: Icons.chat_outlined,
    hintText: '+993 xx xx xx xx',
  ),
  facebook(
    key: 'FACEBOOK',
    label: 'Facebook',
    icon: Icons.facebook_outlined,
    hintText: 'facebook.com/username',
  ),
  twitter(
    key: 'TWITTER',
    label: 'Twitter',
    icon: Icons.alternate_email,
    hintText: '@username',
  ),
  linkedin(
    key: 'LINKEDIN',
    label: 'LinkedIn',
    icon: Icons.work_outline,
    hintText: 'linkedin.com/in/username',
  );

  const SocialNetwork({
    required this.key,
    required this.label,
    required this.icon,
    required this.hintText,
  });

  final String key;
  final String label;
  final IconData icon;
  final String hintText;

  static SocialNetwork? fromKey(String key) {
    for (final network in values) {
      if (network.key == key) return network;
    }
    return null;
  }
}

class SocialLinkEntry {
  SocialLinkEntry({required this.network, String? initialValue})
      : controller = TextEditingController(text: initialValue ?? '');

  final SocialNetwork network;
  final TextEditingController controller;

  Map<String, String> toJson() => {
        'network': network.key,
        'handle': controller.text,
      };

  void dispose() => controller.dispose();
}
