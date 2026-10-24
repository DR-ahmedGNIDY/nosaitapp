import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/matches/data/match_model.dart';
import 'package:basketball_academy/features/matches/presentation/providers/matches_providers.dart';
import 'package:basketball_academy/features/matches/presentation/screens/select_match_players_screen.dart';
import 'package:basketball_academy/features/matches/presentation/widgets/match_settings_section.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// تفاصيل المباراة: معلومات أساسية + قائمة اللاعبين مع إمكانية إرسال تذكير
/// واتساب فردي أو جماعي (بعد نجاح فتح واتساب فعلياً يُسجَّل التذكير في السيرفر).
class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String academyId;
  const MatchDetailScreen({super.key, required this.matchId, required this.academyId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  final Set<String> _sending = {};
  bool _sendingAll = false;

  String _reminderMessage(MatchModel match, String playerName) {
    return 'السلام عليكم،\n'
        'تذكير بموعد مباراة "${match.name}" للاعب $playerName.\n'
        '📍 المكان: ${match.location}\n'
        '📅 التاريخ: ${match.date}\n'
        '⏰ الوقت: ${match.time}\n'
        'نرجو الحضور في الموعد المحدد.';
  }

  Future<bool> _sendReminder(MatchModel match, MatchPlayer player) async {
    final message = _reminderMessage(match, player.fullName);
    final opened = await WhatsAppUtils.open(player.parentPhone, message: message);
    if (!opened) return false;
    return ref.read(matchDetailProvider(widget.matchId).notifier).logReminder(player.id);
  }

  Future<void> _sendOne(MatchModel match, MatchPlayer player) async {
    setState(() => _sending.add(player.id));
    final ok = await _sendReminder(match, player);
    if (!mounted) return;
    setState(() => _sending.remove(player.id));
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر إرسال التذكير'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _sendAll(MatchModel match, List<MatchPlayer> players) async {
    setState(() => _sendingAll = true);
    for (final player in players) {
      if (!mounted) return;
      setState(() => _sending.add(player.id));
      await _sendReminder(match, player);
      if (!mounted) return;
      setState(() => _sending.remove(player.id));
    }
    if (!mounted) return;
    setState(() => _sendingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال التذكيرات'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _addPlayers(List<String> alreadyAdded) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SelectMatchPlayersScreen(
          matchId: widget.matchId,
          academyId: widget.academyId,
          alreadyAdded: alreadyAdded,
        ),
      ),
    );
    if (changed == true) {
      ref.read(matchDetailProvider(widget.matchId).notifier).refresh();
    }
  }

  void _snack(String? error, String ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? ok),
      backgroundColor: error == null ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _togglePaid(MatchPlayer player, bool paid) async {
    final err = await ref
        .read(matchDetailProvider(widget.matchId).notifier)
        .setPaid(player.id, paid);
    _snack(err, paid ? 'تم تسجيل دفع ${player.fullName}' : 'تم إلغاء الدفع');
  }

  // تعديل إعدادات المباراة (وكتابة قيمة الاشتراك بعد الإنشاء).
  Future<void> _editSettings(MatchModel match) async {
    var settings = MatchSettings(
      countsAsSession: match.countsAsSession,
      hasFee: match.hasFee,
      addToRevenue: match.addToRevenue,
    );
    final feeCtrl = TextEditingController(
      text: match.feeAmount == null ? '' : match.feeAmount!.toStringAsFixed(match.feeAmount! % 1 == 0 ? 0 : 2),
    );
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, MediaQuery.of(ctx).viewInsets.bottom + 16.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MatchSettingsSection(
                  value: settings,
                  feeController: feeCtrl,
                  onChanged: (v) => setSheet(() => settings = v),
                ),
                Gap(12.h),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('حفظ الإعدادات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final body = settings.toBody(feeCtrl.text);
    feeCtrl.dispose();
    if (save != true) return;
    final err = await ref.read(matchDetailProvider(widget.matchId).notifier).updateSettings(body);
    _snack(err, 'تم حفظ إعدادات المباراة');
  }

  Future<void> _removePlayer(MatchPlayer player) async {
    final ok = await ref.read(matchDetailProvider(widget.matchId).notifier).removePlayer(player.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حذف اللاعب'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchDetailProvider(widget.matchId));
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final canManage =
        user?.isSuperAdmin == true || user?.isAcademyAdmin == true || user?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تفاصيل المباراة')),
      body: _body(state, canManage),
    );
  }

  Widget _body(MatchDetailState state, bool canManage) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null || state.match == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            SizedBox(height: 12.h),
            const Text('تعذّر تحميل تفاصيل المباراة'),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () => ref.read(matchDetailProvider(widget.matchId).notifier).refresh(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final match = state.match!;
    final players = state.players;

    return RefreshIndicator(
      onRefresh: () => ref.read(matchDetailProvider(widget.matchId).notifier).refresh(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 30.h),
        children: [
          _InfoCard(match: match),
          Gap(10.h),
          _SettingsCard(
            match: match,
            canManage: canManage,
            onEdit: () => _editSettings(match),
          ),
          Gap(16.h),
          Row(
            children: [
              Text('اللاعبون (${players.length})',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (canManage && players.isNotEmpty)
                TextButton.icon(
                  onPressed: _sendingAll ? null : () => _sendAll(match, players),
                  icon: _sendingAll
                      ? SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: const CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.notifications_active_outlined, size: 18),
                  label: const Text('إرسال للجميع'),
                ),
            ],
          ),
          Gap(8.h),
          if (canManage)
            OutlinedButton.icon(
              onPressed: () => _addPlayers(match.playerIds),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('إضافة لاعبين'),
            ),
          Gap(10.h),
          if (players.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text('لا يوجد لاعبون في هذه المباراة بعد',
                    style: TextStyle(color: AppColors.grey500, fontSize: 13.sp)),
              ),
            )
          else
            ...players.map((p) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _PlayerTile(
                    player: p,
                    canManage: canManage,
                    sending: _sending.contains(p.id),
                    hasFee: match.hasFee,
                    paid: match.isPaid(p.id),
                    onTogglePaid: () => _togglePaid(p, !match.isPaid(p.id)),
                    onRemind: () => _sendOne(match, p),
                    onRemove: () => _removePlayer(p),
                  ),
                )),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final MatchModel match;
  const _InfoCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_basketball, color: AppColors.primary, size: 22.sp),
              ),
              Gap(10.w),
              Expanded(
                child: Text(match.name,
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (match.sport != null && match.sport!.isNotEmpty) ...[
            Gap(10.h),
            _row(Icons.category_outlined, match.sport!),
          ],
          Gap(10.h),
          _row(Icons.location_on_outlined, match.location),
          Gap(8.h),
          _row(Icons.calendar_today_outlined, match.date),
          Gap(8.h),
          _row(Icons.access_time_outlined, match.time),
          Gap(8.h),
          _row(Icons.group_outlined, '${match.playersCount} لاعب'),
          if (match.notes != null && match.notes!.isNotEmpty) ...[
            Gap(10.h),
            const Divider(),
            Gap(6.h),
            Text(match.notes!, style: TextStyle(fontSize: 13.sp, color: AppColors.grey700)),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.grey500),
        Gap(6.w),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13.sp, color: AppColors.grey700))),
      ],
    );
  }
}

