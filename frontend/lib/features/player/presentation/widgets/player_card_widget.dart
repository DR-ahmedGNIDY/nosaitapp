import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// بطاقة تعريف اللاعب — تصميم واحد ومصدر حقيقة وحيد (Single Source of Truth).
///
/// هذا الـ Widget هو نفسه المُستخدم على الشاشة، وهو نفسه الذي يُلتقط كصورة
/// PNG عالية الدقة عند الحفظ/المشاركة/الطباعة (عبر `PlayerCardExportService`
/// و`RepaintBoundary`). أي تعديل هنا يظهر تلقائياً في كل تلك المسارات دون
/// الحاجة لتعديل أي كود آخر — لا يوجد رسم ثانٍ للبطاقة في أي مكان.
class _CardScheme {
  final Color primary;
  final Color primaryDark;
  final Color mid;
  final Color soft;
  const _CardScheme(this.primary, this.primaryDark, this.mid, this.soft);
}

const _cardSchemes = <String, _CardScheme>{
  'navy': _CardScheme(
    Color(0xFF0B2E6B),
    Color(0xFF071F4A),
    Color(0xFF3E6FC4),
    Color(0xFFEAF1FB),
  ),
  'red': _CardScheme(
    Color(0xFFB91C1C),
    Color(0xFF7F1010),
    Color(0xFFEF4444),
    Color(0xFFFCE8E8),
  ),
  'orange': _CardScheme(
    Color(0xFFC2410C),
    Color(0xFF7C2D0C),
    Color(0xFFF97316),
    Color(0xFFFDEEDC),
  ),
  'black': _CardScheme(
    Color(0xFF1A1A1A),
    Color(0xFF000000),
    Color(0xFF4B5563),
    Color(0xFFECECEC),
  ),
};

class PlayerCardWidget extends StatelessWidget {
  final String academyName;
  final String? academyLogoUrl;
  final String fullName;
  final String playerCode;
  final String sport;
  final String? imageUrl;
  final String qrData;
  final DateTime? birthDate;
  final String cardColor;
  final String? slogan;

  const PlayerCardWidget({
    super.key,
    required this.academyName,
    required this.academyLogoUrl,
    required this.fullName,
    required this.playerCode,
    required this.sport,
    required this.imageUrl,
    required this.qrData,
    this.birthDate,
    this.cardColor = 'navy',
    this.slogan,
  });

  _CardScheme get _scheme => _cardSchemes[cardColor] ?? _cardSchemes['navy']!;

  String get _slogan => (slogan != null && slogan!.isNotEmpty) ? slogan! : 'معًا نحو القمة';

