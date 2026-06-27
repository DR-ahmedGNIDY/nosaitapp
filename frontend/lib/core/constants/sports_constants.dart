/// Default suggested sports and the weekly attendance days.
///
/// Sports are an open list — academies may store any sport string, these are
/// only the defaults offered in the multi-select. New sports can be added
/// without changing the backend (the `sports` field is a free string array).
class SportsConstants {
  SportsConstants._();

  static const List<String> defaultSports = [
    'كرة قدم',
    'كرة سلة',
    'كرة طائرة',
    'كرة يد',
    'سباحة',
    'كاراتيه',
  ];

  /// Weekly attendance days (Saturday-first, matching the local week).
  static const List<String> weekDays = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
}