/// ملخص إعدادات المباراة + المدفوعات، وزر تعديلها.
class _SettingsCard extends StatelessWidget {
  final MatchModel match;
  final bool canManage;
  final VoidCallback onEdit;
  const _SettingsCard({required this.match, required this.canManage, required this.onEdit});

  String _money(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final fee = match.feeAmount;
    final lines = <String>[
      match.countsAsSession ? 'الحضور يُحسب ضمن حصص الاشتراك' : 'الحضور لا يُحسب ضمن الحصص',
      if (!match.hasFee) 'بدون اشتراك للمباراة',
      if (match.hasFee) fee == null ? 'اشتراك المباراة: لم تُحدَّد القيمة بعد' : 'اشتراك المباراة: ${_money(fee)}',
      if (match.hasFee) match.addToRevenue ? 'يُضاف إلى الإيرادات' : 'لا يُضاف إلى الإيرادات',
      if (match.hasFee) 'دفع ${match.paidCount} من ${match.playersCount} — الإجمالي ${_money(match.paidTotal)}',
    ];
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('إعدادات المباراة',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (canManage)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('تعديل الإعدادات'),
                ),
            ],
          ),
          for (final l in lines)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text('• $l', style: TextStyle(fontSize: 13.sp, color: AppColors.grey700)),
            ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final MatchPlayer player;
  final bool canManage;
  final bool sending;
  final bool hasFee;
  final bool paid;
  final VoidCallback onTogglePaid;
  final VoidCallback onRemind;
  final VoidCallback onRemove;

  const _PlayerTile({
    required this.player,
    required this.canManage,
    required this.sending,
    required this.hasFee,
    required this.paid,
    required this.onTogglePaid,
    required this.onRemind,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.fullName,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                Gap(2.h),
                Text(player.playerCode,
                    style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey500)),
              ],
            ),
          ),
          if (hasFee) ...[
            canManage
                ? FilterChip(
                    label: Text(paid ? 'دفع ✓' : 'لم يدفع'),
                    selected: paid,
                    selectedColor: AppColors.successLight,
                    checkmarkColor: AppColors.success,
                    showCheckmark: false,
                    onSelected: (_) => onTogglePaid(),
                  )
                : Text(paid ? 'دفع ✓' : 'لم يدفع',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: paid ? AppColors.success : AppColors.grey500)),
            Gap(4.w),
          ],
          if (canManage) ...[
            sending
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: 'تذكير',
                    icon: const Icon(Icons.notifications_active_outlined),
                    color: AppColors.primary,
                    onPressed: onRemind,
                  ),
            IconButton(
              tooltip: 'إزالة',
              icon: const Icon(Icons.close),
              color: AppColors.error,
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
