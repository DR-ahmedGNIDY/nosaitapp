class AppConstants {
  AppConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Timeouts (ms)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Player Code
  static const String playerCodePrefix = 'Y';

  // Evaluation range
  static const int minEvaluationScore = 1;
  static const int maxEvaluationScore = 10;

  // App Info
  static const String appName = 'Basketball Academy Manager';
  static const String appVersion = '1.0.0';
  static const int appBuild = 1;
}
