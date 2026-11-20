import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/online_registration/online_registration_data.dart';
import 'package:basketball_academy/features/player/presentation/widgets/account_credentials_dialog.dart';
import 'package:basketball_academy/features/subscription/presentation/screens/add_subscription_screen.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// زر "طلبات التسجيل" (مع عدد الطلبات الجديدة) — في شريط شاشة اللاعبين.
class RegistrationRequestsButton extends ConsumerWidget {
  final String academyId;

  const RegistrationRequestsButton({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(onlineRegistrationSettingsProvider(academyId)).valueOrNull?.pendingCount ?? 0;
    return IconButton(
      tooltip: 'طلبات التسجيل الأونلاين',
      onPressed: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RegistrationRequestsScreen(academyId: academyId),
        ));
        ref.invalidate(onlineRegistrationSettingsProvider(academyId));
      },
      icon: Badge(
        isLabelVisible: pending > 0,
        label: Text('$pending'),
        child: const Icon(Icons.how_to_reg_outlined),
      ),
    );
  }
}

/// طلبات التسجيل الأونلاين + رابط الفورم وإعداداته.
class RegistrationRequestsScreen extends ConsumerStatefulWidget {
  final String academyId;

  const RegistrationRequestsScreen({super.key, required this.academyId});

  @override
  ConsumerState<RegistrationRequestsScreen> createState() => _RegistrationRequestsScreenState();
}

class _RegistrationRequestsScreenState extends ConsumerState<RegistrationRequestsScreen> {
  static const _statuses = ['pending', 'accepted', 'rejected'];
  static const _labels = {'pending': 'الجديدة', 'accepted': 'المقبولة', 'rejected': 'المرفوضة'};
  String _busyId = '';

