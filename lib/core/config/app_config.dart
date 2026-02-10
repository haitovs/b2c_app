/// App configuration constants loaded from environment
class AppConfig {
  // Tourism Backend URL
  static const String tourismApiBaseUrl = String.fromEnvironment(
    'TOURISM_API_URL',
    defaultValue: 'https://api.turkmenchina.com',
  );

  // B2C Backend URL
  static const String b2cApiBaseUrl = String.fromEnvironment(
    'B2C_API_URL',
    defaultValue: 'https://b2c.oguzforum.com',
  );
}
