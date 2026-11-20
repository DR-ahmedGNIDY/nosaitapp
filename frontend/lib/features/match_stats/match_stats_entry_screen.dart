import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/match_stats/match_stats_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// تسجيل نتيجة المباراة وإحصائيات كل لاعب حسب قالب رياضة المباراة.
/// الألعاب الجماعية: أرقام (نقاط/أهداف...)؛ الفردية: نسب % موحدة + النتيجة.
/// [canEdit] = false ⇒ عرض فقط.
class MatchStatsEntryScreen extends StatefulWidget {
  final String matchId;
  final bool canEdit;
  const MatchStatsEntryScreen({super.key, required this.matchId, this.canEdit = true});

  @override
  State<MatchStatsEntryScreen> createState() => _MatchStatsEntryScreenState();
}

class _MatchStatsEntryScreenState extends State<MatchStatsEntryScreen> {
  MatchStatsData? _data;
  Object? _error;
  bool _saving = false;
  bool _dirty = false;

  final _opponent = TextEditingController();
  final _ours = TextEditingController();
  final _theirs = TextEditingController();
  final Map<String, Map<String, dynamic>> _stats = {};
  final Map<String, double?> _rating = {};
  final Map<String, TextEditingController> _ctrls = {};
  String? _mvpId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _opponent.dispose();
    _ours.dispose();
    _theirs.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _data = null;
    });
    try {
      _apply(await MatchStatsApi.match(widget.matchId));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _apply(MatchStatsData d) {
    if (!mounted) return;
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _ctrls.clear();
    _stats.clear();
    _rating.clear();
    _mvpId = null;
    _opponent.text = d.opponent;
    _ours.text = d.ourScore?.toString() ?? '';
    _theirs.text = d.theirScore?.toString() ?? '';
    for (final r in d.rows) {
      _stats[r.playerId] = Map<String, dynamic>.from(r.stats);
      _rating[r.playerId] = r.rating;
      if (r.mvp) _mvpId = r.playerId;
      _ctrl('${r.playerId}|notes', r.notes);
      for (final f in d.template.fields) {
        if (f.kind == 'count' || f.kind == 'time') {
          final v = r.stats[f.key];
          _ctrl('${r.playerId}|${f.key}', v == null ? '' : '$v');
        }
      }
    }
    setState(() {
      _data = d;
      _dirty = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  TextEditingController _ctrl(String id, [String initial = '']) =>
      _ctrls.putIfAbsent(id, () => TextEditingController(text: initial));

  void _set(String pid, String key, Object? value) {
    setState(() {
      final m = _stats.putIfAbsent(pid, () => {});
      if (value == null || value == '') {
        m.remove(key);
      } else {
        m[key] = value;
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final d = _data;
    if (d == null) return;
    setState(() => _saving = true);
    final body = {
      'opponent': _opponent.text.trim(),
      if (d.template.isTeam) 'ourScore': _ours.text.trim(),
      if (d.template.isTeam) 'theirScore': _theirs.text.trim(),
      'rows': [
        for (final r in d.rows)
          {
            'playerId': r.playerId,
            'stats': _stats[r.playerId] ?? const {},
            'rating': _rating[r.playerId],
            'mvp': _mvpId == r.playerId,
            'notes': _ctrl('${r.playerId}|notes').text.trim(),
          },
      ],
    };
    try {
      final saved = await MatchStatsApi.save(widget.matchId, body);
      if (!mounted) return;
      _apply(saved);
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم حفظ إحصائيات المباراة'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغييرات غير محفوظة'),
        content: const Text('لم تحفظ الإحصائيات بعد. هل تريد الخروج بدون حفظ؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('متابعة التعديل')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          setState(() => _dirty = false);
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('إحصائيات المباراة')),
        body: _body(),
        bottomNavigationBar: widget.canEdit && _data != null && _data!.rows.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 10.h),
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ الإحصائيات'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            Gap(10.h),
            Text(_error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
            Gap(12.h),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ]),
        ),
      );
    }
    final d = _data;
    if (d == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 24.h),
      children: [
        _resultCard(d),
        Gap(14.h),
        Text(
          d.template.isTeam
              ? 'إحصائيات اللاعبين (${d.rows.length})'
              : 'تقييم اللاعبين (${d.rows.length}) — نسبة % لكل عنصر',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
        ),
        Gap(4.h),
        Text(
          'اضغط على اللاعب لتسجيل أرقامه • النجمة = نجم المباراة',
          style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
        ),
        Gap(10.h),
        if (d.rows.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30.h),
            child: Center(
              child: Text('أضف لاعبين للمباراة أولاً من شاشة تفاصيل المباراة',
                  style: TextStyle(color: AppColors.grey500, fontSize: 13.sp)),
            ),
          )
        else
          ...d.rows.map((r) => _playerCard(d.template, r)),
      ],
    );
  }

  Widget _resultCard(MatchStatsData d) {
    final enabled = widget.canEdit;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        );
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(d.name, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
          Gap(4.h),
          Text('${d.date} • ${d.template.sport}',
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey600)),
          Gap(12.h),
          TextField(
            controller: _opponent,
            enabled: enabled,
            maxLength: 100,
            decoration: deco(d.template.isTeam ? 'الفريق المنافس' : 'المنافس / البطولة').copyWith(counterText: ''),
            onChanged: (_) => _markDirty(),
          ),
          if (d.template.isTeam) ...[
            Gap(10.h),
            Row(
              children: [
                Expanded(child: _scoreField(_ours, 'نتيجتنا', enabled)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text('-', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800)),
                ),
                Expanded(child: _scoreField(_theirs, 'المنافس', enabled)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreField(TextEditingController c, String label, bool enabled) => TextField(
        controller: c,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
        onChanged: (_) => _markDirty(),
      );

  Widget _playerCard(StatTemplate t, MatchStatsRow r) {
    final stats = _stats[r.playerId] ?? const {};
    final line = t.shortLine(stats);
    final rating = _rating[r.playerId];
    final isMvp = _mvpId == r.playerId;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isMvp ? AppColors.warning : AppColors.grey200, width: isMvp ? 1.5 : 1),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('stats_${r.playerId}'),
            tilePadding: EdgeInsets.symmetric(horizontal: 12.w),
            childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(r.fullName.isEmpty ? '?' : r.fullName.characters.first,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
            title: Text(r.fullName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                if (line.isNotEmpty) line,
                if (rating != null) 'تقييم ${fmtStat(rating)}/10',
                if (line.isEmpty && rating == null) 'لم تُسجَّل بعد',
              ].join(' • '),
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'نجم المباراة',
              icon: Icon(isMvp ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isMvp ? AppColors.warning : AppColors.grey400, size: 28.sp),
              onPressed: widget.canEdit
                  ? () => setState(() {
                        _mvpId = isMvp ? null : r.playerId;
                        _dirty = true;
                      })
                  : null,
            ),
            children: [
              for (final f in t.fields) _fieldEditor(r.playerId, f, stats[f.key]),
              const Divider(),
              _ratingEditor(r.playerId, rating),
              Gap(6.h),
              TextField(
                controller: _ctrl('${r.playerId}|notes'),
                enabled: widget.canEdit,
                maxLength: 300,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات المدرب',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _markDirty(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: TextStyle(fontSize: 13.sp, color: AppColors.grey800, fontWeight: FontWeight.w600));

  Widget _fieldEditor(String pid, StatField f, Object? value) {
    final enabled = widget.canEdit;
    switch (f.kind) {
      case 'count':
        final c = _ctrl('$pid|${f.key}');
        final n = (value as num?)?.toInt() ?? 0;
        void bump(int delta) {
          final next = (n + delta).clamp(0, 999);
          c.text = next == 0 && delta < 0 ? '' : '$next';
          _set(pid, f.key, c.text.isEmpty ? null : next);
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(children: [
            Expanded(child: _label(f.label)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: enabled && n > 0 ? () => bump(-1) : null,
            ),
            SizedBox(
              width: 52.w,
              child: TextField(
                controller: c,
                enabled: enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                decoration: const InputDecoration(isDense: true, hintText: '0', border: OutlineInputBorder()),
                onChanged: (s) => _set(pid, f.key, s.isEmpty ? null : int.tryParse(s)),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: enabled ? () => bump(1) : null,
            ),
          ]),
        );
      case 'percent':
        final v = (value as num?)?.toDouble();
        return Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: _label(f.label)),
              Text(v == null ? '—' : '${v.toInt()}%',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: _percentColor(v))),
              if (v != null && enabled)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'مسح',
                  icon: Icon(Icons.close, size: 16.sp),
                  onPressed: () => _set(pid, f.key, null),
                ),
            ]),
            Slider(
              value: v ?? 0,
              max: 100,
              divisions: 20,
              label: '${(v ?? 0).toInt()}%',
              activeColor: v == null ? AppColors.grey300 : _percentColor(v),
              onChanged: enabled ? (x) => _set(pid, f.key, x.round()) : null,
            ),
          ]),
        );
      case 'bool':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: _label(f.label),
          value: value == true,
          onChanged: enabled ? (x) => _set(pid, f.key, x ? true : null) : null,
        );
      case 'select':
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label(f.label),
            Gap(4.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                for (final o in f.options)
                  ChoiceChip(
                    label: Text(o.label),
                    selected: value == o.value,
                    onSelected: enabled ? (sel) => _set(pid, f.key, sel ? o.value : null) : null,
                  ),
              ],
            ),
          ]),
        );
      case 'time':
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: TextField(
            controller: _ctrl('$pid|${f.key}'),
            enabled: enabled,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: f.label,
              hintText: 'مثال: 1:05.32 أو 12.4 ث',
              isDense: true,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            onChanged: (s) => _set(pid, f.key, s.trim().isEmpty ? null : s.trim()),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _ratingEditor(String pid, double? v) {
    final enabled = widget.canEdit;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: _label('التقييم العام (من 10)')),
        Text(v == null ? '—' : fmtStat(v),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
        if (v != null && enabled)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'مسح',
            icon: Icon(Icons.close, size: 16.sp),
            onPressed: () => setState(() {
              _rating[pid] = null;
              _dirty = true;
            }),
          ),
      ]),
      Slider(
        value: v ?? 0,
        max: 10,
        divisions: 20,
        label: fmtStat(v ?? 0),
        activeColor: v == null ? AppColors.grey300 : AppColors.primary,
        onChanged: enabled
            ? (x) => setState(() {
                  _rating[pid] = (x * 2).round() / 2;
                  _dirty = true;
                })
            : null,
      ),
    ]);
  }
}

Color _percentColor(double? v) {
  if (v == null) return AppColors.grey500;
  if (v >= 75) return AppColors.success;
  if (v >= 50) return AppColors.primary;
  if (v >= 30) return AppColors.warning;
  return AppColors.error;
}

/// لون شريط النسبة (مُستخدم في ملف اللاعب أيضاً).
Color percentColor(double? v) => _percentColor(v);
