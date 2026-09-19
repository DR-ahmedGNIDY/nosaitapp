import 'dart:html' as html;
import 'dart:typed_data';

// يُنشئ Blob URL مؤقت لصورة البطاقة ويُشغّل تنزيلها في متصفح الجهاز عبر
// عنصر <a download> — هذا هو أسلوب "الحفظ" الوحيد الممكن على الويب (لا
// نظام ملفات محلي متاح لـ path_provider).
void downloadBytesInBrowser(Uint8List bytes, String fileName, {String mimeType = 'image/png'}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
