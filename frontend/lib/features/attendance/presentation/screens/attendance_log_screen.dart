import 'dart:async';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/attendance/domain/entities/attendance_entity.dart';
import 'package:basketball_academy/features/attendance/domain/usecases/delete_attendance_usecase.dart';
import 'package:basketball_academy/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:basketball_academy/features/attendance/presentation/widgets/attendance_kind_badge.dart';
import 'package:basketball_academy/features/attendance/presentation/widgets/subscription_stats_banner.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

const _kAttendanceManagerRoles = [
  UserRole.superAdmin,
  UserRole.academyAdmin,
  UserRole.admin,
];

class AttendanceLogScreen extends ConsumerStatefulWidget {
  final String academyId;
  const AttendanceLogScreen({super.key, required this.academyId});

  @override
  ConsumerState<AttendanceLogScreen> createState() =>
      _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends ConsumerState<AttendanceLogScreen> {
  String? _date; // 'YYYY-MM-DD' أو null = كل التواريخ
  String? _sport; // null = الكل
  String _playerQuery = ''; // بحث لاعب على السيرفر (كارت لكل لاعب)
  Timer? _debounce;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _playerQuery = v.trim());
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) {
      setState(() =>
          _date = '${picked.year}-${_two(picked.month)}-${_two(picked.day)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];
    final userRole = ref.watch(authStateProvider).valueOrNull?.user?.role;
    final canDelete = _kAttendanceManagerRoles.contains(userRole);

    final filter = AttendanceLogFilter(
      academyId: widget.academyId,
      date: _date,
      sport: _sport,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سجل الحضور'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // فلتر التاريخ (لا يظهر أثناء البحث عن لاعب)
          if (_playerQuery.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon:
                          const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(_date ?? 'كل التواريخ'),
                    ),
                  ),
                  if (_date != null) ...[
                    Gap(8.w),
                    IconButton(
                      tooltip: 'مسح التاريخ',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _date = null),
                    ),
                  ],
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: TextField(
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'بحث باسم اللاعب أو الكود',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.white,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          // فلتر الرياضة (للأكاديميات متعددة الرياضات)
          if (isMultiSport)
            _SportChips(
              sports: sports,
              selected: _sport,
              onSelected: (s) => setState(() => _sport = s),
            ),
          Expanded(
            child: _playerQuery.isNotEmpty
                ? _PlayerSearchResults(
                    academyId: widget.academyId,
                    query: _playerQuery,
                    sport: _sport,
                    canDelete: canDelete,
                  )
                : PagedAttendanceLog(filter: filter, canDelete: canDelete),
          ),
        ],
      ),
    );
  }
}

/// قائمة سجل الحضور بصفحات من 100 — زر "إظهار المزيد" يضيف 100 أخرى.
/// كل صفحة طلب مستقل مخزّن عبر attendanceLogProvider(filter.copyWithPage(n)).
class PagedAttendanceLog extends ConsumerStatefulWidget {
  final AttendanceLogFilter filter;
  final bool canDelete;
  final Widget? header;

  const PagedAttendanceLog({
    super.key,
    required this.filter,
    required this.canDelete,
    this.header,
  });

  @override
  ConsumerState<PagedAttendanceLog> createState() => _PagedAttendanceLogState();
}

class _PagedAttendanceLogState extends ConsumerState<PagedAttendanceLog> {
  int _pages = 1;

