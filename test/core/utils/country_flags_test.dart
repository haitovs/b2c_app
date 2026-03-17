import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/core/utils/country_flags.dart';

void main() {
  group('countryNameToFlag', () {
    test('returns correct flag for Turkmenistan', () {
      // TM -> regional indicator T (0x1F1F9) + M (0x1F1F2)
      final flag = countryNameToFlag('Turkmenistan');
      expect(flag, isNotEmpty);
      expect(flag.runes.length, 2);
    });

    test('returns correct flag for United States', () {
      final flag = countryNameToFlag('United States');
      expect(flag, isNotEmpty);
      expect(flag.runes.length, 2);
    });

    test('returns correct flag for Turkey', () {
      final flag = countryNameToFlag('Turkey');
      expect(flag, isNotEmpty);
    });

    test('is case insensitive', () {
      expect(countryNameToFlag('turkmenistan'), countryNameToFlag('Turkmenistan'));
      expect(countryNameToFlag('TURKEY'), countryNameToFlag('turkey'));
      expect(countryNameToFlag('United States'), countryNameToFlag('united states'));
    });

    test('returns empty string for unknown country', () {
      expect(countryNameToFlag('Atlantis'), '');
      expect(countryNameToFlag('Narnia'), '');
    });

    test('returns empty string for null', () {
      expect(countryNameToFlag(null), '');
    });

    test('returns empty string for empty string', () {
      expect(countryNameToFlag(''), '');
    });

    test('handles alternate country names', () {
      // USA variants
      expect(countryNameToFlag('usa'), countryNameToFlag('united states'));
      expect(countryNameToFlag('united states of america'),
          countryNameToFlag('united states'));

      // UK variants
      expect(countryNameToFlag('uk'), countryNameToFlag('united kingdom'));

      // UAE
      expect(
          countryNameToFlag('uae'), countryNameToFlag('united arab emirates'));
    });

    test('handles countries with alternate spellings', () {
      // Czech Republic vs Czechia
      expect(countryNameToFlag('czech republic'), countryNameToFlag('czechia'));

      // Cabo Verde vs Cape Verde
      expect(countryNameToFlag('cabo verde'), countryNameToFlag('cape verde'));

      // Eswatini vs Swaziland
      expect(countryNameToFlag('eswatini'), countryNameToFlag('swaziland'));

      // Myanmar vs Burma
      expect(countryNameToFlag('myanmar'), countryNameToFlag('burma'));
    });

    test('all known countries return non-empty flags', () {
      final knownCountries = [
        'Afghanistan', 'Brazil', 'Canada', 'Denmark', 'Egypt',
        'France', 'Germany', 'Hungary', 'India', 'Japan',
        'Kenya', 'Lebanon', 'Mexico', 'Nigeria', 'Oman',
        'Pakistan', 'Qatar', 'Russia', 'Spain', 'Turkey',
        'Uzbekistan', 'Venezuela', 'Yemen', 'Zambia', 'Zimbabwe',
      ];

      for (final country in knownCountries) {
        expect(
          countryNameToFlag(country),
          isNotEmpty,
          reason: '$country should have a flag',
        );
      }
    });
  });
}