  void _snack(String msg, {bool error = false, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      action: action,
    ));
  }

  void _refreshAll() {
    for (final s in _statuses) {
      ref.invalidate(registrationRequestsProvider((academyId: widget.academyId, status: s)));
    }
    ref.invalidate(onlineRegistrationSettingsProvider(widget.academyId));
  }

  Future<void> _accept(RegistrationRequestEntity r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('قبول الطلب'),
        content: Text('هيتضاف ${r.playerName} كلاعب جديد في الأكاديمية. تقدر بعدها تختار مجموعته وتضيف اشتراكه.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('قبول وإضافة')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyId = r.id);
    try {
      final result = await OnlineRegistrationApi.accept(r.id, academyId: widget.academyId);
      _refreshAll();
      if (!mounted) return;
      if (result.username != null && result.password != null) {
        await AccountCredentialsDialog.show(
          context,
          title: 'تم إضافة اللاعب — بيانات دخول البوابة',
          username: result.username!,
          password: result.password!,
          playerName: result.playerName,
          parentPhone: r.parentPhone,
          playerPhone: r.playerPhone.isEmpty ? null : r.playerPhone,
        );
      }
      _snack(
        'تم قبول ${result.playerName} وإضافته للاعبين',
        action: SnackBarAction(
          label: 'إضافة اشتراك',
          textColor: AppColors.white,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddSubscriptionScreen(
              playerId: result.playerId,
              academyId: widget.academyId,
              playerName: result.playerName,
            ),
          )),
        ),
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busyId = '');
    }
  }

  Future<void> _reject(RegistrationRequestEntity r) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(
          controller: reasonCtrl,
          maxLength: 200,
          decoration: const InputDecoration(labelText: 'السبب (اختياري)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (ok != true) return;
    setState(() => _busyId = r.id);
    try {
      await OnlineRegistrationApi.reject(r.id, reason: reason, academyId: widget.academyId);
      _refreshAll();
      _snack('تم رفض الطلب');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busyId = '');
    }
  }

  Future<void> _whatsApp(RegistrationRequestEntity r) async {
    final ok = await WhatsAppUtils.open(
      r.parentPhone,
      message: 'السلام عليكم ${r.parentName}، بخصوص طلب تسجيل ${r.playerName} في الأكاديمية',
    );
    if (!ok) _snack('تعذّر فتح واتساب', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final canManageLink = user?.isSuperAdmin == true || user?.isAcademyAdmin == true;
    final settings = ref.watch(onlineRegistrationSettingsProvider(widget.academyId));

    return DefaultTabController(
      length: _statuses.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('طلبات التسجيل'),
          centerTitle: true,
          bottom: TabBar(tabs: [for (final s in _statuses) Tab(text: _labels[s])]),
        ),
        body: Column(
          children: [
            settings.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (e, _) => const SizedBox.shrink(),
              data: (s) => _LinkCard(
                settings: s,
                canManage: canManageLink,
                onSettings: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _SettingsSheet(academyId: widget.academyId, settings: s),
                  );
                  ref.invalidate(onlineRegistrationSettingsProvider(widget.academyId));
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final s in _statuses) _list(s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(String status) {
    final q = (academyId: widget.academyId, status: status);
    final async = ref.watch(registrationRequestsProvider(q));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(registrationRequestsProvider(q).future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          Gap(80.h),
          Center(child: Text(e.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center)),
        ]),
        data: (d) {
          if (d.items.isEmpty) {
            return ListView(children: [
              Gap(80.h),
              Icon(Icons.inbox_outlined, size: 56.sp, color: AppColors.grey300),
              Gap(8.h),
              Center(
                child: Text(
                  status == 'pending' ? 'مفيش طلبات جديدة' : 'مفيش طلبات هنا',
                  style: TextStyle(color: AppColors.grey600, fontSize: 14.sp),
                ),
              ),
            ]);
          }
          return ListView.separated(
            padding: EdgeInsets.all(14.r),
            itemCount: d.items.length,
            separatorBuilder: (_, __) => Gap(10.h),
            itemBuilder: (_, i) => _card(d.items[i]),
          );
        },
      ),
    );
  }

  Widget _card(RegistrationRequestEntity r) {
    final df = DateFormat('dd/MM/yyyy', 'ar');
    final busy = _busyId == r.id;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.playerName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
              ),
              Text(df.format(r.createdAt), style: TextStyle(fontSize: 11.sp, color: AppColors.grey500)),
            ],
          ),
          Gap(4.h),
          Text(
            [
              if (r.age != null) '${r.age} سنة',
              if (r.sport.isNotEmpty) r.sport,
            ].join(' • '),
            style: TextStyle(fontSize: 12.sp, color: AppColors.grey700),
          ),
          Gap(4.h),
          Text('${r.parentRelationship}: ${r.parentName} • ${r.parentPhone}',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey700)),
          if (r.notes.isNotEmpty) ...[
            Gap(4.h),
            Text('ملاحظات: ${r.notes}', style: TextStyle(fontSize: 12.sp, color: AppColors.grey600)),
          ],
          if (r.status == 'accepted') ...[
            Gap(6.h),
            Text('✅ اتضاف كلاعب${r.handledByName.isNotEmpty ? ' — بواسطة ${r.handledByName}' : ''}',
                style: TextStyle(fontSize: 12.sp, color: AppColors.success, fontWeight: FontWeight.w700)),
          ],
          if (r.status == 'rejected') ...[
            Gap(6.h),
            Text('مرفوض${r.rejectReason.isNotEmpty ? ': ${r.rejectReason}' : ''}',
                style: TextStyle(fontSize: 12.sp, color: AppColors.error, fontWeight: FontWeight.w700)),
          ],
          Gap(8.h),
          Row(
            children: [
              if (r.status == 'pending') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : () => _accept(r),
                    icon: busy
                        ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('قبول'),
                  ),
                ),
                Gap(8.w),
                OutlinedButton(
                  onPressed: busy ? null : () => _reject(r),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('رفض'),
                ),
                Gap(8.w),
              ],
              IconButton(
                tooltip: 'واتساب',
                onPressed: () => _whatsApp(r),
                icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// بطاقة رابط الفورم: الحالة + نسخ + مشاركة + QR + الإعدادات.
class _LinkCard extends StatelessWidget {
  final OnlineRegistrationSettings settings;
  final bool canManage;
  final VoidCallback onSettings;

  const _LinkCard({required this.settings, required this.canManage, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final on = s.enabled && s.url != null;
    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFECFDF5) : AppColors.grey100,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(on ? Icons.link : Icons.link_off, color: on ? AppColors.success : AppColors.grey500),
          Gap(8.w),
          Expanded(
            child: Text(
              on ? 'فورم التسجيل الأونلاين شغال' : 'فورم التسجيل الأونلاين مقفول',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
            ),
          ),
          if (on) ...[
            IconButton(
              tooltip: 'نسخ الرابط',
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: s.url!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
              },
            ),
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: () => Share.share('سجّل ابنك في الأكاديمية من هنا 👇\n${s.url}'),
            ),
            IconButton(
              tooltip: 'QR',
              icon: const Icon(Icons.qr_code_2, size: 22),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('امسح الكود للتسجيل'),
                  content: SizedBox(
                    width: 240,
                    height: 240,
                    child: QrImageView(data: s.url!, version: QrVersions.auto, backgroundColor: Colors.white),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
                ),
              ),
            ),
          ],
          if (canManage)
            IconButton(tooltip: 'إعدادات الفورم', icon: const Icon(Icons.settings_outlined, size: 20), onPressed: onSettings),
        ],
      ),
    );
  }
}

