import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/academy/presentation/providers/currency_provider.dart';
import 'package:basketball_academy/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:basketball_academy/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:basketball_academy/features/attendance/presentation/screens/attendance_hub_screen.dart';
import 'package:basketball_academy/features/dashboard/presentation/screens/sport_detail_screen.dart';
import 'package:basketball_academy/features/notification/presentation/screens/notifications_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedAcademyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider).valueOrNull;
      final user = authState?.user;
      if (user == null) return;
      // admin لا يملك صلاحية الـ dashboard — أعد توجيهه
      if (user.isAdmin && user.academyId != null) {
        context.go(
          AppRoutes.playersList.replaceFirst(':id', user.academyId!),
        );
        return;
      }
      if (user.isAcademyAdmin) {
        ref.read(dashboardProvider.notifier).refresh(academyId: user.academyId);
      } else {
        ref.read(dashboardProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final user = authState?.user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final dashAsync = ref.watch(dashboardProvider);
    final currentAcademyId = isSuperAdmin ? _selectedAcademyId : user?.academyId;
    final currencyLabel = ref.watch(
      academyCurrencyLabelProvider(currentAcademyId),
    );

    // Resolve the current academy to know whether to show the sports section.
    final currentAcademy = currentAcademyId != null
        ? ref.watch(academyByIdProvider(currentAcademyId)).valueOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        title: Text(
          AppStrings.dashboard,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.list_alt_outlined),
              tooltip: AppStrings.academies,
              onPressed: () => context.go(AppRoutes.academyList),
            ),
          NotificationBellIcon(
            onTap: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'إعدادات الحساب',
            onPressed: () => context.push(AppRoutes.accountSettings),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: AppStrings.logout,
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorWidget(
          onRetry: () {
            final u = ref.read(authStateProvider).valueOrNull?.user;
            ref.read(dashboardProvider.notifier).refresh(
                  academyId: isSuperAdmin ? _selectedAcademyId : u?.academyId,
                );
          },
        ),
        data: (dashState) => RefreshIndicator(
          onRefresh: () {
            final u = ref.read(authStateProvider).valueOrNull?.user;
            return ref.read(dashboardProvider.notifier).refresh(
                  academyId: isSuperAdmin ? _selectedAcademyId : u?.academyId,
                );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                _WelcomeCard(userName: user?.name ?? ''),
                Gap(16.h),

                // Recent notifications widget
                RecentNotificationsWidget(
                  onViewAll: () => context.push(AppRoutes.notifications),
                ),
                Gap(20.h),

                // Quick actions for academy_admin (not admin)
                if (!isSuperAdmin && user?.isAcademyAdmin == true && user?.academyId != null) ...[
                  const _SectionTitle(title: 'الإجراءات السريعة'),
                  Gap(8.h),
                  _QuickActionsGrid(academyId: user!.academyId!),
                  Gap(20.h),
                ],

                // Stats cards grid
                const _SectionTitle(title: 'الإحصائيات العامة'),
                Gap(8.h),
                _StatsGrid(stats: dashState.stats, currencyLabel: currencyLabel),
                Gap(20.h),

                // Sports section — only for multi-sport academies
                if (currentAcademy != null &&
                    currentAcademy.isMultiSport &&
                    currentAcademyId != null) ...[
                  const _SectionTitle(title: 'الرياضات'),
                  Gap(8.h),
                  _SportsGrid(
                    academyId: currentAcademyId,
                    sports: currentAcademy.sports,
                    currencyLabel: currencyLabel,
                  ),
                  Gap(20.h),
                ],

                // Revenue chart
                const _SectionTitle(title: AppStrings.revenueByMonth),
                Gap(8.h),
                _RevenueChart(
                    data: dashState.revenueByMonth,
                    currencyLabel: currencyLabel),
                Gap(20.h),

                // Subscriptions pie chart
                const _SectionTitle(title: AppStrings.subscriptionDistribution),
                Gap(8.h),
                _SubscriptionsPieChart(data: dashState.subscriptionsByType),
                Gap(20.h),

                // Players by birth year
                const _SectionTitle(title: AppStrings.playersByBirthYear),
                Gap(8.h),
                _PlayersByBirthYearChart(data: dashState.playersByBirthYear),
                Gap(20.h),

                // Evaluation distribution
                const _SectionTitle(title: AppStrings.evaluationDistribution),
                Gap(8.h),
                _EvaluationDistributionChart(data: dashState.evaluationDistribution),
                Gap(20.h),

                // Recent activities
                const _SectionTitle(title: AppStrings.recentActivities),
                Gap(8.h),
                _RecentActivitiesList(
                    activities: dashState.recentActivities),
                Gap(24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions Grid (academy_admin only) ─────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final String academyId;
  const _QuickActionsGrid({required this.academyId});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickActionItem(
        icon: Icons.sports_basketball_outlined,
        label: AppStrings.players,
        color: AppColors.primary,
        onTap: () => context.push(
          AppRoutes.playersList.replaceFirst(':id', academyId),
        ),
      ),
      _QuickActionItem(
        icon: Icons.card_membership_outlined,
        label: AppStrings.subscriptions,
        color: AppColors.secondary,
        onTap: () => context.push(
          AppRoutes.playersList.replaceFirst(':id', academyId),
        ),
      ),
      _QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: AppStrings.reports,
        color: AppColors.success,
        onTap: () => context.push(AppRoutes.reports),
      ),
      _QuickActionItem(
        icon: Icons.qr_code_scanner,
        label: 'الحضور والانصراف',
        color: AppColors.primaryDark,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AttendanceHubScreen(academyId: academyId),
          ),
        ),
      ),
      _QuickActionItem(
        icon: Icons.badge_outlined,
        label: 'الإدارة والموظفين',
        color: AppColors.secondary,
        onTap: () => context.push(
          AppRoutes.staffList.replaceFirst(':id', academyId),
        ),
      ),
      _QuickActionItem(
        icon: Icons.payments_outlined,
        label: 'الرواتب',
        color: AppColors.success,
        onTap: () => context.push(
          AppRoutes.payrollList.replaceFirst(':id', academyId),
        ),
      ),
      _QuickActionItem(
        icon: Icons.receipt_long_outlined,
        label: 'المصروفات',
        color: AppColors.error,
        onTap: () => context.push(
          AppRoutes.expensesList.replaceFirst(':id', academyId),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.1,
      children: items,
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            Gap(8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sports Grid (multi-sport academies) ─────────────────────────────────────

class _SportsGrid extends StatelessWidget {
  final String academyId;
  final List<String> sports;
  final String currencyLabel;

  const _SportsGrid({
    required this.academyId,
    required this.sports,
    required this.currencyLabel,
  });

  static const _icons = [
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.sports_volleyball,
    Icons.sports_handball,
    Icons.pool,
    Icons.sports_martial_arts,
    Icons.sports,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 2.4,
      ),
      itemCount: sports.length,
      itemBuilder: (_, i) {
        final sport = sports[i];
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SportDetailScreen(
                academyId: academyId,
                sport: sport,
                currencyLabel: currencyLabel,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icons[i % _icons.length],
                    color: AppColors.primary,
                    size: 20.r,
                  ),
                ),
                Gap(10.w),
                Expanded(
                  child: Text(
                    sport,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_left,
                    size: 20.sp, color: AppColors.grey300),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Welcome Card ────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final String userName;
  const _WelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_basketball,
              color: AppColors.primary,
              size: 28.r,
            ),
          ),
          Gap(12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، $userName',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppStrings.dashboard,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        Gap(8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final DashboardStatsEntity? stats;
  final String currencyLabel;
  const _StatsGrid({required this.stats, required this.currencyLabel});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final cards = [
      _StatCardData(
        label: AppStrings.totalPlayers,
        value: '${s?.totalPlayers ?? 0}',
        icon: Icons.group,
        color: AppColors.secondary,
        bg: AppColors.secondaryContainer,
      ),
      _StatCardData(
        label: AppStrings.activePlayers,
        value: '${s?.activePlayers ?? 0}',
        icon: Icons.sports_basketball,
        color: AppColors.success,
        bg: AppColors.successLight,
      ),
      _StatCardData(
        label: AppStrings.activeSubscriptions,
        value: '${s?.activeSubscriptions ?? 0}',
        icon: Icons.card_membership,
        color: AppColors.primary,
        bg: AppColors.primaryContainer,
      ),
      _StatCardData(
        label: AppStrings.expiredSubscriptions,
        value: '${s?.expiredSubscriptions ?? 0}',
        icon: Icons.event_busy,
        color: AppColors.error,
        bg: AppColors.errorLight,
      ),
      _StatCardData(
        label: AppStrings.totalRevenue,
        value: _formatCurrency(s?.totalRevenue ?? 0),
        icon: Icons.payments_outlined,
        color: AppColors.success,
        bg: AppColors.successLight,
      ),
      _StatCardData(
        label: AppStrings.monthlyRevenue,
        value: _formatCurrency(s?.currentMonthRevenue ?? 0),
        icon: Icons.trending_up,
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFEFF6FF),
      ),
      _StatCardData(
        label: 'اشتراكات جديدة',
        value: '${s?.newSubscriptionsCount ?? 0}',
        icon: Icons.add_card,
        color: AppColors.primary,
        bg: AppColors.primaryContainer,
      ),
      _StatCardData(
        label: 'تجديدات',
        value: '${s?.renewalsCount ?? 0}',
        icon: Icons.refresh,
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFEFF6FF),
      ),
      _StatCardData(
        label: 'متوسط التقييم',
        value: '${(s?.averageEvaluationScore ?? 0).toStringAsFixed(1)} ${AppStrings.outOf10}',
        icon: Icons.star_outline,
        color: AppColors.warning,
        bg: AppColors.warningLight,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _StatCard(data: cards[i]),
    );
  }

  String _formatCurrency(double amount) {
    final formatted = NumberFormat('#,##0', 'ar').format(amount.toInt());
    return '$formatted $currencyLabel';
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: data.bg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(data.icon, color: data.color, size: 18.r),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.grey500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Revenue Chart ────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final List<RevenueByMonthEntity> data;
  final String currencyLabel;
  const _RevenueChart({required this.data, required this.currencyLabel});

  static const _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _monthLabel(String monthStr) {
    final parts = monthStr.split('-');
    if (parts.length >= 2) {
      final m = int.tryParse(parts[1]) ?? 1;
      return _arabicMonths[(m - 1).clamp(0, 11)];
    }
    return monthStr;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: data.isEmpty
          ? _NoDataWidget()
          : Column(
              children: [
                SizedBox(
                  height: 200.h,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()} $currencyLabel',
                              TextStyle(
                                color: AppColors.white,
                                fontSize: 11.sp,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40.w,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: AppColors.grey500,
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28.h,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  _monthLabel(data[idx].month),
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: AppColors.grey200,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.revenue,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 14.w,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4.r),
                                topRight: Radius.circular(4.r),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Subscriptions Pie Chart ─────────────────────────────────────────────────

class _SubscriptionsPieChart extends StatelessWidget {
  final SubscriptionsByTypeEntity? data;
  const _SubscriptionsPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d == null || d.total == 0) {
      return _ChartCard(child: _NoDataWidget());
    }

    return _ChartCard(
      child: Row(
        children: [
          SizedBox(
            width: 160.w,
            height: 160.h,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35.r,
                sections: [
                  PieChartSectionData(
                    value: d.newSubscription.toDouble(),
                    color: AppColors.primary,
                    title: '${d.newSubscription}',
                    radius: 55.r,
                    titleStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: d.renewal.toDouble(),
                    color: AppColors.secondary,
                    title: '${d.renewal}',
                    radius: 55.r,
                    titleStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإجمالي: ${d.total}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                Gap(12.h),
                _LegendItem(color: AppColors.primary, label: 'اشتراك جديد', count: d.newSubscription),
                Gap(8.h),
                _LegendItem(color: AppColors.secondary, label: 'تجديد', count: d.renewal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Gap(6.w),
        Text(
          '$label ($count)',
          style: TextStyle(fontSize: 12.sp, color: AppColors.grey700),
        ),
      ],
    );
  }
}

// ─── Players by Birth Year Chart ─────────────────────────────────────────────

class _PlayersByBirthYearChart extends StatelessWidget {
  final List<PlayersByBirthYearEntity> data;
  const _PlayersByBirthYearChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _ChartCard(child: _NoDataWidget());
    }

    return _ChartCard(
      child: SizedBox(
        height: 200.h,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${data[groupIndex].year}: ${rod.toY.toInt()} لاعب',
                    TextStyle(color: AppColors.white, fontSize: 11.sp),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30.w,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}',
                    style: TextStyle(fontSize: 9.sp, color: AppColors.grey500),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24.h,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                    return Text(
                      '${data[idx].year}',
                      style: TextStyle(fontSize: 9.sp, color: AppColors.grey500),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => const FlLine(color: AppColors.grey200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.count.toDouble(),
                    color: AppColors.secondary,
                    width: 16.w,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.r),
                      topRight: Radius.circular(4.r),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Evaluation Distribution Chart ───────────────────────────────────────────

class _EvaluationDistributionChart extends StatelessWidget {
  final EvaluationDistributionEntity? data;
  const _EvaluationDistributionChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d == null || d.total == 0) {
      return _ChartCard(child: _NoDataWidget());
    }

    return _ChartCard(
      child: Row(
        children: [
          SizedBox(
            width: 160.w,
            height: 160.h,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30.r,
                sections: [
                  if (d.excellent > 0)
                    PieChartSectionData(
                      value: d.excellent.toDouble(),
                      color: AppColors.success,
                      title: '${d.excellent}',
                      radius: 55.r,
                      titleStyle: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  if (d.good > 0)
                    PieChartSectionData(
                      value: d.good.toDouble(),
                      color: AppColors.warning,
                      title: '${d.good}',
                      radius: 55.r,
                      titleStyle: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  if (d.needsImprovement > 0)
                    PieChartSectionData(
                      value: d.needsImprovement.toDouble(),
                      color: AppColors.error,
                      title: '${d.needsImprovement}',
                      radius: 55.r,
                      titleStyle: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإجمالي: ${d.total}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                Gap(12.h),
                _LegendItem(color: AppColors.success, label: 'ممتاز (≥8)', count: d.excellent),
                Gap(6.h),
                _LegendItem(color: AppColors.warning, label: 'جيد (6-8)', count: d.good),
                Gap(6.h),
                _LegendItem(color: AppColors.error, label: 'يحتاج تحسين (<6)', count: d.needsImprovement),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activities ────────────────────────────────────────────────────────

class _RecentActivitiesList extends StatelessWidget {
  final RecentActivitiesEntity? activities;
  const _RecentActivitiesList({required this.activities});

  @override
  Widget build(BuildContext context) {
    final all = activities?.all.take(15).toList() ?? [];

    if (all.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: _NoDataWidget()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: all.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.grey100,
          indent: 16.w,
          endIndent: 16.w,
        ),
        itemBuilder: (_, i) => _ActivityTile(activity: all[i]),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final RecentActivityEntity activity;
  const _ActivityTile({required this.activity});

  // (icon, color, background) حسب نوع العنصر.
  (IconData, Color, Color) get _visual {
    switch (activity.entityType) {
      case 'PLAYER':
        return (Icons.person_outline, AppColors.secondary, AppColors.secondaryContainer);
      case 'SUBSCRIPTION':
        return (Icons.card_membership_outlined, AppColors.primary, AppColors.primaryContainer);
      case 'EVALUATION':
        return (Icons.assessment_outlined, AppColors.warning, AppColors.warningLight);
      case 'ATTENDANCE':
        return (Icons.qr_code_scanner, const Color(0xFF2D9748), AppColors.successLight);
      case 'USER':
        return (Icons.manage_accounts_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF));
      case 'ACADEMY':
        return (Icons.business_outlined, AppColors.secondary, AppColors.secondaryContainer);
      default:
        return (Icons.history, AppColors.grey500, AppColors.grey100);
    }
  }

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy', 'ar').format(dt);

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = _visual;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20.r),
      ),
      title: Text(
        activity.sentence,
        style: TextStyle(
            fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.grey900),
      ),
      trailing: Text(
        _formatDate(activity.createdAt),
        style: TextStyle(fontSize: 10.sp, color: AppColors.grey400),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NoDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, color: AppColors.grey300, size: 32.r),
            Gap(8.h),
            Text(
              AppStrings.noChartData,
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey400),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.r, color: AppColors.error),
          Gap(16.h),
          Text(
            AppStrings.serverError,
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey700),
          ),
          Gap(16.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
