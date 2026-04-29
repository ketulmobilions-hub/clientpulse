abstract final class AppConstants {
  // Override at build time: --dart-define=API_BASE_URL=https://api.example.com/api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static const appBaseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'http://localhost:3001',
  );
}
