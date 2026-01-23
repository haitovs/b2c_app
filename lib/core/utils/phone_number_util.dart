/// Phone Number Utility
/// Handles conversion between E.164 format and display format
class PhoneNumberUtil {
  /// Combine country dial code and local number to E.164 format
  ///
  /// Example:
  /// ```dart
  /// toE164('+993', '62436999') // Returns: '+99362436999'
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
  /// fromE164('+99362436999')
  /// // Returns: {'dialCode': '+993', 'localNumber': '62436999'}
  /// ```
  static Map<String, String> fromE164(String e164Phone) {
    if (!e164Phone.startsWith('+')) {
      // Not in E.164 format, return as-is with default dial code
      return {'dialCode': '+993', 'localNumber': e164Phone};
    }

    // Extract dial code by trying different lengths (1-4 digits)
    // Common dial codes: +1 (USA), +44 (UK), +993 (TM), +7 (RU)
    for (int len = 1; len <= 4; len++) {
      if (e164Phone.length > len + 1) {
        final code = e164Phone.substring(0, len + 1); // Include the '+'
        final local = e164Phone.substring(len + 1);

        // Return if we have a reasonable split
        if (local.isNotEmpty) {
          return {'dialCode': code, 'localNumber': local};
        }
      }
    }

    // Fallback: assume first 4 characters are dial code (+XXX)
    if (e164Phone.length > 4) {
      return {
        'dialCode': e164Phone.substring(0, 4),
        'localNumber': e164Phone.substring(4),
      };
    }

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
