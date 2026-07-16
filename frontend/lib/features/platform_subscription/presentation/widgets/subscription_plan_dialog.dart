// نافذة اختيار الباقة لتفعيل/تعديل اشتراك الأكاديمية (Super Admin).
//
// تحاكي بصرياً صفحة "اشتراك النظام" التي يراها مدير الأكاديمية:
// بطاقات باقات ملوّنة + ChoiceChips للمدة + خانة تفعيل حسابات اللاعبين +
// ملخّص للطلب. لا تُجري أي استدعاء API — تُرجع فقط اختيار المستخدم عبر
// [SubscriptionPlanResult]، وتتولى الشاشة استدعاء نفس الـ API الحالية.
import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

// ─── نماذج البيانات الثابتة (مطابقة لأسعار صفحة اشتراك النظام) ─────────────────

class _Package {
  final String title; // مثال: "حتى 100 لاعب"
  final int maxPlayers;
  final Color color;
  final List<int> prices; // بترتيب [_durations]: [شهر, 3, 6, سنة]
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

class _Duration {
  final String label;
  final int months;
  const _Duration(this.label, this.months);
}

const _durations = <_Duration>[
  _Duration('شهر', 1),
  _Duration('3 أشهر', 3),
  _Duration('6 أشهر', 6),
  _Duration('سنة', 12),
];

// السعر السنوي لخدمة تفعيل حسابات اللاعبين (كما في صفحة اشتراك النظام).
const int _playerAccountsPrice = 1000;

// خيارات حالة الاشتراك المتاحة في وضع التعديل.
const _statusOptions = <(String, String)>[
  ('active', 'نشط'),
  ('suspended', 'معلّق'),
  ('expired', 'منتهٍ'),
];

int _durationIndexFromMonths(int? months) {
  if (months == null) return 3; // سنة افتراضياً
  final i = _durations.indexWhere((d) => d.months == months);
  return i >= 0 ? i : 3;
}

int? _packageIndexFromMaxPlayers(int? maxPlayers) {
  if (maxPlayers == null) return null;
  final i = _packages.indexWhere((p) => p.maxPlayers == maxPlayers);
  return i >= 0 ? i : null;
}

// ─── نتيجة الاختيار المُعادة إلى الشاشة ────────────────────────────────────────

class SubscriptionPlanResult {
  /// هل اختار المستخدم باقة قياسية (100/200/300)؟ في وضع التعديل قد يكون false
  /// عندما يترك الحد الحالي دون تغيير (مثلاً أكاديمية قديمة بحد غير قياسي).
  final bool packageChosen;
  final int? maxPlayers;
  final int durationMonths; // 1 | 3 | 6 | 12
  final String plan; // 'month' | 'year'
  final bool playerPortalEnabled;

  /// حالة الاشتراك — تُستخدم في وضع التعديل فقط (null عند التفعيل).
  final String? status;

  const SubscriptionPlanResult({
    required this.packageChosen,
    required this.maxPlayers,
    required this.durationMonths,
    required this.plan,
    required this.playerPortalEnabled,
    this.status,
  });
}

/// يعرض نافذة اختيار الباقة. يُرجع [SubscriptionPlanResult] عند الضغط على زر
/// التأكيد، أو null عند الإلغاء.
///
/// [editMode] = true لعرض عناصر التعديل (حالة الاشتراك) وزر "حفظ التعديلات".
Future<SubscriptionPlanResult?> showSubscriptionPlanDialog(
  BuildContext context, {
  required String academyName,
  bool editMode = false,
  int? currentMaxPlayers,
  int? currentDurationMonths,
  bool currentPortalEnabled = false,
  String currentStatus = 'active',
}) {
  return showDialog<SubscriptionPlanResult>(
    context: context,
    builder: (_) => _SubscriptionPlanDialog(
      academyName: academyName,
      editMode: editMode,
      currentMaxPlayers: currentMaxPlayers,
      currentDurationMonths: currentDurationMonths,
      currentPortalEnabled: currentPortalEnabled,
      currentStatus: currentStatus,
    ),
  );
}

class _SubscriptionPlanDialog extends StatefulWidget {
  final String academyName;
  final bool editMode;
  final int? currentMaxPlayers;
  final int? currentDurationMonths;
  final bool currentPortalEnabled;
  final String currentStatus;

  const _SubscriptionPlanDialog({
    required this.academyName,
    required this.editMode,
    required this.currentMaxPlayers,
    required this.currentDurationMonths,
    required this.currentPortalEnabled,
    required this.currentStatus,
  });

  @override
  State<_SubscriptionPlanDialog> createState() => _SubscriptionPlanDialogState();
}

class _SubscriptionPlanDialogState extends State<_SubscriptionPlanDialog> {
  late int? _selectedPkg;
  late int _selectedDur;
  late bool _portal;
  late String _status;

  @override
  void initState() {
    super.initState();
    // في التفعيل: باقة 200 افتراضياً. في التعديل: الباقة الحالية إن كانت قياسية.
    _selectedPkg = widget.editMode
        ? _packageIndexFromMaxPlayers(widget.currentMaxPlayers)
        : (_packageIndexFromMaxPlayers(widget.currentMaxPlayers) ?? 1);
    _selectedDur = _durationIndexFromMonths(widget.currentDurationMonths);
    _portal = widget.currentPortalEnabled;
    _status = _statusOptions.any((s) => s.$1 == widget.currentStatus)
        ? widget.currentStatus
        : 'active';
  }

  _Package? get _pkg => _selectedPkg != null ? _packages[_selectedPkg!] : null;

