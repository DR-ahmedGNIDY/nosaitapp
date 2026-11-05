import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// حساب محفوظ للدخول السريع من شاشة تسجيل الدخول.
/// لا نحفظ كلمة المرور إطلاقاً — نحفظ توكن الجلسة فقط (داخل التخزين الآمن).
class SavedAccount {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? academyName;
  final String token;

  /// refresh token (صلاحية 30 يوماً تتجدد مع كل استخدام) — يسمح بالدخول بعد انتهاء [token].
  final String? refreshToken;
  final DateTime savedAt;

  const SavedAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    required this.savedAt,
    this.academyName,
    this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'academyName': academyName,
        'token': token,
        'refreshToken': refreshToken,
        'savedAt': savedAt.toIso8601String(),
      };

  static SavedAccount? tryParse(Object? j) {
    if (j is! Map) return null;
    final id = j['id']?.toString() ?? '';
    final token = j['token']?.toString() ?? '';
    if (id.isEmpty || token.isEmpty) return null;
    return SavedAccount(
      id: id,
      name: j['name']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      role: j['role']?.toString() ?? '',
      academyName: j['academyName']?.toString(),
      token: token,
      refreshToken: j['refreshToken']?.toString(),
      savedAt:
          DateTime.tryParse(j['savedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// الحرف الأول للاسم (أو البريد) لدائرة الحساب.
  String get initial {
    final s = name.trim().isNotEmpty ? name.trim() : email.trim();
    return s.isEmpty ? '?' : String.fromCharCode(s.runes.first);
  }
}

/// مخزن الحسابات المحفوظة — أحدث حساب أولاً، بحد أقصى [maxAccounts].
class SavedAccountsStore {
  static const _key = 'saved_accounts';
  static const maxAccounts = 5;

  final FlutterSecureStorage _storage;
  const SavedAccountsStore(this._storage);

  Future<List<SavedAccount>> list() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map(SavedAccount.tryParse)
          .whereType<SavedAccount>()
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[SAVED_ACCOUNTS] list() failed: $e');
      return [];
    }
  }

  Future<void> _write(List<SavedAccount> accounts) => _storage.write(
      key: _key, value: jsonEncode(accounts.map((a) => a.toJson()).toList()));

  /// يضيف الحساب أو يحدّثه (نفس المستخدم) ويضعه أولاً.
  Future<void> upsert(SavedAccount account) async {
    final others = (await list()).where((a) => a.id != account.id).toList();
    await _write([account, ...others].take(maxAccounts).toList());
  }

  Future<void> remove(String id) async {
    final all = await list();
    await _write(all.where((a) => a.id != id).toList());
  }

  /// بعد تغيير كلمة المرور: يستبدل توكنات الكارت الذي كان يحمل [oldToken].
  Future<void> replaceTokens(
      String oldToken, String token, String? refreshToken) async {
    final all = await list();
    if (!all.any((a) => a.token == oldToken)) return;
    await _write([
      for (final a in all)
        a.token == oldToken
            ? SavedAccount(
                id: a.id,
                name: a.name,
                email: a.email,
                role: a.role,
                academyName: a.academyName,
                token: token,
                refreshToken: refreshToken ?? a.refreshToken,
                savedAt: DateTime.now(),
              )
            : a,
    ]);
  }

  /// يحذف الحساب بالبريد (عند الدخول مع إلغاء "حفظ تسجيل الدخول").
  Future<void> removeByEmail(String email) async {
    final e = email.trim().toLowerCase();
    final all = await list();
    await _write(all.where((a) => a.email.trim().toLowerCase() != e).toList());
  }
}
