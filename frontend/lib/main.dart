import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initDependencies();

  runApp(
    const ProviderScope(
      child: BasketballAcademyApp(),
    ),
  );
}

class BasketballAcademyApp extends ConsumerWidget {
  const BasketballAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    final app = ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'nosait academy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: router,
          builder: (context, widget) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: widget ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );

    // الويب فقط: الشاشات مصمَّمة لعرض موبايل (390px)؛ على نوافذ أوسع
    // (تابلت/لابتوب/ديسكتوب) نُحاصر المحتوى بعرض ثابت ونمركزه بدل تمديد
    // كل القياسات (ScreenUtil .w/.h/.sp) بنسبة عرض النافذة الحقيقي، وهو ما
    // كان يُكسِّر كل الشاشات (نصوص وأيقونات وحشو ضخمة بشكل غير متناسب).
    // لا يؤثر هذا على Android أو Windows لأنه محصور بـ kIsWeb.
    return kIsWeb ? _WebResponsiveClamp(child: app) : app;
  }
}

class _WebResponsiveClamp extends StatelessWidget {
  final Widget child;
  const _WebResponsiveClamp({required this.child});

  static const double _maxContentWidth = 480;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= _maxContentWidth || !constraints.hasBoundedWidth) {
          return child;
        }
        final mq = MediaQuery.of(context);
        return ColoredBox(
          color: AppColors.grey200,
          child: Center(
            child: SizedBox(
              width: _maxContentWidth,
              height: constraints.maxHeight,
              child: MediaQuery(
                data: mq.copyWith(
                  size: Size(_maxContentWidth, constraints.maxHeight),
                ),
                child: ClipRect(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
