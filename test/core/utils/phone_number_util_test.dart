import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/core/utils/phone_number_util.dart';

void main() {
  group('PhoneNumberUtil', () {
    group('toE164', () {
      test('combines dial code and local number', () {
        expect(PhoneNumberUtil.toE164('+993', '61444555'), '+99361444555');
      });

      test('adds + prefix if missing from dial code', () {
        expect(PhoneNumberUtil.toE164('993', '61444555'), '+99361444555');
      });

      test('strips non-digit characters from local number', () {
        expect(
          PhoneNumberUtil.toE164('+1', '(212) 555-1234'),
          '+12125551234',
        );
      });

      test('handles dashes and spaces in local number', () {
        expect(PhoneNumberUtil.toE164('+44', '20-7946 0958'), '+442079460958');
      });

      test('handles empty local number', () {
        expect(PhoneNumberUtil.toE164('+993', ''), '+993');
      });

      test('handles local number with only non-digit chars', () {
        expect(PhoneNumberUtil.toE164('+1', '---'), '+1');
      });
    });

    group('fromE164', () {
      test('parses Turkmenistan number correctly', () {
        final result = PhoneNumberUtil.fromE164('+99361444555');
        expect(result['dialCode'], '+993');
        expect(result['localNumber'], '61444555');
      });

      test('parses US number correctly', () {
        final result = PhoneNumberUtil.fromE164('+12125551234');
        expect(result['dialCode'], '+1');
        expect(result['localNumber'], '2125551234');
      });

      test('parses UK number correctly', () {
        final result = PhoneNumberUtil.fromE164('+442079460958');
        expect(result['dialCode'], '+44');
        expect(result['localNumber'], '2079460958');
      });

      test('parses Turkey number correctly', () {
        final result = PhoneNumberUtil.fromE164('+905321234567');
        expect(result['dialCode'], '+90');
        expect(result['localNumber'], '5321234567');
      });

      test('defaults to +993 for non-E164 input (no + prefix)', () {
        final result = PhoneNumberUtil.fromE164('61444555');
        expect(result['dialCode'], '+993');
        expect(result['localNumber'], '61444555');
      });

      test('parses Uzbekistan number correctly', () {
        final result = PhoneNumberUtil.fromE164('+998901234567');
        expect(result['dialCode'], '+998');
        expect(result['localNumber'], '901234567');
      });

      test('parses Russia number correctly', () {
        final result = PhoneNumberUtil.fromE164('+79161234567');
        expect(result['dialCode'], '+7');
        expect(result['localNumber'], '9161234567');
      });
    });

    group('isValidE164', () {
      test('accepts valid E.164 numbers', () {
        expect(PhoneNumberUtil.isValidE164('+99361444555'), isTrue);
        expect(PhoneNumberUtil.isValidE164('+12125551234'), isTrue);
        expect(PhoneNumberUtil.isValidE164('+442079460958'), isTrue);
      });

      test('rejects number without + prefix', () {
        expect(PhoneNumberUtil.isValidE164('99361444555'), isFalse);
      });

      test('rejects empty string', () {
        expect(PhoneNumberUtil.isValidE164(''), isFalse);
      });

      test('rejects + alone', () {
        expect(PhoneNumberUtil.isValidE164('+'), isFalse);
      });

      test('rejects number starting with +0', () {
        expect(PhoneNumberUtil.isValidE164('+0123456789'), isFalse);
      });

      test('rejects number with letters', () {
        expect(PhoneNumberUtil.isValidE164('+1abc'), isFalse);
      });

      test('rejects number too long (>15 digits after +)', () {
        expect(PhoneNumberUtil.isValidE164('+1234567890123456'), isFalse);
      });

      test('accepts minimum length (2 digits)', () {
        expect(PhoneNumberUtil.isValidE164('+12'), isTrue);
      });
    });

    group('getCountryISO', () {
      test('returns correct ISO for known dial codes', () {
        expect(PhoneNumberUtil.getCountryISO('+993'), 'TM');
        expect(PhoneNumberUtil.getCountryISO('+1'), 'US');
        expect(PhoneNumberUtil.getCountryISO('+44'), 'GB');
        expect(PhoneNumberUtil.getCountryISO('+90'), 'TR');
        expect(PhoneNumberUtil.getCountryISO('+998'), 'UZ');
      });

      test('defaults to TM for unknown dial codes', () {
        expect(PhoneNumberUtil.getCountryISO('+999'), 'TM');
        expect(PhoneNumberUtil.getCountryISO('+000'), 'TM');
      });
    });
  });
}