  @override
  void didUpdateWidget(covariant PagedAttendanceLog old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter) _pages = 1;
  }

  void _refreshAll() {
    for (var p = 1; p <= _pages; p++) {
      ref.invalidate(attendanceLogProvider(widget.filter.copyWithPage(p)));
    }
    ref.invalidate(attendanceReportProvider);
    if (widget.filter.playerId != null) {
      ref.invalidate(attendancePlayerSummaryProvider(widget.filter.playerId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = ref.watch(attendanceLogProvider(widget.filter.copyWithPage(1)));
    if (first.isLoading && !first.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (first.hasError && !first.hasValue) {
      return _ErrorView(onRetry: _refreshAll);
    }

    final records = <AttendanceLogEntry>[];
    var total = 0;
    var totalPages = 1;
    var loadingMore = false;
    var moreError = false;
    for (var p = 1; p <= _pages; p++) {
      final page = ref.watch(attendanceLogProvider(widget.filter.copyWithPage(p)));
      final data = page.valueOrNull;
      if (data != null) {
        records.addAll(data.records);
        total = data.total;
        totalPages = data.totalPages;
      } else if (page.hasError) {
        moreError = true;
      } else {
        loadingMore = true;
      }
    }
    final hasMore = _pages < totalPages;

    final header = widget.header;
    if (records.isEmpty) {
      return Column(
        children: [
          if (header != null)
            Padding(padding: EdgeInsets.all(16.r), child: header),
          Expanded(child: _EmptyView()),
        ],
      );
    }

    final extra = header != null ? 1 : 0;
    return RefreshIndicator(
      onRefresh: () async => _refreshAll(),
      child: ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: records.length + extra + 1,
        separatorBuilder: (_, __) => Gap(10.h),
        itemBuilder: (_, i) {
          if (header != null && i == 0) return header;
          final idx = i - extra;
          if (idx < records.length) {
            return _LogTile(
              entry: records[idx],
              canDelete: widget.canDelete,
              onDeleted: _refreshAll,
            );
          }
          // الذيل: عدّاد + إظهار المزيد
          return Column(
            children: [
              Text(
                'عرض ${records.length} من $total سجل',
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
              ),
              if (loadingMore)
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: const CircularProgressIndicator(),
                )
              else if (moreError)
                TextButton.icon(
                  onPressed: () => ref.invalidate(attendanceLogProvider(
                      widget.filter.copyWithPage(_pages))),
                  icon: const Icon(Icons.refresh),
                  label: const Text('تعذّر التحميل — إعادة المحاولة'),
                )
              else if (hasMore)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _pages++),
                    icon: const Icon(Icons.expand_more),
                    label: const Text('إظهار المزيد'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// نتائج البحث — كارت واحد لكل لاعب، الضغط يفتح سجل حضوره الكامل.
class _PlayerSearchResults extends ConsumerWidget {
  final String academyId;
  final String query;
  final String? sport;
  final bool canDelete;

  const _PlayerSearchResults({
    required this.academyId,
    required this.query,
    required this.sport,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = AttendancePlayerSearchKey(
        academyId: academyId, query: query, sport: sport);
    final async = ref.watch(attendancePlayerSearchProvider(key));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(attendancePlayerSearchProvider(key))),
      data: (players) {
        if (players.isEmpty) {
          return Center(
            child: Text('لا يوجد لاعب مطابق',
                style: TextStyle(fontSize: 14.sp, color: AppColors.grey500)),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(16.r),
          itemCount: players.length,
          separatorBuilder: (_, __) => Gap(10.h),
          itemBuilder: (_, i) {
            final p = players[i];
            return Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AttendancePlayerLogScreen(
                    academyId: academyId,
                    player: p,
                    canDelete: canDelete,
                  ),
                )),
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    children: [
                      _Avatar(imageUrl: p.imageUrl),
                      Gap(12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.fullName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey900,
                                )),
                            Gap(2.h),
                            Text(
                              [
                                p.playerCode,
                                if (p.sport != null && p.sport!.isNotEmpty)
                                  p.sport!,
                              ].join(' • '),
                              style: TextStyle(
                                  fontSize: 11.sp, color: AppColors.grey500),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left, color: AppColors.grey500),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// سجل حضور لاعب واحد + ملخص حضوره في اشتراكه الأخير.
class AttendancePlayerLogScreen extends ConsumerWidget {
  final String academyId;
  final AttendancePlayer player;
  final bool canDelete;

  const AttendancePlayerLogScreen({
    super.key,
    required this.academyId,
    required this.player,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendancePlayerSummaryProvider(player.id));
    final header = summary.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text('تعذّر تحميل ملخص الاشتراك',
          style: TextStyle(fontSize: 12.sp, color: AppColors.error)),
      data: (s) => SubscriptionStatsBanner(stats: s.stats),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(player.fullName), centerTitle: true),
      body: PagedAttendanceLog(
        filter: AttendanceLogFilter(academyId: academyId, playerId: player.id),
        canDelete: canDelete,
        header: header,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  const _Avatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryContainer,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.person, color: AppColors.primary, size: 22.sp),
              )
            : Icon(Icons.person, color: AppColors.primary, size: 22.sp),
      ),
    );
  }
}

class _SportChips extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SportChips({
    required this.sports,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...sports];
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        itemCount: options.length,
        separatorBuilder: (_, __) => Gap(8.w),
        itemBuilder: (_, i) {
          final value = options[i];
          final isSel = value == selected;
          return ChoiceChip(
            label: Text(value ?? 'الكل'),
            selected: isSel,
            onSelected: (_) => onSelected(value),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSel ? AppColors.white : AppColors.grey700,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
            backgroundColor: AppColors.white,
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AttendanceLogEntry entry;
  final bool canDelete;
  final VoidCallback onDeleted;
  const _LogTile({
    required this.entry,
    required this.canDelete,
    required this.onDeleted,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('حذف سجل الحضور'),
        content: Text(
          'هل تريد حذف سجل حضور "${entry.playerName.isNotEmpty ? entry.playerName : entry.playerCode}" بتاريخ ${_fmtDate(entry.date)}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final result = await sl<DeleteAttendanceUsecase>()(entry.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر حذف السجل: ${failure.message}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف سجل الحضور'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        onDeleted();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
            ),
            child: ClipOval(
              child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: entry.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(Icons.person,
                          color: AppColors.primary, size: 22.sp),
                    )
                  : Icon(Icons.person, color: AppColors.primary, size: 22.sp),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName.isNotEmpty
                      ? entry.playerName
                      : entry.playerCode,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                Gap(2.h),
                Text(
                  [
                    entry.playerCode,
                    if (entry.sport != null && entry.sport!.isNotEmpty)
                      entry.sport!,
                  ].join(' • '),
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                ),
                if (AttendanceKind.label(entry.kind) != null) ...[
                  Gap(4.h),
                  AttendanceKindBadge(kind: entry.kind),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtDate(entry.date),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              Gap(2.h),
              Text(
                entry.time,
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
              ),
            ],
          ),
          if (canDelete) ...[
            Gap(4.w),
            IconButton(
              tooltip: 'حذف سجل الحضور',
              icon: Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20.sp),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(String ymd) {
    try {
      final d = DateTime.parse(ymd);
      return DateFormat('dd/MM/yyyy', 'ar').format(d);
    } catch (_) {
      return ymd;
    }
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 64.sp, color: AppColors.grey300),
          Gap(12.h),
          Text(
            'لا توجد سجلات حضور',
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56.sp, color: AppColors.error),
          Gap(12.h),
          Text('تعذّر تحميل السجل',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey700)),
          Gap(12.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
