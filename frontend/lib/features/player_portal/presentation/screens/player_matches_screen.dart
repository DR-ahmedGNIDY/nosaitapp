import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/player_portal/presentation/providers/player_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// مباريات اللاعب المسجّل فيها: القادمة أولاً ثم السابقة.
class PlayerMatchesScreen extends ConsumerWidget {
  const PlayerMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerMatchesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المباريات'), centerTitle: true),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(playerMatchesProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (data) {
          final upcoming =
              (data['upcoming'] as List<dynamic>).cast<Map<String, dynamic>>();
          final past =
              (data['past'] as List<dynamic>).cast<Map<String, dynamic>>();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(playerMatchesProvider),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _SectionHeader(
                    title: 'المباريات القادمة', count: upcoming.length),
                Gap(8.h),
                if (upcoming.isEmpty)
                  const _Empty(text: 'لا توجد مباريات قادمة مسجّل فيها')
                else
                  for (final m in upcoming) ...[
                    _MatchCard(match: m, upcoming: true),
                    Gap(10.h)
                  ],
                Gap(16.h),
                _SectionHeader(title: 'مباريات سابقة', count: past.length),
                Gap(8.h),
                if (past.isEmpty)
                  const _Empty(text: 'لا توجد مباريات سابقة')
                else
                  for (final m in past) ...[
                    _MatchCard(match: m, upcoming: false),
                    Gap(10.h)
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Text('$title ($count)',
      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800));
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey500)),
      );
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final bool upcoming;
  const _MatchCard({required this.match, required this.upcoming});

  String get _dateLabel {
    final d = DateTime.tryParse(match['date']?.toString() ?? '');
    return d == null
        ? (match['date']?.toString() ?? '')
        : DateFormat('EEEE dd/MM/yyyy', 'ar').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final color = upcoming ? AppColors.primary : AppColors.grey500;
    final location = (match['location'] as String?) ?? '';
    final notes = (match['notes'] as String?) ?? '';
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
            color: upcoming
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_basketball, color: color),
              Gap(8.w),
              Expanded(
                child: Text(match['name']?.toString() ?? '',
                    style: TextStyle(
                        fontSize: 15.sp, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          Gap(8.h),
          _line(Icons.calendar_today_outlined, _dateLabel),
          _line(Icons.access_time, match['time']?.toString() ?? ''),
          if (location.isNotEmpty) _line(Icons.place_outlined, location),
          if (notes.isNotEmpty) ...[
            Gap(6.h),
            Text(notes,
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
          ],
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: AppColors.grey500),
            Gap(6.w),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.grey700)),
            ),
          ],
        ),
      );
}
