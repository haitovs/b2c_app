/// URL utility functions for domain and HTTPS handling
class UrlUtil {
  /// Extract domain from URL (removes https://, http://, www.)
  ///
  /// Examples:
  /// - 'https://example.com' → 'example.com'
  /// - 'www.example.com' → 'example.com'
  /// - 'example.com/path' → 'example.com'
  static String extractDomain(String url) {
    String domain = url.trim();

    // Remove protocol
    domain = domain.replaceAll(RegExp(r'^https?://'), '');

    // Remove www.
    domain = domain.replaceAll(RegExp(r'^www\.'), '');

    // Remove trailing slash
    domain = domain.replaceAll(RegExp(r'/$'), '');

    // Remove path (everything after first /)
    if (domain.contains('/')) {
      domain = domain.substring(0, domain.indexOf('/'));
    }

    return domain;
  }

  /// Convert domain to full HTTPS URL
  ///
  /// Example: 'example.com' → 'https://example.com'
  static String toHttpsUrl(String domain) {
    final cleaned = extractDomain(domain);
    return 'https://$cleaned';
  }

  /// Validate domain format
  ///
  /// Returns true if domain is valid (e.g., example.com, sub.example.co.uk)
  static bool isValidDomain(String domain) {
    final cleaned = extractDomain(domain);
    // Basic domain validation: alphanumeric, hyphens, dots
    return RegExp(
      r'^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$',
    ).hasMatch(cleaned);
  }
}
