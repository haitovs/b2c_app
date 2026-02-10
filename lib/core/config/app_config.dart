/// App configuration constants loaded from environment
class AppConfig {
  // Tourism Backend URL (main tourism site)
  static const String tourismApiBaseUrl = String.fromEnvironment(
    'TOURISM_API_URL',
    defaultValue: 'https://api.turkmenchina.com', // Your working config
  );

  // B2C Backend URL (registration/booking system)
  static const String b2cApiBaseUrl = String.fromEnvironment(
    'B2C_API_URL',
    defaultValue: 'https://b2c.oguzforum.com',
  );
}
