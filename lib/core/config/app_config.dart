/// App configuration constants loaded from environment
class AppConfig {
  // Tourism Backend URL (main tourism site)
  static const String tourismApiBaseUrl = String.fromEnvironment(
    'TOURISM_API_URL',
    defaultValue: 'https://api.turkmenchina.com', // Your working config
  );

  // B2C Backend URL (registration/booking system)
  // Dev default: localhost:8010 (redesign branch); override with --dart-define for prod
  static const String b2cApiBaseUrl = String.fromEnvironment(
    'B2C_API_URL',
    defaultValue: 'http://localhost:8010',
  );
}