/// إعدادات الفورم: تشغيل/إيقاف، الرياضات، رسالة الترحيب، رابط جديد.
class _SettingsSheet extends StatefulWidget {
  final String academyId;
  final OnlineRegistrationSettings settings;

  const _SettingsSheet({required this.academyId, required this.settings});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late bool _enabled = widget.settings.enabled;
  late final Set<String> _sports = {...widget.settings.sports};
  late final _message = TextEditingController(text: widget.settings.welcomeMessage);
  bool _saving = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _save({bool regenerate = false}) async {
    setState(() => _saving = true);
    try {
      await OnlineRegistrationApi.updateSettings(
        widget.academyId,
        enabled: _enabled,
        sports: _sports.toList(),
        welcomeMessage: _message.text,
        regenerate: regenerate,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(regenerate ? 'تم إنشاء رابط جديد — الرابط القديم اتوقف' : 'تم حفظ الإعدادات'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.settings.academySports;
    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: MediaQuery.viewInsetsOf(context).bottom + 20.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إعدادات فورم التسجيل', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('استقبال طلبات أونلاين'),
              subtitle: const Text('لما يكون مقفول، الرابط بيعرض إن التسجيل غير متاح'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            if (all.length > 1) ...[
              Text('الرياضات في الفورم (من غير اختيار = كلها)', style: TextStyle(fontSize: 13.sp, color: AppColors.grey700)),
              Gap(6.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  for (final s in all)
                    FilterChip(
                      label: Text(s),
                      selected: _sports.contains(s),
                      onSelected: (v) => setState(() => v ? _sports.add(s) : _sports.remove(s)),
                    ),
                ],
              ),
              Gap(10.h),
            ],
            TextField(
              controller: _message,
              maxLength: 300,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'رسالة ترحيب أعلى الفورم (اختياري)',
                hintText: 'مثال: التمرين يوم السبت والثلاثاء — الاشتراك الشهري 500 جنيه',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            Gap(8.h),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 46.h)),
              child: const Text('حفظ'),
            ),
            if (widget.settings.url != null)
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('رابط جديد؟'),
                            content: const Text('الرابط القديم والـ QR المطبوع هيبطلوا يشتغلوا.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنشاء رابط جديد')),
                            ],
                          ),
                        );
                        if (ok == true) _save(regenerate: true);
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('إنشاء رابط جديد'),
              ),
          ],
        ),
      ),
    );
  }
}
