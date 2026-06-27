class AppConstants {
  AppConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.nosait.com/api/v1',
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

  // Privacy Policy — official link opened in the device's default browser.
  // Change this value to update the link without touching any other code.
  static const String privacyPolicyUrl = 'https://nosait.com/privacy';

  // Company contact (WhatsApp) for "create account / inquiry".
  static const String companyWhatsappNumber = '+201554579942';
  static const String contactDefaultMessage =
      'مرحباً\n\n'
      'أرغب في إنشاء حساب جديد أو الاستفسار عن نظام إدارة الأكاديميات الرياضية.\n\n'
      'الاسم:\n'
      '....................\n\n'
      'رقم الهاتف:\n'
      '....................';
}
