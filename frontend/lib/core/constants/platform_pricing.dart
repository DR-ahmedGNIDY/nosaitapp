// أسعار اشتراك منصة Nosait — مصدر واحد تستخدمه صفحة "اشتراك النظام" (مدير
// الأكاديمية) ونافذة التفعيل (Super Admin) حتى لا تختلف الأرقام بينهما.
//
// القاعدة:
//  - أكاديمية مصرية (عملتها EGP): الأسعار بالجنيه كما هي.
//  - أي دولة أخرى: ضعف سعر الجنيه، محوَّلاً إلى دولار بسعر [usdRate]،
//    ومقرَّباً لأقرب دولار. مثال: 250 جنيه × 2 = 500 ÷ 54 ≈ $9.
// دولة الأكاديمية تُعرف من عملتها (تُشتق من الدولة عند التسجيل).

/// سعر الدولار بالجنيه المستخدم في التحويل. غيّره هنا فقط عند تغيّر السعر.
const double usdRate = 54;

/// معامل أسعار غير المصريين قبل التحويل للدولار.
const int internationalMultiplier = 2;

/// أسعار الباقات بالجنيه حسب الحد الأقصى للاعبين، بترتيب المدد:
/// [شهر، 3 أشهر، 6 أشهر، سنة].
const Map<int, List<int>> packagePricesEgp = {
  100: [250, 600, 950, 1700],
  200: [300, 800, 1300, 2500],
  300: [400, 1100, 2200, 3200],
};

/// تفعيل حسابات اللاعبين — سنوياً بالجنيه.
const int playerAccountsPriceEgp = 1000;

/// شراء تطبيق خاص بالأكاديمية — مدى الحياة بالجنيه.
const int appPurchasePriceEgp = 9500;

/// تسعير حسب دولة الأكاديمية.
class PlatformPricing {
  /// true = أسعار مصر بالجنيه، false = أسعار دولية بالدولار.
  final bool isEgypt;

  const PlatformPricing._(this.isEgypt);

  /// [currency] كود عملة الأكاديمية (مثل EGP / SAR). عند غيابه نفترض مصر
  /// (الافتراضي في التسجيل) حتى لا يرى أحد سعراً دولياً بالخطأ.
  factory PlatformPricing.forCurrency(String? currency) {
    final c = (currency ?? '').trim().toUpperCase();
    return PlatformPricing._(c.isEmpty || c == 'EGP');
  }

  /// السعر المعروض لسعر أساسي بالجنيه.
  int price(int egp) =>
      isEgypt ? egp : (egp * internationalMultiplier / usdRate).round();

  /// الوحدة بجانب الرقم الكبير في البطاقات: "جنيه" أو "$".
  String get unitShort => isEgypt ? 'جنيه' : r'$';

  /// نص كامل للسعر: "250 جنيه" أو "$9".
  String format(int egp) => isEgypt ? '${price(egp)} جنيه' : '\$${price(egp)}';

  /// إجمالي عدة بنود: مجموع الأسعار المعروضة (كلٌّ مقرَّب) حتى يطابق الإجمالي
  /// البنود التي يراها المستخدم.
  String formatSum(List<int> egpItems) {
    final total = egpItems.fold<int>(0, (s, e) => s + price(e));
    return isEgypt ? '$total جنيه' : '\$$total';
  }

  /// سطر الملاحظات أسفل صفحة الأسعار.
  String get currencyNote => isEgypt
      ? 'جميع الأسعار بالجنيه المصري.'
      : 'جميع الأسعار بالدولار الأمريكي (USD).';
}
