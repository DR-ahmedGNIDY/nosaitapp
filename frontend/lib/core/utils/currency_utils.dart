/// Maps an academy currency code to its Arabic label.
///
/// Stored on the academy as one of: EGP, SAR, KWD, USD.
/// Falls back to the Egyptian pound for unknown / legacy values.
class CurrencyUtils {
  CurrencyUtils._();

  static const String defaultCode = 'EGP';

  static const Map<String, String> _labels = {
    'EGP': 'جنيه',
    'SAR': 'ريال',
    'KWD': 'دينار',
    'USD': 'دولار',
  };

  /// Supported currency codes (used to build dropdowns).
  static const List<String> codes = ['EGP', 'SAR', 'KWD', 'USD'];

  /// Arabic label for a currency code, e.g. 'EGP' → 'جنيه'.
  static String label(String? code) {
    if (code == null) return _labels[defaultCode]!;
    return _labels[code] ?? _labels[defaultCode]!;
  }

  /// Label including the code for selectors, e.g. 'جنيه (EGP)'.
  static String labelWithCode(String code) => '${label(code)} ($code)';
}
