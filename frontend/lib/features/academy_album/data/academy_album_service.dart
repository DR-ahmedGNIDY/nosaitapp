import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/core/utils/multipart/image_multipart_helper.dart';
import 'package:basketball_academy/features/academy_album/data/album_image.dart';
import 'package:dio/dio.dart';

/// نتيجة صفحة ألبوم (عناصر + هل توجد صفحة تالية) لدعم Pagination/Lazy Loading.
class AlbumPage {
  final List<AlbumImage> items;
  final bool hasNext;
  const AlbumPage(this.items, this.hasNext);
}

/// خدمة ألبوم الأكاديمية — تعيد استخدام ApiClient نفسه. جهة المدير (CRUD)
/// وجهة اللاعب (قراءة فقط عبر /player/album). لا خدمة رفع/شبكة جديدة.
class AcademyAlbumService {
  final ApiClient _api;
  AcademyAlbumService(this._api);

  AlbumPage _parse(Response<Map<String, dynamic>> res) {
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? [])
        .map((e) => AlbumImage.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>?;
    final hasNext = meta?['hasNext'] as bool? ?? false;
    return AlbumPage(list, hasNext);
  }

  // ── جهة المدير ──
  Future<AlbumPage> getAlbum({int page = 1, int limit = 20}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/academy-album',
      queryParameters: {'page': page, 'limit': limit},
    );
    return _parse(res);
  }

  Future<AlbumImage> upload({
    required String imagePath,
    required String title,
    String? description,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'image': await buildImageMultipart(imagePath, filename: 'album.jpg'),
    });
    final res = await _api.postMultipart<Map<String, dynamic>>(
      '/academy-album',
      data: form,
    );
    return AlbumImage.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<AlbumImage> update({
    required String id,
    String? title,
    String? description,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/academy-album/$id',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      },
    );
    return AlbumImage.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(String id) async {
    await _api.delete('/academy-album/$id');
  }

  Future<void> reorder(List<String> ids) async {
    await _api.patch('/academy-album/reorder', data: {'ids': ids});
  }

  // ── جهة اللاعب (قراءة فقط) ──
  Future<AlbumPage> getPlayerAlbum({int page = 1, int limit = 20}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/player/album',
      queryParameters: {'page': page, 'limit': limit},
    );
    return _parse(res);
  }
}
