import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/core/network/token_manager.dart';
import 'package:basketball_academy/core/utils/multipart/image_multipart_helper.dart';
import 'package:dio/dio.dart';

/// خدمة بوابة اللاعب (Nosait SaaS): دخول اللاعب + لوحته + محادثته + إشعاراته.
/// تستخدم نفس ApiClient/التوكن؛ يُميَّز نوع الجلسة عبر sessionType='player'.
class PlayerApiService {
  final ApiClient _api;
  final TokenManager _tokenManager;

  PlayerApiService(this._api, this._tokenManager);

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/player/login',
      data: {'username': username, 'password': password},
    );
    final body = res.data as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null) {
      await _tokenManager.saveToken(token);
      await _tokenManager.saveSessionType('player');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _api.get<Map<String, dynamic>>('/auth/player/me');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final res = await _api.get<Map<String, dynamic>>('/player/dashboard');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  // ── الصورة الشخصية ──
  /// يرفع صورة اللاعب إلى Cloudinary عبر الخادم ويعيد رابط الصورة الجديد.
  Future<String?> updatePhoto(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await buildImageMultipart(imagePath, filename: 'player_image.jpg'),
    });
    final res = await _api.putMultipart<Map<String, dynamic>>(
      '/player/photo',
      data: formData,
    );
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return data?['image_url'] as String?;
  }

  /// يحذف صورة اللاعب من Cloudinary ويعيدها إلى الافتراضية.
  Future<void> deletePhoto() async {
    await _api.delete('/player/photo');
  }

  // ── المحادثة ──
  Future<Map<String, dynamic>> getChat() async {
    final res = await _api.get<Map<String, dynamic>>('/player/chat');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendChat(String text) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/player/chat',
      data: {'text': text},
    );
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  // ── الإشعارات ──
  Future<Map<String, dynamic>> notifications() async {
    final res = await _api.get<Map<String, dynamic>>('/player/notifications');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<void> markNotificationRead(String id) async {
    await _api.patch('/player/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _api.patch('/player/notifications/read-all');
  }

  Future<void> logout() async {
    await _tokenManager.clearToken();
  }
}
