import 'dart:async';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/tournaments/data/tournament_models.dart';
import 'package:basketball_academy/features/tournaments/data/tournaments_service.dart';
import 'package:basketball_academy/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:basketball_academy/features/tournaments/presentation/widgets/tournament_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// توزيع تلقائي للاعبين على الفرق (بطولات الفرق فقط، قبل توليد الجدول).
/// الأدمن يختار اللاعبين وعدد الفرق وطريقة التوزيع:
///  - عشوائي: خلط كامل مع أحجام فرق متساوية تقريباً.
///  - متوازن: حسب آخر تقييم لكل لاعب حتى تتقارب الفرق في المستوى.
/// القائمة تعرض أول 100 لاعب، و"عرض المزيد" يجلب الباقي. البحث يتم على الخادم،
/// والاختيارات تبقى محفوظة عند تغيير البحث.
/// يعيد true عند النجاح.
class AutoSplitScreen extends ConsumerStatefulWidget {
  final TournamentDetail detail;
  const AutoSplitScreen({super.key, required this.detail});

  @override
  ConsumerState<AutoSplitScreen> createState() => _AutoSplitScreenState();
}

class _AutoSplitScreenState extends ConsumerState<AutoSplitScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<PickablePlayer> _results = [];
  // المختارون: id → اللاعب (تبقى عند تغيير البحث أو تحميل صفحات جديدة).
  final Map<String, PickablePlayer> _selected = {};
  bool _loading = true;
  bool _saving = false;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  int? _total;
  int _loadSeq = 0;
  int _teams = 2;
  String _mode = 'random';
  bool _replace = false;

  Tournament get _t => widget.detail.tournament;
  String get _academyId => _t.academyIds.isNotEmpty ? _t.academyIds.first : '';
  bool get _hasTeams => widget.detail.participants.isNotEmpty;

  /// لاعبون مسجّلون بالفعل في فرق — يُستبعدون إلا لو اختار الأدمن "إعادة التوزيع".
  Set<String> get _taken =>
      {for (final p in widget.detail.participants) ...p.playerIds};

  bool _isAvailable(String id) => _replace || !_taken.contains(id);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// الصفحة الأولى (عند الفتح أو تغيير البحث).
  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _page = 1;
    });
    try {
      final r = await ref
          .read(tournamentsServiceProvider)
          .searchPlayersPage(academyId: _academyId, search: _search.text);
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _results = r.items;
        _hasMore = r.hasNext;
        _total = r.total;
      });
    } catch (e) {
      if (mounted) {
        showToast(context, errorText(e, 'تعذّر تحميل اللاعبين'), error: true);
      }
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loading = false);
    }
  }

  /// "عرض المزيد": الصفحة التالية لنفس البحث.
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final seq = _loadSeq;
    setState(() => _loadingMore = true);
    try {
      final r = await ref.read(tournamentsServiceProvider).searchPlayersPage(
          academyId: _academyId, search: _search.text, page: _page + 1);
      if (!mounted || seq != _loadSeq) return;
      final have = {for (final p in _results) p.id};
      setState(() {
        _page++;
        _results = [..._results, ...r.items.where((p) => !have.contains(p.id))];
        _hasMore = r.hasNext;
      });
    } catch (e) {
      if (mounted) {
        showToast(context, errorText(e, 'تعذّر تحميل المزيد'), error: true);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<PickablePlayer> get _visible =>
      _results.where((p) => _isAvailable(p.id)).toList();

  List<String> get _chosen => _selected.keys.where(_isAvailable).toList();

  Future<void> _save() async {
    final ids = _chosen;
    if (ids.length < _teams) {
      return showToast(context, 'اختر $_teams لاعبين على الأقل (لاعب لكل فريق)',
          error: true);
    }
    setState(() => _saving = true);
    try {
      await ref.read(tournamentsServiceProvider).autoSplit(
            _t.id,
            playerIds: ids,
            teamsCount: _teams,
            mode: _mode,
            replace: _replace,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showToast(context, errorText(e, 'تعذّر توزيع الفرق'), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _loadMoreButton() => Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Center(
          child: _loadingMore
              ? const CircularProgressIndicator()
              : OutlinedButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more),
                  label: Text(_total != null
                      ? 'عرض المزيد (${_results.length} من $_total)'
                      : 'عرض المزيد'),
                ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final count = _chosen.length;
    final allOn =
        visible.isNotEmpty && visible.every((p) => _selected.containsKey(p.id));
    final perTeam = count / _teams;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('توزيع الفرق تلقائياً')),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('عدد الفرق',
                    style: TextStyle(
                        fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: _teams <= 2 ? null : () => setState(() => _teams--),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_teams',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: _teams >= 64 ? null : () => setState(() => _teams++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ]),
            Wrap(spacing: 8.w, children: [
              ChoiceChip(
                label: const Text('عشوائي'),
                selected: _mode == 'random',
                onSelected: (_) => setState(() => _mode = 'random'),
              ),
              ChoiceChip(
                label: const Text('متوازن حسب التقييم'),
                selected: _mode == 'balanced',
                onSelected: (_) => setState(() => _mode = 'balanced'),
              ),
            ]),
            Gap(4.h),
            Text(
              _mode == 'balanced'
                  ? 'يوزّع الأقوى على الفرق بالتناوب حتى تتقارب الفرق في المستوى. من ليس له تقييم يُعامل كمتوسط.'
                  : 'يخلط اللاعبين عشوائياً مع أحجام فرق متساوية تقريباً.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey600),
            ),
            if (_hasTeams)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('حذف الفرق الحالية وإعادة التوزيع',
                    style: TextStyle(fontSize: 13.sp)),
                subtitle: Text(
                  _replace
                      ? 'سيتم حذف ${widget.detail.participants.length} فريق حالي'
                      : 'الفرق الجديدة تُضاف للحالية، ولاعبوها مستبعدون من القائمة',
                  style: TextStyle(fontSize: 11.5.sp),
                ),
                value: _replace,
                onChanged: (v) => setState(() => _replace = v),
              ),
            Gap(6.h),
            TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), _load);
              },
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الكود',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            Row(children: [
              Expanded(
                child: Text(
                  count == 0
                      ? 'لم يتم اختيار لاعبين'
                      : 'المختارون: $count — حوالي ${perTeam.toStringAsFixed(perTeam % 1 == 0 ? 0 : 1)} لكل فريق',
                  style:
                      TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: visible.isEmpty
                    ? null
                    : () => setState(() {
                          for (final p in visible) {
                            allOn
                                ? _selected.remove(p.id)
                                : _selected[p.id] = p;
                          }
                        }),
                child: Text(allOn ? 'إلغاء المعروضين' : 'تحديد المعروضين'),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : visible.isEmpty && !_hasMore
                  ? const Center(child: Text('لا يوجد لاعبون متاحون'))
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: 100.h),
                      itemCount: visible.length + (_hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == visible.length) return _loadMoreButton();
                        final p = visible[i];
                        return CheckboxListTile(
                          dense: true,
                          value: _selected.containsKey(p.id),
                          title: Text(p.fullName),
                          subtitle:
                              p.playerCode.isEmpty ? null : Text(p.playerCode),
                          onChanged: (v) => setState(() => v == true
                              ? _selected[p.id] = p
                              : _selected.remove(p.id)),
                        );
                      },
                    ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.shuffle),
            label: Text('وزّع على $_teams فرق'),
          ),
        ),
      ),
    );
  }
}
