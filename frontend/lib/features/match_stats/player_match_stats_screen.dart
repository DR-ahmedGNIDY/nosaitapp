import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/match_stats/leaderboard_screen.dart';
import 'package:basketball_academy/features/match_stats/match_stats_data.dart';
import 'package:basketball_academy/features/match_stats/match_stats_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// ملف إحصائيات اللاعب في المباريات: ملخص الموسم + آخر المباريات + أفضل مباراة.
/// [playerId] == null ⇒ بوابة اللاعب ("إحصائياتي").
class PlayerMatchStatsScreen extends ConsumerWidget {
  final String? playerId;
  final String? playerName;
  final String? academyId;
  const PlayerMatchStatsScreen({super.key, this.playerId, this.playerName, this.academyId});

  bool get _portal => playerId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerMatchStatsProvider(playerId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_portal ? 'إحصائياتي' : 'إحصائيات ${playerName ?? 'اللاعب'}'),
        actions: [
          IconButton(
            tooltip: 'ترتيب الأكاديمية',
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () {
              final sport = async.valueOrNull?.sport;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LeaderboardScreen(
                  portal: _portal,
                  academyId: academyId,
                  initialSport: sport == null || sport.isEmpty ? null : sport,
                  highlightPlayerId: playerId ?? async.valueOrNull?.playerId,
                ),
              ));
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(playerMatchStatsProvider(playerId)),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(playerMatchStatsProvider(playerId).future),
          child: d.matches == 0
              ? ListView(children: [
                  SizedBox(height: 120.h),
                  Icon(Icons.query_stats, size: 64.sp, color: AppColors.grey300),
                  Gap(12.h),
                  Center(
                    child: Text(
                      _portal ? 'لا توجد إحصائيات مباريات لك بعد' : 'لا توجد إحصائيات مباريات لهذا اللاعب بعد',
                      style: TextStyle(color: AppColors.grey500, fontSize: 14.sp),
                    ),
                  ),
                  Gap(6.h),
                  Center(
                    child: Text('تظهر هنا بعد أن يسجّل المدرب أرقامك في المباريات',
                        style: TextStyle(color: AppColors.grey400, fontSize: 12.sp)),
                  ),
                ])
              : _content(context, d),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PlayerStatsData d) {
    final t = d.template;
    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 30.h),
      children: [
        Row(children: [
          _tile(Icons.sports_outlined, '${d.matches}', 'مباراة', AppColors.primary),
          Gap(8.w),
          _tile(Icons.star_rounded, '${d.mvpCount}', 'نجم المباراة', AppColors.warning),
          Gap(8.w),
          _tile(Icons.grade_outlined, d.avgRating == null ? '—' : fmtStat(d.avgRating), 'متوسط التقييم',
              AppColors.success),
        ]),
        Gap(14.h),
        _card(
          title: t.isTeam ? 'أرقام الموسم — ${t.sport}' : 'مستوى الأداء — ${t.sport}',
          child: t.isTeam ? _teamTotals(d) : _individualBars(d),
        ),
        if (!t.isTeam) ...[
          Gap(12.h),
          _card(title: 'النتائج', child: _outcomes(d)),
        ],
        if (d.best != null) ...[
          Gap(12.h),
          _card(
            title: 'أفضل مباراة',
            child: _matchLine(context, t, d.best!, highlight: true),
          ),
        ],
        Gap(12.h),
        _card(
          title: 'آخر المباريات',
          child: Column(children: [
            for (final m in d.recent) _matchLine(context, t, m),
          ]),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String value, String label, Color color) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22.sp),
            Gap(4.h),
            Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.grey700), textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _card({required String title, required Widget child}) => Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
          Gap(10.h),
          child,
        ]),
      );

  Widget _teamTotals(PlayerStatsData d) {
    final fields = d.template.fields.where((f) => f.kind == 'count' || f.kind == 'bool').toList();
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 16.w) / 3;
      return Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final f in fields)
            Container(
              width: w,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(children: [
                Text(fmtStat(d.fields[f.key]?['total'] as num?),
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
                Text(f.label,
                    style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey700),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (f.kind == 'count')
                  Text('متوسط ${fmtStat(d.fields[f.key]?['avg'] as num?)}',
                      style: TextStyle(fontSize: 10.5.sp, color: AppColors.grey500)),
              ]),
            ),
        ],
      );
    });
  }

  Widget _individualBars(PlayerStatsData d) {
    final fields = d.template.fields.where((f) => f.kind == 'percent').toList();
    return Column(children: [
      for (final f in fields) ...[
        Builder(builder: (_) {
          final v = (d.fields[f.key]?['avg'] as num?)?.toDouble();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(f.label, style: TextStyle(fontSize: 13.sp))),
              Text(v == null ? '—' : '${fmtStat(v)}%',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: percentColor(v))),
            ]),
            Gap(4.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: (v ?? 0) / 100,
                minHeight: 9.h,
                backgroundColor: AppColors.grey100,
                color: percentColor(v),
              ),
            ),
            Gap(10.h),
          ]);
        }),
      ],
    ]);
  }

  Widget _outcomes(PlayerStatsData d) {
    final outcome = d.template.fields.where((f) => f.key == 'outcome').firstOrNull;
    final tally = (d.fields['outcome']?['tally'] as Map?) ?? const {};
    if (outcome == null) return const SizedBox.shrink();
    final colors = {'win': AppColors.success, 'loss': AppColors.error, 'draw': AppColors.grey600};
    return Row(children: [
      for (final o in outcome.options) ...[
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: (colors[o.value] ?? AppColors.primary).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(children: [
              Text('${(tally[o.value] as num?)?.toInt() ?? 0}',
                  style: TextStyle(
                      fontSize: 18.sp, fontWeight: FontWeight.w900, color: colors[o.value] ?? AppColors.primary)),
              Text(o.label, style: TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
            ]),
          ),
        ),
        if (o != outcome.options.last) Gap(8.w),
      ],
    ]);
  }

  Widget _matchLine(BuildContext context, StatTemplate t, PlayerMatchLine m, {bool highlight = false}) {
    final line = t.shortLine(m.stats, max: 4);
    return InkWell(
      onTap: _portal
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MatchStatsEntryScreen(matchId: m.matchId, canEdit: false),
              )),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(children: [
          if (m.mvp) Icon(Icons.star_rounded, color: AppColors.warning, size: 20.sp) else Gap(20.sp),
          Gap(8.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                [m.matchName, if (m.opponent.isNotEmpty) 'ضد ${m.opponent}'].join(' '),
                style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
              ),
              Text(
                [m.date, if (m.score != null) 'النتيجة ${m.score}'].join(' • '),
                style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey500),
              ),
              if (line.isNotEmpty)
                Text(line, style: TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
            ]),
          ),
          if (m.rating != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: (highlight ? AppColors.warning : AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(fmtStat(m.rating),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: highlight ? AppColors.warning : AppColors.primary)),
            ),
        ]),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            Gap(10.h),
            Text(message, textAlign: TextAlign.center),
            Gap(12.h),
            ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ]),
        ),
      );
}
