import 'package:image_picker/image_picker.dart';

/// حد أقصى موحّد لحجم أي صورة تُرفع — مطابق لـ MAX_IMAGE_BYTES في الخادم
/// (backend/src/config/cloudinary.js). الفحص هنا يوفّر رحلة رفع فاشلة،
/// والخادم يبقى هو المرجع النهائي.
const int kMaxImageBytes = 2 * 1024 * 1024;

/// حد أقصى لحجم فيديو ألبوم الأكاديمية — مطابق لـ MAX_ALBUM_MEDIA_BYTES.
const int kMaxAlbumVideoBytes = 20 * 1024 * 1024;

/// الرسالة المعروضة عند تجاوز الحد.
const String kImageTooLargeMessage = 'حجم الصورة يجب ألا يزيد عن 2 ميجابايت.';
const String kVideoTooLargeMessage = 'حجم الفيديو يجب ألا يزيد عن 20 ميجابايت.';

/// يعيد `null` إذا كان الحجم مقبولاً، أو رسالة الخطأ إذا تجاوز الحد.
/// يعمل على الجوال والويب معاً — `XFile.length()` مدعوم على المنصتين.
Future<String?> validateImageSize(XFile file) async {
  final bytes = await file.length();
  return bytes > kMaxImageBytes ? kImageTooLargeMessage : null;
}

/// نفس الفكرة لملفات فيديو ألبوم الأكاديمية (حد أعلى).
Future<String?> validateAlbumVideoSize(XFile file) async {
  final bytes = await file.length();
  return bytes > kMaxAlbumVideoBytes ? kVideoTooLargeMessage : null;
}
