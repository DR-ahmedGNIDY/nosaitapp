import 'dart:async';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/core/constants/sports_constants.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/attendance/presentation/screens/attendance_hub_screen.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/notification/presentation/screens/notifications_screen.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/presentation/providers/player_provider.dart';
import 'package:basketball_academy/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:basketball_academy/features/player/presentation/screens/add_player_screen.dart';
import 'package:basketball_academy/features/player/presentation/screens/player_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class PlayersListScreen extends ConsumerStatefulWidget {
  final String academyId;

  const PlayersListScreen({super.key, required this.academyId});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playersProvider.notifier).filterByAcademy(widget.academyId);
    });
  }

  @override
  void didUpdateWidget(PlayersListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When super_admin navigates from one academy to another, reload players
    if (oldWidget.academyId != widget.academyId) {
      _searchController.clear();
      _debounce?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(playersProvider.notifier).filterByAcademy(widget.academyId);
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(playersProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Rebuild so the clear (X) icon reflects the field's current state.
    setState(() {});
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      // Field cleared — drop the filter immediately and show all players.
      _debounce = Timer(const Duration(milliseconds: 200), () {
        ref.read(playersProvider.notifier).clearSearch();
      });
    } else {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        ref.read(playersProvider.notifier).search(value.trim());
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    ref.read(playersProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final isAcademyLevel = authState?.user?.isAcademyLevel ?? false;
    final statusMap = ref
        .watch(academyPlayerStatusMapProvider(widget.academyId))
        .valueOrNull ??
        {};

    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final academySports = academy?.sports ?? const <String>[];

    final canAdd = isSuperAdmin ||
        (isAcademyLevel &&
            authState?.user?.academyId == widget.academyId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.players),
            playersAsync.whenOrNull(
              data: (state) => state.total > 0
                  ? Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${state.total}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ) ??
                const SizedBox.shrink(),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'الحضور والانصراف',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AttendanceHubScreen(academyId: widget.academyId),
              ),
            ),
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppStrings.searchPlayers,
                prefixIcon: Icon(Icons.search,
                    color: AppColors.grey400, size: 20.sp),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: AppColors.grey400, size: 18.sp),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Filter row - sport chips (multi-sport academies only)
          if (isMultiSport)
            playersAsync.whenOrNull(
                  data: (state) => _ChipFilterRow(
                    allLabel: 'الكل',
                    options: academySports,
                    selected: state.sportFilter,
                    onSelected: (sport) => ref
                        .read(playersProvider.notifier)
                        .filterBySport(sport),
                  ),
                ) ??
                const SizedBox.shrink(),

          // Filter row - attendance day chips
          playersAsync.whenOrNull(
                data: (state) => _ChipFilterRow(
                  allLabel: 'كل الأيام',
                  options: SportsConstants.weekDays,
                  selected: state.attendanceDayFilter,
                  onSelected: (day) => ref
                      .read(playersProvider.notifier)
                      .filterByAttendanceDay(day),
                ),
              ) ??
              const SizedBox.shrink(),

          // Filter row - birth year chips
          playersAsync.whenOrNull(
                data: (state) => _BirthYearFilterRow(
                  selectedYear: state.birthYearFilter,
                  onYearSelected: (year) {
                    ref
                        .read(playersProvider.notifier)
                        .filterByBirthYear(year);
                  },
                ),
              ) ??
              const SizedBox.shrink(),

          // Search results count
          playersAsync.whenOrNull(
                data: (state) {
                  if (state.search != null && state.search!.isNotEmpty) {
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'نتائج البحث: ${state.total}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ) ??
              const SizedBox.shrink(),

          // Players list
          Expanded(
            child: playersAsync.when(
              loading: () => const _LoadingState(),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () =>
                    ref.read(playersProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.players.isEmpty) {
                  return _EmptyState(
                    hasSearch: state.search != null &&
                        state.search!.isNotEmpty,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(playersProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: state.players.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => Gap(10.h),
                    itemBuilder: (context, index) {
                      if (index == state.players.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final player = state.players[index];
                      return _PlayerCard(
                        player: player,
                        subscriptionStatus:
                            statusMap[player.id] ?? 'جديد',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerDetailScreen(
                                playerId: player.id,
                                academyId: widget.academyId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddPlayerScreen(academyId: widget.academyId),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text(AppStrings.addPlayer),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Generic horizontal chip filter row (sports / attendance days)
// ---------------------------------------------------------------------------

class _ChipFilterRow extends StatelessWidget {
  final String allLabel;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _ChipFilterRow({
    required this.allLabel,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: options.length + 1,
        separatorBuilder: (_, __) => Gap(8.w),
        itemBuilder: (context, index) {
          // First chip = "All"
          if (index == 0) {
            final isSelected = selected == null;
            return FilterChip(
              label: Text(
                allLabel,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? AppColors.white : AppColors.grey700,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(null),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.grey200,
              ),
              checkmarkColor: AppColors.white,
            );
          }
          final option = options[index - 1];
          final isSelected = selected == option;
          return FilterChip(
            label: Text(
              option,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? AppColors.white : AppColors.grey700,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(isSelected ? null : option),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.grey200,
            ),
            checkmarkColor: AppColors.white,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Birth year filter row
// ---------------------------------------------------------------------------

class _BirthYearFilterRow extends StatelessWidget {
  final int? selectedYear;
  final ValueChanged<int?> onYearSelected;

  const _BirthYearFilterRow({
    required this.selectedYear,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(21, (i) => currentYear - i);

    return SizedBox(
      height: 48.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: years.length + 1,
        separatorBuilder: (_, __) => Gap(8.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Clear filter button
            if (selectedYear != null) {
              return ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14.sp, color: AppColors.error),
                    Gap(4.w),
                    Text(
                      'مسح الفلتر',
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.error),
                    ),
                  ],
                ),
                backgroundColor: AppColors.errorLight,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                onPressed: () => onYearSelected(null),
              );
            }
            return const SizedBox.shrink();
          }
          final year = years[index - 1];
          final isSelected = selectedYear == year;
          return FilterChip(
            label: Text(
              '$year',
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? AppColors.white : AppColors.grey700,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (_) =>
                onYearSelected(isSelected ? null : year),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.grey200,
            ),
            checkmarkColor: AppColors.white,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player card
// ---------------------------------------------------------------------------

class _PlayerCard extends ConsumerWidget {
  final PlayerEntity player;
  final String subscriptionStatus;
  final VoidCallback onTap;

  const _PlayerCard({
    required this.player,
    required this.subscriptionStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              // Player photo
              _PlayerAvatar(imageUrl: player.imageUrl, size: 54.r),
              Gap(12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(Icons.cake_outlined,
                            size: 14.sp, color: AppColors.grey400),
                        Gap(4.w),
                        Text(
                          '${player.age} ${AppStrings.yearsOld}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500),
                        ),
                        Gap(12.w),
                        Icon(Icons.phone_outlined,
                            size: 14.sp, color: AppColors.grey400),
                        Gap(4.w),
                        Expanded(
                          child: Text(
                            player.parentPhone,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Gap(8.w),
              // Player code + subscription status badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      player.playerCode,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Gap(4.h),
                  _MiniStatusBadge(status: subscriptionStatus),
                  Gap(2.h),
                  Icon(Icons.chevron_left,
                      size: 20.sp, color: AppColors.grey300),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player avatar
// ---------------------------------------------------------------------------

class _PlayerAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _PlayerAvatar({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryContainer,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: size * 0.5,
                ),
              ),
            )
          : Icon(
              Icons.person,
              color: AppColors.primary,
              size: size * 0.5,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: 6,
      separatorBuilder: (_, __) => Gap(10.h),
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            _shimmerBox(54.r, 54.r, circular: true),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimmerBox(12.h, 140.w),
                  Gap(8.h),
                  _shimmerBox(10.h, 100.w),
                ],
              ),
            ),
            _shimmerBox(28.h, 60.w),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {bool circular = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: circular
                ? BorderRadius.circular(height / 2)
                : BorderRadius.circular(6.r),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_outlined
                : Icons.sports_basketball_outlined,
            size: 80.sp,
            color: AppColors.grey300,
          ),
          Gap(16.h),
          Text(
            hasSearch ? 'لا توجد نتائج للبحث' : AppStrings.noPlayers,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.grey500),
          ),
          Gap(8.h),
          Text(
            hasSearch
                ? 'جرّب كلمة بحث مختلفة'
                : 'أضف أول لاعب للأكاديمية',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            Gap(16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gap(16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini Status Badge — compact version for player list
// ---------------------------------------------------------------------------

class _MiniStatusBadge extends StatelessWidget {
  final String status;
  const _MiniStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'نشط':
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case 'منتهي':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
      default: // جديد
        bg = AppColors.primaryContainer;
        fg = AppColors.primaryDark;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10.sp,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
