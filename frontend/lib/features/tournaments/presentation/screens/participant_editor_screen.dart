import 'dart:async';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/tournaments/data/tournament_models.dart';
import 'package:basketball_academy/features/tournaments/data/tournaments_service.dart';
import 'package:basketball_academy/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:basketball_academy/features/tournaments/presentation/widgets/tournament_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// إضافة / تعديل مشارك: في الفردي لاعب واحد، في الجماعي فريق يختار الأدمن لاعبيه وكابتنه.
class ParticipantEditorScreen extends ConsumerStatefulWidget {
  final TournamentDetail detail;
  final TournamentParticipant? existing;
  const ParticipantEditorScreen(
      {super.key, required this.detail, this.existing});

  @override
  ConsumerState<ParticipantEditorScreen> createState() =>
      _ParticipantEditorScreenState();
}

class _ParticipantEditorScreenState
    extends ConsumerState<ParticipantEditorScreen> {
  late final TextEditingController _name;
  final _search = TextEditingController();
  Timer? _debounce;
  late String _branch;
  List<PickablePlayer> _results = [];
  bool _loading = true;
  bool _saving = false;
  // صفحات اللاعبين: أول 100 ثم "عرض المزيد".
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  int _loadSeq = 0; // يتجاهل ردود بحث قديمة وصلت متأخرة
  // المختارون: id → الاسم
  final Map<String, String> _selected = {};
  String? _captain;

  Tournament get t => widget.detail.tournament;
  bool get _playersLocked => widget.existing != null && !t.isDraft;

  /// لاعبون مسجّلون في مشاركين آخرين بنفس البطولة.
  late final Set<String> _taken = {
    for (final p in widget.detail.participants)
      if (p.id != widget.existing?.id) ...p.playerIds,
  };

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _branch = t.academyIds.isNotEmpty ? t.academyIds.first : '';
    for (final id in widget.existing?.playerIds ?? const <String>[]) {
      _selected[id] = widget.detail.player(id)?.fullName ?? '';
    }
    _captain = widget.existing?.captainId;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  /// يحمّل الصفحة الأولى (عند الفتح أو تغيير البحث/الفرع).
  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _page = 1;
    });
    try {
      final r = await ref
          .read(tournamentsServiceProvider)
          .searchPlayersPage(academyId: _branch, search: _search.text);
      if (mounted && seq == _loadSeq) {
        setState(() {
          _results = r.items;
          _hasMore = r.hasNext;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(context, errorText(e, 'تعذّر تحميل اللاعبين'), error: true);
      }
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loading = false);
    }
  }

  /// "عرض المزيد": يضيف الصفحة التالية لنفس البحث.
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final seq = _loadSeq;
    setState(() => _loadingMore = true);
    try {
      final r = await ref.read(tournamentsServiceProvider).searchPlayersPage(
          academyId: _branch, search: _search.text, page: _page + 1);
      if (mounted && seq == _loadSeq) {
        final have = {for (final p in _results) p.id};
        setState(() {
          _page++;
          _results = [
            ..._results,
            ...r.items.where((p) => !have.contains(p.id))
          ];
          _hasMore = r.hasNext;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(context, errorText(e, 'تعذّر تحميل المزيد'), error: true);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
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
                  label: const Text('عرض المزيد'),
                ),
        ),
      );

  void _toggle(PickablePlayer p) {
    if (_playersLocked) return;
    setState(() {
      if (_selected.containsKey(p.id)) {
        _selected.remove(p.id);
        if (_captain == p.id) _captain = null;
      } else {
        if (!t.isTeam) _selected.clear();
        _selected[p.id] = p.fullName;
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      return showToast(context, 'اختر ${t.isTeam ? 'لاعبي الفريق' : 'اللاعب'}',
          error: true);
    }
    if (t.isTeam && _name.text.trim().isEmpty) {
      return showToast(context, 'اكتب اسم الفريق', error: true);
    }
    setState(() => _saving = true);
    final svc = ref.read(tournamentsServiceProvider);
    try {
      final ids = _selected.keys.toList();
      if (widget.existing == null) {
        await svc.addParticipant(t.id,
            name: t.isTeam ? _name.text.trim() : null,
            playerIds: ids,
            captainId: _captain);
      } else {
        await svc.updateParticipant(t.id, widget.existing!.id,
            name: t.isTeam ? _name.text.trim() : null,
            playerIds: _playersLocked ? null : ids,
            captainId: _captain);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showToast(context, errorText(e, 'تعذّر الحفظ'), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academies = ref.watch(academiesProvider).valueOrNull ?? const [];
    String branchName(String id) {
      for (final a in academies) {
        if (a.id == id) return a.name;
      }
      return 'الفرع';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existing == null
            ? (t.isTeam ? 'فريق جديد' : 'إضافة لاعب')
            : 'تعديل ${widget.existing!.name}'),
      ),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (t.isTeam)
              TextField(
                controller: _name,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'اسم الفريق',
                  filled: true,
                  fillColor: AppColors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            if (_selected.isNotEmpty) ...[
              Text(
                  t.isTeam
                      ? 'لاعبو الفريق (${_selected.length}) — اضغط ★ لتحديد الكابتن'
                      : 'اللاعب المختار',
                  style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey700)),
              Gap(6.h),
              Wrap(spacing: 6.w, runSpacing: 6.h, children: [
                for (final e in _selected.entries)
                  InputChip(
                    avatar: t.isTeam
                        ? GestureDetector(
                            onTap: () => setState(() =>
                                _captain = _captain == e.key ? null : e.key),
                            child: Icon(
                                _captain == e.key
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppColors.warning,
                                size: 18),
                          )
                        : null,
                    label: Text(e.value.isEmpty ? 'لاعب' : e.value),
                    onDeleted: _playersLocked
                        ? null
                        : () => setState(() {
                              _selected.remove(e.key);
                              if (_captain == e.key) _captain = null;
                            }),
                  ),
              ]),
            ],
            if (_playersLocked)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text('بدأت البطولة — يمكن تعديل الاسم والكابتن فقط.',
                    style:
                        TextStyle(fontSize: 12.sp, color: AppColors.warning)),
              ),
            if (!_playersLocked) ...[
              if (t.academyIds.length > 1) ...[
                Gap(8.h),
                Wrap(spacing: 6.w, children: [
                  for (final id in t.academyIds)
                    ChoiceChip(
                      label: Text(branchName(id)),
                      selected: _branch == id,
                      onSelected: (_) {
                        setState(() => _branch = id);
                        _load();
                      },
                    ),
                ]),
              ],
              Gap(8.h),
              TextField(
                controller: _search,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), _load);
                },
                decoration: InputDecoration(
                  hintText: 'ابحث باسم اللاعب أو الكود...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ]),
        ),
        Gap(8.h),
        if (!_playersLocked)
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const EmptyHint(
                        icon: Icons.person_search_outlined,
                        text: 'لا يوجد لاعبون')
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 100.h),
                        itemCount: _results.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => Gap(6.h),
                        itemBuilder: (_, i) {
                          if (i == _results.length) return _loadMoreButton();
                          final p = _results[i];
                          final taken = _taken.contains(p.id);
                          final picked = _selected.containsKey(p.id);
                          return Material(
                            color: picked
                                ? AppColors.primaryContainer
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10.r),
                            child: ListTile(
                              dense: true,
                              enabled: !taken,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                side:
                                    const BorderSide(color: AppColors.grey200),
                              ),
                              title: Text(p.fullName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp)),
                              subtitle: Text(
                                  taken ? 'مسجّل في مشارك آخر' : p.playerCode),
                              trailing: Icon(
                                picked
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                color: taken
                                    ? AppColors.grey300
                                    : AppColors.primary,
                              ),
                              onTap: taken ? null : () => _toggle(p),
                            ),
                          );
                        },
                      ),
          )
        else
          const Spacer(),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ'),
          ),
        ),
      ),
    );
  }
}
