import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/features/academy/domain/entities/academy_entity.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/academy/presentation/screens/add_academy_screen.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class AcademyListScreen extends ConsumerWidget {
  const AcademyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final academiesAsync = ref.watch(academiesProvider);
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSuperAdmin
              ? AppStrings.academies
              : (authState?.user?.academyName ?? AppStrings.academy),
        ),
        actions: [
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
      body: academiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.read(academiesProvider.notifier).refresh(),
        ),
        data: (academies) => academies.isEmpty
            ? _EmptyState(isSuperAdmin: isSuperAdmin)
            : RefreshIndicator(
                onRefresh: () => ref.read(academiesProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: academies.length,
                  separatorBuilder: (_, __) => Gap(12.h),
                  itemBuilder: (context, index) {
                    return _AcademyCard(
                      academy: academies[index],
                      onTap: () => context.push(
                        AppRoutes.academyDetail.replaceFirst(
                          ':id',
                          academies[index].id,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddAcademyScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addAcademy),
            )
          : null,
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

class _EmptyState extends StatelessWidget {
  final bool isSuperAdmin;
  const _EmptyState({required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_basketball_outlined,
              size: 80.sp, color: AppColors.grey300),
          Gap(16.h),
          Text(
            'لا توجد أكاديميات بعد',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: AppColors.grey500),
          ),
          if (isSuperAdmin) ...[
            Gap(8.h),
            Text(
              'أضف أول أكاديمية للبدء',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.grey400),
            ),
          ],
        ],
      ),
    );
  }
}

class _AcademyCard extends StatelessWidget {
  final AcademyEntity academy;
  final VoidCallback onTap;

  const _AcademyCard({required this.academy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              // Logo
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: academy.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          academy.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultLogo(),
                        ),
                      )
                    : _defaultLogo(),
              ),
              Gap(12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      academy.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(4.h),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      text: academy.phone,
                    ),
                    Gap(2.h),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: academy.address,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (academy.playerCount != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${academy.playerCount} لاعب',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Gap(8.h),
                  Icon(Icons.chevron_left,
                      color: AppColors.grey400, size: 20.sp),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultLogo() {
    return Icon(Icons.sports_basketball,
        color: AppColors.primary, size: 28.sp);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13.sp, color: AppColors.grey500),
        Gap(4.w),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
