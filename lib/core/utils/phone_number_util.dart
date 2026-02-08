/// Phone Number Utility
/// Handles conversion between E.164 format and display format
class PhoneNumberUtil {
  /// Combine country dial code and local number to E.164 format
  ///
  /// Example:
  /// ```dart
  /// toE164('+993', '61444555') // Returns: '+99361444555'
  /// ```
  static String toE164(String dialCode, String localNumber) {
    // Remove all non-digit characters from local number
    final cleaned = localNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure dial code starts with +
    final code = dialCode.startsWith('+') ? dialCode : '+$dialCode';

    return '$code$cleaned';
  }

  /// Parse E.164 phone number to dial code and local number
  ///
  /// Example:
  /// ```dart
  /// fromE164('+99361444555')
  /// // Returns: {'dialCode': '+993', 'localNumber': '61444555'}
  /// ```
  static Map<String, String> fromE164(String e164Phone) {
    if (!e164Phone.startsWith('+')) {
      // Not in E.164 format, return as-is with default dial code
      return {'dialCode': '+993', 'localNumber': e164Phone};
    }

    // Known dial codes sorted by length (longest first for accurate matching)
    const knownDialCodes = [
      '+1684', '+1264', '+1268', '+1242', '+1246', '+1441', '+1284', '+1345',
      '+1767', '+1809', '+1829', '+1849', '+1473', '+1671', '+1876', '+1664',
      '+1787', '+1939', '+1869', '+1758', '+1784', '+1868', '+1649', '+1340',
      // 4-digit codes
      '+993', '+994', '+995', '+996', '+998', '+992', // Central Asia
      '+380', '+375', '+374', '+373', '+371', '+370', // Eastern Europe
      '+353', '+354', '+358', '+359', '+351', '+352', // Western Europe
      '+852', '+853', '+886', '+880', '+855', '+856', // East Asia
      // 3-digit codes
      '+90', '+91', '+92', '+93', '+94', '+95', '+98', // Asia
      '+20', '+27', '+30', '+31', '+32', '+33', '+34', '+36', '+39', // Europe
      '+40', '+41', '+43', '+44', '+45', '+46', '+47', '+48', '+49', // Europe
      '+51', '+52', '+53', '+54', '+55', '+56', '+57', '+58', // Americas
      '+60', '+61', '+62', '+63', '+64', '+65', '+66', // Asia-Pacific
      '+81', '+82', '+84', '+86', // East Asia
      // 2-digit and 1-digit codes
      '+7', '+1', // Russia/Kazakhstan, NANP
    ];

    // Try to match known dial codes (longest match first)
    for (final code in knownDialCodes) {
      if (e164Phone.startsWith(code)) {
        final local = e164Phone.substring(code.length);
        if (local.isNotEmpty) {
          return {'dialCode': code, 'localNumber': local};
        }
      }
    }

    // Fallback: try different lengths from longest to shortest
    for (int len = 4; len >= 1; len--) {
      if (e164Phone.length > len + 1) {
        final code = e164Phone.substring(0, len + 1);
        final local = e164Phone.substring(len + 1);
        if (local.isNotEmpty && RegExp(r'^\d').hasMatch(local)) {
          return {'dialCode': code, 'localNumber': local};
        }
      }
    }

    // Last resort: assume +993 with remaining as local
    return {'dialCode': '+993', 'localNumber': e164Phone.substring(1)};
  }

  /// Validate if phone number is in E.164 format
  ///
  /// E.164 format: +[1-9][0-9]{1,14}
  static bool isValidE164(String phone) {
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(phone);
  }

  /// Get ISO country code from dial code
  /// Used for CountryCodePicker initialization
  static String getCountryISO(String dialCode) {
    const dialCodeToISO = {
      '+1': 'US',
      '+7': 'RU',
      '+20': 'EG',
      '+27': 'ZA',
      '+30': 'GR',
      '+31': 'NL',
      '+32': 'BE',
      '+33': 'FR',
      '+34': 'ES',
      '+36': 'HU',
      '+39': 'IT',
      '+40': 'RO',
      '+41': 'CH',
      '+43': 'AT',
      '+44': 'GB',
      '+45': 'DK',
      '+46': 'SE',
      '+47': 'NO',
      '+48': 'PL',
      '+49': 'DE',
      '+90': 'TR',
      '+91': 'IN',
      '+92': 'PK',
      '+93': 'AF',
      '+94': 'LK',
      '+95': 'MM',
      '+98': 'IR',
      '+992': 'TJ',
      '+993': 'TM', // Turkmenistan
      '+994': 'AZ',
      '+995': 'GE',
      '+996': 'KG',
      '+998': 'UZ',
    };

    return dialCodeToISO[dialCode] ?? 'TM'; // Default to Turkmenistan
  }
}
