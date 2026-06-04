import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'أكاديمية كرة السلة',
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
  }
}
