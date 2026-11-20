import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/match_stats/match_stats_data.dart';
import 'package:basketball_academy/features/match_stats/player_match_stats_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// ترتيب الأكاديمية (أعلى 10) لرياضة وحقل — الهدافون، الأكثر أسيست، الأعلى تقييماً...
/// [portal] = true ⇒ بوابة اللاعب (رياضة اللاعب فقط).
class LeaderboardScreen extends ConsumerStatefulWidget {
  final bool portal;
  final String? academyId;
  final String? initialSport;
  final List<String> sports;
  final String? highlightPlayerId;

  const LeaderboardScreen({
    super.key,
    this.portal = false,
    this.academyId,
    this.initialSport,
    this.sports = const [],
    this.highlightPlayerId,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _sport;
  String? _field;

  @override
  void initState() {
    super.initState();
    _sport = widget.initialSport ?? (widget.sports.isNotEmpty ? widget.sports.first : null);
  }

  @override
  Widget build(BuildContext context) {
    final q = (portal: widget.portal, academyId: widget.academyId, sport: _sport, field: _field);
    final async = ref.watch(leaderboardProvider(q));
    final data = async.valueOrNull;
    final sports = {...widget.sports, if (_sport != null) _sport!}.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(data == null ? 'ترتيب الأكاديمية' : 'ترتيب الأكاديمية — ${data.sport}')),
      body: Column(children: [
        if (!widget.portal && sports.length > 1)
          _chips(
            [for (final s in sports) StatOption(s, s)],
            _sport,
            (v) => setState(() {
              _sport = v;
              _field = null;
            }),
          ),
        if (data != null) _chips(data.fields, data.fieldKey, (v) => setState(() => _field = v)),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
                  Gap(12.h),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(leaderboardProvider(q)),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]),
              ),
            ),
            data: (d) => d.rows.isEmpty
                ? Center(
                    child: Text('لا توجد إحصائيات مسجّلة بعد في ${d.fieldLabel}',
                        style: TextStyle(color: AppColors.grey500, fontSize: 13.sp)),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(leaderboardProvider(q).future),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
                      itemCount: d.rows.length,
                      separatorBuilder: (_, __) => Gap(8.h),
                      itemBuilder: (_, i) => _row(context, d, i),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _chips(List<StatOption> options, String? selected, ValueChanged<String> onTap) => SizedBox(
        height: 48.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          children: [
            for (final o in options)
              Padding(
                padding: EdgeInsetsDirectional.only(end: 6.w),
                child: ChoiceChip(
                  label: Text(o.label),
                  selected: o.value == selected,
                  onSelected: (_) => onTap(o.value),
                ),
              ),
          ],
        ),
      );

  Widget _row(BuildContext context, LeaderboardData d, int i) {
    final r = d.rows[i];
    const medals = [Color(0xFFFFB300), Color(0xFF9E9E9E), Color(0xFFB87333)];
    final me = widget.highlightPlayerId != null && r.playerId == widget.highlightPlayerId;
    final valueText = d.isAverage
        ? (d.fieldKey == 'rating' ? fmtStat(r.value) : '${fmtStat(r.value)}%')
        : fmtStat(r.value);
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: widget.portal
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerMatchStatsScreen(
                  playerId: r.playerId,
                  playerName: r.fullName,
                  academyId: widget.academyId,
                ),
              )),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: me ? AppColors.primary.withValues(alpha: 0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: i < 3 ? medals[i].withValues(alpha: 0.6) : AppColors.grey200),
        ),
        child: Row(children: [
          SizedBox(
            width: 30.w,
            child: i < 3
                ? Icon(Icons.emoji_events, color: medals[i], size: 24.sp)
                : Text('${i + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.grey600)),
          ),
          Gap(8.w),
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.grey100,
            backgroundImage: r.imageUrl != null && r.imageUrl!.isNotEmpty
                ? CachedNetworkImageProvider(r.imageUrl!)
                : null,
            child: r.imageUrl == null || r.imageUrl!.isEmpty
                ? Text(r.fullName.isEmpty ? '?' : r.fullName.characters.first)
                : null,
          ),
          Gap(10.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.fullName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
              Text('${r.matches} مباراة', style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey500)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(valueText,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(d.isAverage ? 'متوسط' : d.fieldLabel,
                style: TextStyle(fontSize: 10.5.sp, color: AppColors.grey500)),
          ]),
        ]),
      ),
    );
  }
}