  int get _basePrice => _pkg?.prices[_selectedDur] ?? 0;
  int get _addonPrice => _portal ? _playerAccountsPrice : 0;
  int get _total => _basePrice + _addonPrice;

  void _confirm() {
    final chosen = _selectedPkg != null;
    Navigator.pop(
      context,
      SubscriptionPlanResult(
        packageChosen: chosen,
        maxPlayers: _pkg?.maxPlayers ?? widget.currentMaxPlayers,
        durationMonths: _durations[_selectedDur].months,
        plan: _durations[_selectedDur].months == 12 ? 'year' : 'month',
        playerPortalEnabled: _portal,
        status: widget.editMode ? _status : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _pkg?.color ?? AppColors.primary;
    // في التفعيل يجب اختيار باقة؛ في التعديل يُسمح بالحفظ دون تغيير الباقة.
    final canConfirm = widget.editMode || _selectedPkg != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(accent),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.editMode) ...[
                      _statusSelector(),
                      const SizedBox(height: 16),
                    ],
                    const _MiniTitle(
                        icon: Icons.workspace_premium_outlined, title: 'اختر الباقة'),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _packages.length; i++) ...[
                      _PackageCard(
                        package: _packages[i],
                        selected: _selectedPkg == i,
                        durationIndex: _selectedDur,
                        onSelect: () => setState(() => _selectedPkg = i),
                        onDuration: (d) => setState(() => _selectedDur = d),
                      ),
                      if (i != _packages.length - 1) const SizedBox(height: 12),
                    ],
                    if (widget.editMode && _selectedPkg == null) ...[
                      const SizedBox(height: 12),
                      _legacyHint(),
                    ],
                    const SizedBox(height: 16),
                    _portalCheckbox(accent),
                    const SizedBox(height: 16),
                    _summary(accent),
                  ],
                ),
              ),
            ),
            _actions(accent, canConfirm),
          ],
        ),
      ),
    );
  }

  Widget _header(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.editMode ? Icons.edit_outlined : Icons.workspace_premium_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.editMode ? 'تعديل الاشتراك' : 'تفعيل اشتراك',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.academyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MiniTitle(icon: Icons.tune_outlined, title: 'حالة الاشتراك'),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: [
            for (final s in _statusOptions)
              ButtonSegment(value: s.$1, label: Text(s.$2)),
          ],
          selected: {_status},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _status = s.first),
        ),
      ],
    );
  }

  Widget _legacyHint() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الحد الحالي: ${widget.currentMaxPlayers ?? '-'} لاعب (غير قياسي). '
              'لن يتغيّر إلا إذا اخترت باقة من الأعلى.',
              style: const TextStyle(fontSize: 12, color: AppColors.grey700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _portalCheckbox(Color accent) {
    return InkWell(
      onTap: () => setState(() => _portal = !_portal),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _portal ? accent : AppColors.grey200),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _portal,
              activeColor: accent,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => setState(() => _portal = v ?? false),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'تفعيل حسابات اللاعبين (+1000 جنيه/سنة)',
                style: TextStyle(fontSize: 13, color: AppColors.grey800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(Color accent) {
    final maxPlayers = _pkg?.maxPlayers ?? widget.currentMaxPlayers;
    final pkgLabel = _pkg != null
        ? 'حتى ${_pkg!.maxPlayers} لاعب'
        : (maxPlayers != null ? 'حتى $maxPlayers لاعب' : 'لم تُحدَّد');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('ملخّص الطلب',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow('الباقة المختارة', pkgLabel),
          _summaryRow('المدة', _durations[_selectedDur].label),
          if (_pkg != null) _summaryRow('السعر الأساسي', '$_basePrice جنيه'),
          if (_portal) _summaryRow('تفعيل حسابات اللاعبين', '$_playerAccountsPrice جنيه'),
          if (_pkg != null) ...[
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                Text('$_total جنيه',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, color: accent)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey700)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900)),
        ],
      ),
    );
  }

  Widget _actions(Color accent, bool canConfirm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: canConfirm ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  widget.editMode ? 'حفظ التعديلات' : 'تفعيل الاشتراك',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── بطاقة الباقة (قابلة للاختيار) ────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final _Package package;
  final bool selected;
  final int durationIndex;
  final VoidCallback onSelect;
  final ValueChanged<int> onDuration;

  const _PackageCard({
    required this.package,
    required this.selected,
    required this.durationIndex,
    required this.onSelect,
    required this.onDuration,
  });

  @override
  Widget build(BuildContext context) {
    final price = package.prices[durationIndex];
    final duration = _durations[durationIndex];
    final minPrice =
        package.prices.reduce((a, b) => a < b ? a : b);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? package.color.withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? package.color : AppColors.grey200,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: package.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_outlined, color: package.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    package.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: package.color),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? package.color : AppColors.grey400,
                  size: 22,
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _durations.length; i++)
                    ChoiceChip(
                      label: Text(_durations[i].label),
                      selected: durationIndex == i,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: durationIndex == i ? AppColors.white : AppColors.grey700,
                      ),
                      selectedColor: package.color,
                      backgroundColor: AppColors.grey100,
                      side: BorderSide(
                        color: durationIndex == i ? package.color : AppColors.grey200,
                      ),
                      onSelected: (_) => onDuration(i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$price',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: package.color,
                        height: 1),
                  ),
                  const SizedBox(width: 6),
                  const Text('جنيه',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey600)),
                  const SizedBox(width: 4),
                  Text('/ ${duration.label}',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text('من $minPrice جنيه',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── عنوان صغير للأقسام داخل النافذة ──────────────────────────────────────────

class _MiniTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _MiniTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.grey900)),
      ],
    );
  }
}
