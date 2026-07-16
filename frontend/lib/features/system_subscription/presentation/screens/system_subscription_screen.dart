// صفحة "اشتراك النظام" لمدير الأكاديمية — صفحة تسويقية/أسعار (Frontend فقط).
// لا تستدعي أي Backend ولا تنشئ أي API. جميع الأزرار تفتح واتساب الدعم برسالة
// جاهزة باستخدام رقم الدعم الموجود مسبقاً (AppConstants.companyWhatsappNumber).
import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_constants.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── نماذج بيانات ثابتة (Frontend only) ───────────────────────────────────────

class _Duration {
  final String label; // نص المدة كما يظهر في رسالة الواتساب والواجهة
  final int months;
  const _Duration(this.label, this.months);
}

const _durations = <_Duration>[
  _Duration('شهر واحد', 1),
  _Duration('3 أشهر', 3),
  _Duration('6 أشهر', 6),
  _Duration('سنة كاملة', 12),
];

class _Package {
  final String title; // مثال: "حتى 100 لاعب"
  final int maxPlayers;
  final Color color;
  final List<int> prices; // بترتيب _durations: [شهر, 3, 6, سنة]
  const _Package({
    required this.title,
    required this.maxPlayers,
    required this.color,
    required this.prices,
  });
}

const _packages = <_Package>[
  _Package(
    title: 'حتى 100 لاعب',
    maxPlayers: 100,
    color: Color(0xFF2D9748), // أخضر
    prices: [250, 600, 950, 1700],
  ),
  _Package(
    title: 'حتى 200 لاعب',
    maxPlayers: 200,
    color: Color(0xFF2563EB), // أزرق
    prices: [300, 800, 1300, 2500],
  ),
  _Package(
    title: 'حتى 300 لاعب',
    maxPlayers: 300,
    color: Color(0xFF7C3AED), // بنفسجي
    prices: [400, 1100, 2200, 3200],
  ),
];

// السعر السنوي لخدمة تفعيل حسابات اللاعبين.
const int _playerAccountsPrice = 1000;
// سعر شراء التطبيق الخاص بالأكاديمية.
const int _appPurchasePrice = 9500;

// المميزات المعروضة في قسم "لماذا تشترك؟".
const _features = <(IconData, String)>[
  (Icons.sports_basketball_outlined, 'إدارة اللاعبين'),
  (Icons.badge_outlined, 'إدارة المدربين والإداريين'),
  (Icons.card_membership_outlined, 'الاشتراكات والمدفوعات'),
  (Icons.qr_code_scanner, 'QR للحضور'),
  (Icons.smartphone_outlined, 'تطبيق اللاعب'),
  (Icons.bar_chart_outlined, 'تقارير وإحصائيات'),
  (Icons.backup_outlined, 'النسخ الاحتياطي'),
  (Icons.support_agent_outlined, 'الدعم الفني'),
  (Icons.system_update_alt_outlined, 'التحديثات المجانية'),
  (Icons.verified_user_outlined, 'الأمان الكامل'),
];

const _notes = <String>[
  'جميع الأسعار بالجنيه المصري.',
  'يتم التفعيل بعد التواصل مع الدعم.',
  'يمكن ترقية الباقة في أي وقت.',
  'عند تجاوز الحد الأقصى للاعبين يمكن الترقية للباقة التالية.',
  'خدمة حسابات اللاعبين اختيارية ويمكن إضافتها مع أي باقة.',
  'التطبيق الخاص بالأكاديمية يُسلَّم باسم وشعار الأكاديمية ويشمل إمكانية إضافة أي تطويرات مستقبلية حسب الاتفاق.',
];

// ─── الشاشة ────────────────────────────────────────────────────────────────────

class SystemSubscriptionScreen extends ConsumerWidget {
  const SystemSubscriptionScreen({super.key});

