import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/ai_assistant/ai_assistant_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// المساعد الذكي لمدير الأكاديمية (المرحلة 1: أسئلة وقراءة فقط).
/// ميزة مدفوعة بحد رسائل يومي — متاحة على نسخة الويب فقط حالياً.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  static const _suggestions = [
    'ملخص الأكاديمية النهارده',
    'مين عليه فلوس؟',
    'مين اشتراكه بيخلص الأسبوع ده؟',
    'مين غاب النهارده؟',
    'إيرادات ومصروفات الشهر ده',
    'الماتشات الجاية',
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  AiStatus? _status;
  List<AiMessage> _messages = [];
  Object? _loadError;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final status = await AiAssistantApi.status();
      final messages = status.enabled ? await AiAssistantApi.conversation() : <AiMessage>[];
      if (!mounted) return;
      setState(() {
        _status = status;
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  String _err(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    final pending = AiMessage(id: 'local-${DateTime.now().microsecondsSinceEpoch}', role: 'user', content: text);
    setState(() {
      _messages = [..._messages, pending];
      _sending = true;
      if (preset == null) _input.clear();
    });
    try {
      final r = await AiAssistantApi.send(text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, r.reply];
        _status = _status?.withUsage(r.used, r.limit, r.remaining);
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      // الرسالة لم تُحفظ على السيرفر ⇒ نشيلها ونرجّع النص للكتابة.
      setState(() {
        _messages = _messages.where((m) => m.id != pending.id).toList();
        _sending = false;
        if (preset == null && _input.text.isEmpty) _input.text = text;
      });
      _snack(_err(e), error: true);
      // تحديث العداد (مثلاً بعد الوصول للحد).
      AiAssistantApi.status().then((s) {
        if (mounted) setState(() => _status = s);
      }).catchError((_) {});
    }
    _focus.requestFocus();
  }

  Future<void> _newChat() async {
    if (_messages.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('محادثة جديدة'),
        content: const Text('هتتمسح المحادثة الحالية. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ابدأ من جديد')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AiAssistantApi.reset();
      if (mounted) setState(() => _messages = []);
    } catch (e) {
      if (mounted) _snack(_err(e), error: true);
    }
  }

  Future<void> _report(AiMessage m) async {
    final reasonCtrl = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إبلاغ عن رد'),
        content: TextField(
          controller: reasonCtrl,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'إيه المشكلة في الرد؟ (رقم غلط، رد غير مناسب...)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إرسال البلاغ')),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (send != true) return;
    try {
      await AiAssistantApi.report(m.id, reason);
      if (!mounted) return;
      setState(() => _messages = [for (final x in _messages) x.id == m.id ? x.copyWith(reported: true) : x]);
      _snack('شكراً، تم إرسال البلاغ');
    } catch (e) {
      if (mounted) _snack(_err(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المساعد الذكي'),
            if (s != null && s.enabled)
              Text(
                'متبقي ${s.remainingToday} من ${s.dailyLimit} رسالة النهارده',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        actions: [
          if (s != null && s.enabled)
            IconButton(
              tooltip: 'محادثة جديدة',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: _sending ? null : _newChat,
            ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            Gap(10.h),
            Text(_err(_loadError!), textAlign: TextAlign.center),
            Gap(12.h),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ]),
        ),
      );
    }
    final s = _status!;
    if (!s.enabled) return _locked(s);

    return Column(children: [
      Expanded(
        child: _messages.isEmpty && !_sending
            ? _welcome()
            : ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_sending && i == 0) return const _TypingBubble();
                  final m = _messages[_messages.length - 1 - (i - (_sending ? 1 : 0))];
                  return _Bubble(message: m, onReport: m.isUser || m.reported ? null : () => _report(m));
                },
              ),
      ),
      _composer(s),
    ]);
  }

  Widget _locked(AiStatus s) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 44.sp, color: AppColors.primary),
          ),
          Gap(16.h),
          Text('المساعد الذكي',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900)),
          Gap(8.h),
          Text(
            s.blockedBySubscription
                ? 'المساعد متوقف لأن اشتراك الأكاديمية في المنصة منتهي أو موقوف. جدّد الاشتراك علشان يرجع يشتغل.'
                : 'اسأل عن أي حاجة في أكاديميتك بالعربي: مين عليه فلوس، مين غاب، الإيرادات، الاشتراكات اللي بتخلص… والمساعد يرد عليك من بياناتك الحقيقية.\n\nدي ميزة مدفوعة — تواصل مع إدارة نوسيت لتفعيلها.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey700, height: 1.6),
          ),
          Gap(18.h),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.systemSubscription),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('اشتراك النظام والتواصل'),
          ),
        ]),
      ),
    );
  }

  Widget _welcome() {
    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        Gap(20.h),
        Icon(Icons.auto_awesome, size: 46.sp, color: AppColors.primary),
        Gap(10.h),
        Text('أهلاً! أنا مساعد أكاديميتك',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
        Gap(6.h),
        Text(
          'اسألني عن اللاعبين والاشتراكات والمديونيات والحضور والإيرادات والماتشات.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: AppColors.grey600),
        ),
        Gap(18.h),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final q in _suggestions)
              ActionChip(
                avatar: Icon(Icons.chat_bubble_outline, size: 16.sp, color: AppColors.primary),
                label: Text(q),
                onPressed: () => _send(q),
              ),
          ],
        ),
      ],
    );
  }

  Widget _composer(AiStatus s) {
    final out = s.remainingToday <= 0;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 6.h),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.grey200)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              // Enter = إرسال (textInputAction.send ⇒ onSubmitted حتى مع عدة أسطر).
              child: TextField(
                controller: _input,
                focusNode: _focus,
                enabled: !out,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: out ? 'خلّصت رسائل النهارده — يتجدد الحد بكره' : 'اكتب سؤالك…',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22.r),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                ),
              ),
            ),
            Gap(6.w),
            IconButton.filled(
              tooltip: 'إرسال',
              onPressed: _sending || out ? null : _send,
              icon: _sending
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ]),
          Gap(4.h),
          Text(
            'الردود من الذكاء الاصطناعي وممكن يكون فيها أخطاء — راجع الأرقام المهمة من شاشاتها.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5.sp, color: AppColors.grey500),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final AiMessage message;
  final VoidCallback? onReport;
  const _Bubble({required this.message, this.onReport});

  // حماية لو الموديل كتب Markdown رغم التعليمات.
  String get _text => message.content.replaceAll('**', '').replaceAll(RegExp(r'^#+\s*', multiLine: true), '');

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    final maxW = MediaQuery.sizeOf(context).width * 0.82;
    return Align(
      // RTL: start = يمين. رسائل المدير يمين، والمساعد يسار.
      alignment: user ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW > 640 ? 640 : maxW),
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, onReport != null || message.reported ? 2.h : 10.h),
        decoration: BoxDecoration(
          color: user ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: user ? null : Border.all(color: AppColors.grey200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          SelectableText(
            _text,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.55,
              color: user ? AppColors.white : AppColors.grey900,
            ),
          ),
          if (!user)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: message.reported
                  ? Padding(
                      padding: EdgeInsets.only(top: 4.h, bottom: 6.h),
                      child: Text('تم الإبلاغ', style: TextStyle(fontSize: 10.5.sp, color: AppColors.grey500)),
                    )
                  : IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'إبلاغ عن الرد',
                      icon: Icon(Icons.flag_outlined, size: 16.sp, color: AppColors.grey400),
                      onPressed: onReport,
                    ),
            ),
        ]),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 14.r, height: 14.r, child: const CircularProgressIndicator(strokeWidth: 2)),
          Gap(8.w),
          Text('بيدوّر في بيانات الأكاديمية…', style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey600)),
        ]),
      ),
    );
  }
}
