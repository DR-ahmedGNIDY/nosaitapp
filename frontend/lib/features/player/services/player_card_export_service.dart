import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// نتيجة عملية الحفظ — تفيد الواجهة في صياغة رسالة النجاح.
class PlayerCardSaveResult {
  final bool savedToGallery;
  final String? filePath;
  const PlayerCardSaveResult({required this.savedToGallery, this.filePath});
}

/// خدمة تصدير بطاقة اللاعب — مصدرها الوحيد صورة PNG مُلتقطة مباشرة من
/// `PlayerCardWidget` المعروض على الشاشة (عبر RepaintBoundary)، فلا يوجد رسم
/// ثانٍ للبطاقة في أي مكان. لا تُستخدم مكتبة PDF هنا إطلاقاً باستثناء استثناء
/// تقني واحد صريح: زر "طباعة" — لأن نظام الطباعة في Flutter (على Windows
/// وAndroid) لا يقبل من التطبيق سوى مستند PDF كصيغة نقل لسائق الطابعة، ولا
/// توجد صيغة PNG خام تُرسل مباشرة له. حتى في هذه الحالة لا يُعاد رسم البطاقة:
/// تُغلَّف نفس صورة الـPNG الملتقطة داخل صفحة PDF مؤقتة بالذاكرة فقط لأجل
/// الطباعة، ثم تُهمل فوراً — لا حفظ ولا مشاركة لأي PDF.
class PlayerCardExportService {
  PlayerCardExportService._();

  /// يلتقط Widget البطاقة المعروض كصورة PNG عالية الدقة دون أي إعادة رسم —
  /// نفس الـ Gradient/الظل/الـ BorderRadius/الخطوط/الألوان تماماً كما تظهر
  /// على الشاشة. لا يُستدعى إلا عند الضغط على حفظ/مشاركة/طباعة (وليس عند
  /// فتح الصفحة) توفيراً للأداء والذاكرة.
  ///
  /// pixelRatio مشتق من الحجم المنطقي الفعلي للبطاقة بحيث يكون العرض
  /// الناتج ~3500px — أعلى من 300 DPI عند الطباعة بعرض صفحة A4 أفقية،
  /// ومناسب أيضاً لطباعة PVC Card أو A6/A5 دون أي Blur أو Pixelation.
  static Future<Uint8List> capturePng(GlobalKey cardKey) async {
    final cardContext = cardKey.currentContext;
    if (cardContext == null) {
      throw StateError('تعذّر التقاط البطاقة — لم تُرسم بعد');
    }
    final boundary = cardContext.findRenderObject() as RenderRepaintBoundary;

    // ننتظر نهاية الإطار الحالي لضمان اكتمال رسم البطاقة (الصورة/الشعار/QR).
    await WidgetsBinding.instance.endOfFrame;

    const targetWidth = 3500.0;
    // لا يقل عن 4.0 (طلب صريح) — ويكفي لعرض ناتج ≥ 2200×1400px بدقة ≥ 300 DPI.
    final pixelRatio = (targetWidth / boundary.size.width).clamp(4.0, 10.0);

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData? byteData;
    try {
      byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      // تحرير فوري لصورة الـ GPU — لا نحتاجها بعد استخراج البايتات.
      image.dispose();
    }
    if (byteData == null) {
      throw StateError('تعذّر تحويل البطاقة إلى صورة');
    }
    final bytes = byteData.buffer.asUint8List();
    // لا مرجع آخر لـ byteData بعد هذا — تُترك لجامع النفايات فوراً.
    return bytes;
  }

  /// يحفظ صورة PNG في الجهاز:
  /// - Android: يُحفظ في معرض الصور (Gallery) عبر `gal`.
  /// - Windows/macOS/Linux: يُحفظ في مجلد التنزيلات (Downloads).
  /// - Web: لا نظام ملفات محلي — يُستخدم زر "مشاركة" بدلاً من ذلك.
  static Future<PlayerCardSaveResult> saveToDevice(
    Uint8List pngBytes,
    String fileName,
  ) async {
    if (pngBytes.isEmpty) {
      throw StateError('تعذّر الحفظ — صورة البطاقة فارغة');
    }

    if (kIsWeb) {
      throw UnsupportedError('الحفظ المباشر غير مدعوم على الويب — استخدم زر المشاركة');
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
      if (!hasAccess) {
        throw StateError('لم يُمنح إذن الوصول إلى معرض الصور');
      }
      await Gal.putImageBytes(pngBytes, name: fileName.replaceAll('.png', ''));
      return const PlayerCardSaveResult(savedToGallery: true);
    }

    // Desktop (Windows/macOS/Linux): نحفظ في مجلد التنزيلات.
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final path = '${dir.path}${Platform.pathSeparator}$fileName';
    final file = File(path);
    await file.writeAsBytes(pngBytes, flush: true);
    return PlayerCardSaveResult(savedToGallery: false, filePath: path);
  }

  /// يكتب صورة PNG في ملف مؤقت — يُستخدم لفتحها في عارض الصور الافتراضي
  /// بالجهاز (زر "فتح الصورة") دون أي اعتماد على PDF.
  static Future<String> writeTempFile(Uint8List pngBytes, String fileName) async {
    if (pngBytes.isEmpty) {
      throw StateError('تعذّر فتح الصورة — صورة البطاقة فارغة');
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}$fileName';
    final file = File(path);
    await file.writeAsBytes(pngBytes, flush: true);
    return path;
  }

  /// يفتح ملف الصورة في عارض الصور الافتراضي بالجهاز.
  static Future<void> openImage(String filePath) async {
    final result = await OpenFilex.open(filePath, type: 'image/png');
    if (result.type != ResultType.done) {
      throw StateError(result.message.isNotEmpty ? result.message : 'تعذّر فتح الصورة');
    }
  }

  /// يشارك صورة PNG مباشرة (وليس PDF) عبر share_plus.
  static Future<void> shareImage(Uint8List pngBytes, String fileName) async {
    if (pngBytes.isEmpty) {
      throw StateError('تعذّرت المشاركة — صورة البطاقة فارغة');
    }
    await Share.shareXFiles(
      [XFile.fromData(pngBytes, name: fileName, mimeType: 'image/png')],
      fileNameOverrides: [fileName],
    );
  }

  /// يطبع صورة PNG. استثناء تقني وحيد: نظام الطباعة في Flutter لا يقبل سوى
  /// PDF كصيغة نقل، لذا تُغلَّف نفس صورة الـPNG الملتقطة (BoxFit.contain —
  /// بلا أي تمدد أو تشويه) داخل صفحة PDF مؤقتة بالذاكرة فقط لأجل هذه
  /// العملية، دون حفظها أو مشاركتها.
  static Future<void> printImage(Uint8List pngBytes) async {
    if (pngBytes.isEmpty) {
      throw StateError('تعذّرت الطباعة — صورة البطاقة فارغة');
    }
    await Printing.layoutPdf(
      onLayout: (_) => _wrapForPrintOnly(pngBytes),
    );
  }

  static Future<Uint8List> _wrapForPrintOnly(Uint8List pngBytes) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    final base = PdfPageFormat.a4.landscape;

    doc.addPage(
      pw.Page(
        pageFormat: base.copyWith(
          marginTop: 24,
          marginBottom: 24,
          marginLeft: 24,
          marginRight: 24,
        ),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );

    return doc.save();
  }
}