  String _academyName(WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final byId = (user?.academyId != null)
        ? ref.watch(academyByIdProvider(user!.academyId!)).valueOrNull?.name
        : null;
    return (byId != null && byId.isNotEmpty)
        ? byId
        : (user?.academyName?.isNotEmpty == true
            ? user!.academyName!
            : 'أكاديميتي');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyName = _academyName(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        title: const Text('اشتراك النظام'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth =
              constraints.maxWidth > 1100 ? 1100.0 : constraints.maxWidth;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      const SizedBox(height: 24),
                      _PackagesSection(academyName: academyName),
                      const SizedBox(height: 32),
                      _AdditionalServicesSection(academyName: academyName),
                      const SizedBox(height: 32),
                      const _FeaturesSection(),
                      const SizedBox(height: 32),
                      const _NotesSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── واتساب ────────────────────────────────────────────────────────────────────

Future<void> _openWhatsApp(BuildContext context, String message) async {
  final ok = await WhatsAppUtils.open(
    AppConstants.companyWhatsappNumber,
    message: message,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر فتح واتساب. حاول مرة أخرى.')),
    );
  }
}

// ─── الهيدر ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.secondary, Color(0xFF2D3F63)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'اشتراك النظام',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'اختر الباقة المناسبة لأكاديميتك واستمتع بجميع مميزات منصة Nosait.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── قسم الباقات ───────────────────────────────────────────────────────────────

class _PackagesSection extends StatelessWidget {
  final String academyName;
  const _PackagesSection({required this.academyName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.workspace_premium_outlined, title: 'الباقات'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _packages.length; i++) ...[
                    Expanded(
                      child: _PackageCard(
                        package: _packages[i],
                        academyName: academyName,
                        highlighted: i == 1,
                      ),
                    ),
                    if (i != _packages.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < _packages.length; i++) ...[
                  _PackageCard(
                    package: _packages[i],
                    academyName: academyName,
                    highlighted: i == 1,
                  ),
                  if (i != _packages.length - 1) const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PackageCard extends StatefulWidget {
  final _Package package;
  final String academyName;
  final bool highlighted;

  const _PackageCard({
    required this.package,
    required this.academyName,
    required this.highlighted,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  int _selected = 3; // افتراضياً السنة الكاملة (الأفضل)
  bool _addPlayerAccounts = false;

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final price = pkg.prices[_selected];
    final duration = _durations[_selected];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.highlighted
              ? pkg.color
              : AppColors.grey200,
          width: widget.highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس البطاقة الملون
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: pkg.color.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: pkg.color.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.groups_outlined,
                          color: pkg.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pkg.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: pkg.color,
                        ),
                      ),
                    ),
                    if (widget.highlighted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pkg.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'الأكثر شيوعاً',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // اختيار المدة عبر ChoiceChips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _durations.length; i++)
                      ChoiceChip(
                        label: Text(_durations[i].label),
                        selected: _selected == i,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selected == i
                              ? AppColors.white
                              : AppColors.grey700,
                        ),
                        selectedColor: pkg.color,
                        backgroundColor: AppColors.grey100,
                        side: BorderSide(
                          color: _selected == i ? pkg.color : AppColors.grey200,
                        ),
                        onSelected: (_) => setState(() => _selected = i),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                // السعر
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$price',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: pkg.color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'جنيه',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${duration.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // خيار إضافة حسابات اللاعبين
                InkWell(
                  onTap: () => setState(
                      () => _addPlayerAccounts = !_addPlayerAccounts),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _addPlayerAccounts,
                          activeColor: pkg.color,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) => setState(
                              () => _addPlayerAccounts = v ?? false),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'إضافة تفعيل حسابات اللاعبين (+1000 جنيه/سنة)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // زر الاشتراك
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(
                      context,
                      _subscribeMessage(
                        academyName: widget.academyName,
                        packageTitle: pkg.title,
                        duration: duration.label,
                        price: price,
                        addPlayerAccounts: _addPlayerAccounts,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pkg.color,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      'اشترك الآن',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── الخدمات الإضافية ──────────────────────────────────────────────────────────

class _AdditionalServicesSection extends StatelessWidget {
  final String academyName;
  const _AdditionalServicesSection({required this.academyName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.add_business_outlined, title: 'خدمات إضافية'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            final cards = [
              _ServiceCard(
                icon: Icons.manage_accounts_outlined,
                color: const Color(0xFF2D9748),
                title: 'تفعيل حسابات اللاعبين',
                price: '1000 جنيه سنوياً',
                description:
                    'تفعيل إمكانية دخول اللاعبين وأولياء الأمور إلى تطبيق Nosait '
                    'باستخدام اسم المستخدم وكلمة المرور، مع الاستفادة من لوحة اللاعب، '
                    'الحضور، التقييمات، الإشعارات، وجدول التدريب.',
                note: 'يمكن إضافة هذه الخدمة مع أي باقة من الباقات السابقة.',
                buttonLabel: 'اطلب الخدمة',
                onPressed: () => _openWhatsApp(
                  context,
                  _playerAccountsMessage(academyName),
                ),
              ),
              _ServiceCard(
                icon: Icons.smartphone_outlined,
                color: const Color(0xFFE85D04),
                title: 'شراء تطبيق الأكاديمية',
                price: '9500 جنيه',
                badge: 'مدى الحياة',
                description:
                    'تطبيق Android و iOS ونسخة ويب ونسخة Windows باسم وشعار '
                    'الأكاديمية الخاصة بك، مع إمكانية إضافة أي مميزات مستقبلية '
                    'حسب احتياجات الأكاديمية.',
                buttonLabel: 'اطلب التطبيق',
                onPressed: () => _openWhatsApp(
                  context,
                  _appPurchaseMessage(academyName),
                ),
              ),
            ];
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              );
            }
            return Column(
              children: [
                cards[0],
                const SizedBox(height: 16),
                cards[1],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String price;
  final String description;
  final String? note;
  final String? badge;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ServiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.price,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.note,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.grey700,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: Text(
                buttonLabel,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── لماذا تشترك؟ ──────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
            icon: Icons.verified_outlined, title: 'لماذا تشترك؟'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width >= 820 ? 3 : (width >= 520 ? 2 : 1);
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 4.2,
              children: [
                for (final f in _features) _FeatureTile(icon: f.$1, label: f.$2),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 16),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── الملاحظات ─────────────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  const _NotesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_outlined, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'ملاحظات هامة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final note in _notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle,
                        size: 16, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── عنوان قسم ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.grey900,
          ),
        ),
      ],
    );
  }
}

// ─── قوالب رسائل واتساب ────────────────────────────────────────────────────────

String _subscribeMessage({
  required String academyName,
  required String packageTitle,
  required String duration,
  required int price,
  required bool addPlayerAccounts,
}) {
  final services = addPlayerAccounts
      ? '✔ تفعيل حسابات اللاعبين ($_playerAccountsPrice جنيه سنوياً)'
      : 'لا يوجد';
  return 'السلام عليكم\n\n'
      'أرغب في الاشتراك في منصة Nosait.\n\n'
      'اسم الأكاديمية:\n$academyName\n\n'
      'الباقة:\n$packageTitle\n\n'
      'المدة:\n$duration\n\n'
      'السعر:\n$price جنيه\n\n'
      'الخدمات الإضافية المختارة:\n$services\n\n'
      'أرجو التواصل معي لإتمام الاشتراك.';
}

String _playerAccountsMessage(String academyName) {
  return 'السلام عليكم\n\n'
      'أرغب في تفعيل حسابات اللاعبين على منصة Nosait.\n\n'
      'اسم الأكاديمية:\n$academyName\n\n'
      'الخدمة المطلوبة:\nتفعيل حسابات اللاعبين وأولياء الأمور\n\n'
      'السعر:\n$_playerAccountsPrice جنيه سنوياً\n\n'
      'ملاحظة:\nهذه الخدمة إضافة على الباقة الحالية.\n\n'
      'أرجو التواصل معي.';
}

String _appPurchaseMessage(String academyName) {
  return 'السلام عليكم\n\n'
      'أرغب في شراء التطبيق الخاص بالأكاديمية.\n\n'
      'اسم الأكاديمية:\n$academyName\n\n'
      'الخدمة المطلوبة:\nشراء تطبيق خاص بالأكاديمية\n\n'
      'السعر:\n$_appPurchasePrice جنيه\n\n'
      'أرجو التواصل معي.';
}
