import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// تقييمات التمرين اليومية (GET /training-ratings) — null = أحدث يوم فيه تقييمات.
final trainingRatingsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String?>((ref, date) async {
  final res = await sl<ApiClient>().get<Map<String, dynamic>>(
    '/training-ratings',
    queryParameters: {if (date != null) 'date': date, 'days': 30},
  );
  return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
});

/// شاشة الإدارة: تقييمات اللاعبين للتمرين مقسّمة بالأيام.
class TrainingRatingsScreen extends ConsumerStatefulWidget {
  const TrainingRatingsScreen({super.key});

  @override
  ConsumerState<TrainingRatingsScreen> createState() =>
      _TrainingRatingsScreenState();
}

class _TrainingRatingsScreenState extends ConsumerState<TrainingRatingsScreen> {
  String? _date;

  static String _ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static String _fmt(String ymd) {
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : DateFormat('EEEE dd/MM', 'ar').format(d);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date ?? '') ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = _ymd(picked));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(trainingRatingsProvider(_date));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقييم التمرين'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'اختيار يوم',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(trainingRatingsProvider(_date)),
            child: const Text('إعادة المحاولة'),
          ),
        ),
        data: (data) {
          final date = data['date'] as String;
          final days = (data['days'] as List<dynamic>).cast<Map<String, dynamic>>();
          final ratings = (data['ratings'] as List<dynamic>).cast<Map<String, dynamic>>();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(trainingRatingsProvider(_date)),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                if (days.isNotEmpty)
                  SizedBox(
                    height: 74.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      separatorBuilder: (_, __) => Gap(8.w),
                      itemBuilder: (_, i) => _DayChip(
                        label: _fmt(days[i]['date'] as String),
                        average: (days[i]['average'] as num).toDouble(),
                        count: (days[i]['count'] as num).toInt(),
                        selected: days[i]['date'] == date,
                        onTap: () => setState(() => _date = days[i]['date'] as String),
                      ),
                    ),
                  ),
                Gap(16.h),
                _SummaryCard(
                  label: _fmt(date),
                  average: (data['average'] as num).toDouble(),
                  count: (data['count'] as num).toInt(),
                ),
                Gap(12.h),
                if (ratings.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 40.h),
                    child: Text('لا توجد تقييمات في هذا اليوم',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grey500, fontSize: 14.sp)),
                  )
                else
                  for (final r in ratings) ...[
                    _RatingTile(rating: r),
                    Gap(8.h),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double value;
  final double size;
  const _Stars(this.value, {this.size = 18});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              value >= i
                  ? Icons.star_rounded
                  : value >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: size.sp,
              color: AppColors.warning,
            ),
        ],
      );
}

class _DayChip extends StatelessWidget {
  final String label;
  final double average;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip({
    required this.label,
    required this.average,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryContainer : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.grey200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
              Gap(2.h),
              Text('★ ${average.toStringAsFixed(1)} · $count',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey600)),
            ],
          ),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double average;
  final int count;
  const _SummaryCard({required this.label, required this.average, required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                  Gap(4.h),
                  Text('$count تقييم',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey500)),
                ],
              ),
            ),
            Column(
              children: [
                Text(average.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                _Stars(average, size: 16),
              ],
            ),
          ],
        ),
      );
}

class _RatingTile extends StatelessWidget {
  final Map<String, dynamic> rating;
  const _RatingTile({required this.rating});

  @override
  Widget build(BuildContext context) {
    final player = rating['player'] as Map<String, dynamic>?;
    final image = player?['image_url'] as String?;
    final notes = (rating['notes'] as String?) ?? '';
    final created = DateTime.tryParse(rating['createdAt']?.toString() ?? '')?.toLocal();
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: (image ?? '').isNotEmpty
                    ? CachedNetworkImageProvider(image!)
                    : null,
                child: (image ?? '').isEmpty
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              Gap(10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player?['fullName']?.toString() ?? 'لاعب محذوف',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    Text(
                      [
                        player?['playerCode']?.toString() ?? '',
                        if (created != null) DateFormat('HH:mm').format(created),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(fontSize: 11.sp, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              _Stars((rating['stars'] as num).toDouble()),
            ],
          ),
          if (notes.isNotEmpty) ...[
            Gap(8.h),
            Text(notes, style: TextStyle(fontSize: 13.sp, color: AppColors.grey700)),
          ],
        ],
      ),
    );
  }
}
