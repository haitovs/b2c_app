import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/core/utils/url_util.dart';

void main() {
  group('UrlUtil', () {
    group('extractDomain', () {
      test('strips https:// protocol', () {
        expect(UrlUtil.extractDomain('https://example.com'), 'example.com');
      });

      test('strips http:// protocol', () {
        expect(UrlUtil.extractDomain('http://example.com'), 'example.com');
      });

      test('strips www. prefix', () {
        expect(UrlUtil.extractDomain('www.example.com'), 'example.com');
      });

      test('strips both https:// and www.', () {
        expect(
          UrlUtil.extractDomain('https://www.example.com'),
          'example.com',
        );
      });

      test('removes path after domain', () {
        expect(
          UrlUtil.extractDomain('https://example.com/path/to/page'),
          'example.com',
        );
      });

      test('removes trailing slash', () {
        expect(UrlUtil.extractDomain('example.com/'), 'example.com');
      });

      test('returns bare domain unchanged', () {
        expect(UrlUtil.extractDomain('example.com'), 'example.com');
      });

      test('handles subdomain', () {
        expect(
          UrlUtil.extractDomain('https://blog.example.com/post'),
          'blog.example.com',
        );
      });

      test('trims whitespace', () {
        expect(UrlUtil.extractDomain('  example.com  '), 'example.com');
      });
    });

    group('toHttpsUrl', () {
      test('adds https:// to bare domain', () {
        expect(UrlUtil.toHttpsUrl('example.com'), 'https://example.com');
      });

      test('normalizes http:// to https://', () {
        expect(UrlUtil.toHttpsUrl('http://example.com'), 'https://example.com');
      });

      test('keeps https:// domain clean', () {
        expect(
          UrlUtil.toHttpsUrl('https://example.com'),
          'https://example.com',
        );
      });

      test('strips www. and adds https://', () {
        expect(
          UrlUtil.toHttpsUrl('www.example.com'),
          'https://example.com',
        );
      });

      test('strips path and adds https://', () {
        expect(
          UrlUtil.toHttpsUrl('example.com/path'),
          'https://example.com',
        );
      });
    });

    group('isValidDomain', () {
      test('accepts valid simple domains', () {
        expect(UrlUtil.isValidDomain('example.com'), isTrue);
        expect(UrlUtil.isValidDomain('my-site.org'), isTrue);
        expect(UrlUtil.isValidDomain('google.com'), isTrue);
      });

      test('rejects subdomains (regex only matches single-level)', () {
        // The current regex does not support multi-level domains like sub.example.com
        expect(UrlUtil.isValidDomain('sub.example.com'), isFalse);
        expect(UrlUtil.isValidDomain('example.co.uk'), isFalse);
      });

      test('accepts domain with https:// prefix (strips it)', () {
        expect(UrlUtil.isValidDomain('https://example.com'), isTrue);
      });

      test('accepts domain with www. prefix (strips it)', () {
        expect(UrlUtil.isValidDomain('www.example.com'), isTrue);
      });

      test('rejects domain without TLD', () {
        expect(UrlUtil.isValidDomain('localhost'), isFalse);
      });

      test('rejects empty string', () {
        expect(UrlUtil.isValidDomain(''), isFalse);
      });

      test('rejects single character TLD', () {
        expect(UrlUtil.isValidDomain('example.c'), isFalse);
      });

      test('rejects domain starting with hyphen', () {
        expect(UrlUtil.isValidDomain('-example.com'), isFalse);
      });
    });
  });
}
