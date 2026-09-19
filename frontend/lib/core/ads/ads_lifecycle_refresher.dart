import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// يلتقط تغيّر اشتراك الأكاديمية أثناء استخدام التطبيق (تجديد أو انتهاء أو
/// تعليق من إدارة المنصة) بإعادة جلب /auth/me **بصمت** عند عودة التطبيق
/// للمقدمة. لا يعرض شيئاً — يغلّف الشجرة فقط.
///
/// إعادة الجلب صامتة عمداً (لا حالة loading) حتى لا يفسّرها GoRouter كخروج
/// من الجلسة.
class AdsLifecycleRefresher extends ConsumerStatefulWidget {
  final Widget child;

  const AdsLifecycleRefresher({super.key, required this.child});

  @override
  ConsumerState<AdsLifecycleRefresher> createState() =>
      _AdsLifecycleRefresherState();
}

class _AdsLifecycleRefresherState extends ConsumerState<AdsLifecycleRefresher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authStateProvider.notifier).refreshSilently();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