  String get _birthDateLabel {
    final d = birthDate;
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd / $mm / ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final radius = w * 0.045;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.16),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // خلفية بيضاء نظيفة + لمسات احترافية خفيفة جداً (منحنيات،
                // Hexagon، أمواج) بشفافية منخفضة — بلا أي ازدحام بصري.
                Positioned.fill(child: Container(color: Colors.white)),
                Positioned.fill(
                  child: CustomPaint(painter: _BackgroundPatternPainter(scheme.primary)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 16,
                      child: _Header(
                        w: w,
                        scheme: scheme,
                        academyName: academyName,
                        academyLogoUrl: academyLogoUrl,
                        sport: sport,
                      ),
                    ),
                    Expanded(
                      flex: 62,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // يمين البطاقة (أول عنصر في صف RTL) — صورة اللاعب.
                              Expanded(
                                flex: 30,
                                child: _PlayerPhoto(w: w, scheme: scheme, imageUrl: imageUrl),
                              ),
                              SizedBox(width: w * 0.02),
                              // المنتصف — الاسم والكود.
                              Expanded(
                                flex: 40,
                                child: _CenterInfo(
                                  w: w,
                                  scheme: scheme,
                                  fullName: fullName,
                                  playerCode: playerCode,
                                ),
                              ),
                              SizedBox(width: w * 0.02),
                              // يسار البطاقة — QR.
                              Expanded(
                                flex: 30,
                                child: _QrColumn(w: w, scheme: scheme, qrData: qrData),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 22,
                      child: _BottomBar(
                        w: w,
                        scheme: scheme,
                        birthDateLabel: _birthDateLabel,
                        slogan: _slogan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── خلفية احترافية خفيفة جداً: منحنيات + Hexagon + أمواج بشفافية منخفضة ────
class _BackgroundPatternPainter extends CustomPainter {
  final Color color;
  const _BackgroundPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;

    // منحنى موجي أعلى يمين البطاقة.
    final wave = Path()
      ..moveTo(size.width * 0.55, -size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.85, size.height * 0.12,
        size.width * 1.05, -size.height * 0.02,
      );
    canvas.drawPath(wave, stroke);

    // منحنى موجي أسفل يسار البطاقة.
    final wave2 = Path()
      ..moveTo(-size.width * 0.05, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.2, size.height * 1.05,
        size.width * 0.45, size.height * 0.92,
      );
    canvas.drawPath(wave2, stroke);

    // نمط سداسي (Hexagon) خفيف جداً في الزاوية العلوية اليسرى.
    _drawHexagon(canvas, Offset(size.width * 0.08, size.height * 0.1), size.width * 0.05, stroke);
    _drawHexagon(canvas, Offset(size.width * 0.14, size.height * 0.2), size.width * 0.035, stroke);

    // دائرة هندسية خفيفة أسفل يمين البطاقة.
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.95), size.width * 0.1, fill);
  }

  void _drawHexagon(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── رأس البطاقة: شعار + اسم الأكاديمية (حقيقي من البيانات) + شارة الرياضة ──
class _Header extends StatelessWidget {
  final double w;
  final _CardScheme scheme;
  final String academyName;
  final String? academyLogoUrl;
  final String sport;

  const _Header({
    required this.w,
    required this.scheme,
    required this.academyName,
    required this.academyLogoUrl,
    required this.sport,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = w * 0.07;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: scheme.primary.withValues(alpha: 0.08), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.014),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.soft,
                border: Border.all(color: scheme.primary, width: 1.6),
              ),
              child: ClipOval(
                child: (academyLogoUrl != null && academyLogoUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: academyLogoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _logoPlaceholder(logoSize, scheme),
                        placeholder: (_, __) => _logoPlaceholder(logoSize, scheme),
                      )
                    : _logoPlaceholder(logoSize, scheme),
              ),
            ),
            SizedBox(width: w * 0.022),
            Expanded(
              child: Text(
                academyName,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: w * 0.034,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  height: 1.1,
                ),
              ),
            ),
            if (sport.isNotEmpty) ...[
              SizedBox(width: w * 0.018),
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.007),
                decoration: BoxDecoration(
                  color: scheme.soft,
                  borderRadius: BorderRadius.circular(w * 0.05),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(
                  sport,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: w * 0.016,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _logoPlaceholder(double size, _CardScheme scheme) => Container(
        color: scheme.soft,
        alignment: Alignment.center,
        child: Icon(Icons.shield_outlined, size: size * 0.55, color: scheme.primary),
      );
}

// ─── صورة اللاعب — دائرة كبيرة، إطار كحلي غامق، ظل خفيف. ────────────────────
class _PlayerPhoto extends StatelessWidget {
  final double w;
  final _CardScheme scheme;
  final String? imageUrl;

  const _PlayerPhoto({required this.w, required this.scheme, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final photoSize = w * 0.30;
    return Center(
      child: Container(
        width: photoSize,
        height: photoSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 3.4),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _avatarPlaceholder(photoSize, scheme),
                  placeholder: (_, __) => _avatarPlaceholder(photoSize, scheme),
                )
              : _avatarPlaceholder(photoSize, scheme),
        ),
      ),
    );
  }

  static Widget _avatarPlaceholder(double size, _CardScheme scheme) => Container(
        color: scheme.soft,
        alignment: Alignment.center,
        child: Icon(Icons.person, size: size * 0.55, color: scheme.primary),
      );
}

// ─── منتصف البطاقة — اسم اللاعب (كبير جداً/Bold/كحلي) + كود اللاعب. ─────────
class _CenterInfo extends StatelessWidget {
  final double w;
  final _CardScheme scheme;
  final String fullName;
  final String playerCode;

  const _CenterInfo({
    required this.w,
    required this.scheme,
    required this.fullName,
    required this.playerCode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fullName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: w * 0.058,
                fontWeight: FontWeight.w900,
                color: scheme.primaryDark,
                height: 1.15,
              ),
            ),
            SizedBox(height: w * 0.026),
            Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.036, vertical: w * 0.014),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.mid, scheme.primary],
                ),
                borderRadius: BorderRadius.circular(w * 0.05),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                playerCode,
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── عمود الـ QR — بطاقة بيضاء بإطار كحلي + "امسح للتحقق". لا تعديل على
// منطق أو بيانات الـ QR نفسه (نفس `qrData` كما يصل من الشاشة). ──────────────
class _QrColumn extends StatelessWidget {
  final double w;
  final _CardScheme scheme;
  final String qrData;

  const _QrColumn({required this.w, required this.scheme, required this.qrData});

  @override
  Widget build(BuildContext context) {
    final qrSize = w * 0.245;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: qrSize,
            height: qrSize,
            padding: EdgeInsets.all(w * 0.014),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(w * 0.028),
              border: Border.all(color: scheme.primary, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: scheme.primaryDark,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: scheme.primaryDark,
              ),
              errorStateBuilder: (_, __) => Center(
                child: Text(
                  'تعذّر توليد QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: w * 0.016, color: Colors.red),
                ),
              ),
            ),
          ),
          SizedBox(height: w * 0.01),
          Text(
            'امسح للتحقق',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.016,
              fontWeight: FontWeight.w700,
              color: scheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── الشريط السفلي — Navy Blue بعرض البطاقة: تاريخ الميلاد + الشعار. ────────
class _BottomBar extends StatelessWidget {
  final double w;
  final _CardScheme scheme;
  final String birthDateLabel;
  final String slogan;

  const _BottomBar({
    required this.w,
    required this.scheme,
    required this.birthDateLabel,
    required this.slogan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.primary,
      padding: EdgeInsets.symmetric(horizontal: w * 0.045),
      alignment: Alignment.center,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (birthDateLabel.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📅', style: TextStyle(fontSize: w * 0.024)),
                  SizedBox(width: w * 0.012),
                  Text(
                    birthDateLabel,
                    style: TextStyle(
                      fontSize: w * 0.024,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            Text(
              slogan,
              style: TextStyle(
                fontSize: w * 0.024,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
