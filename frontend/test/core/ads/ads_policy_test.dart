import 'package:basketball_academy/core/ads/ads_policy.dart';
import 'package:basketball_academy/features/auth/domain/entities/academy_subscription_status.dart';
import 'package:basketball_academy/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

UserEntity _user(
  UserRole role,
  AcademySubscriptionStatus status, {
  DateTime? endDate,
}) =>
    UserEntity(
      id: 'u1',
      name: 'اختبار',
      email: 't@t.com',
      role: role,
      academyId: role == UserRole.superAdmin ? null : 'ACADEMY_1',
      createdAt: DateTime(2026, 1, 1),
      academySubscriptionStatus: status,
      academySubscriptionEndDate: endDate,
    );

bool _adminAds(UserEntity u, {DateTime? now}) => AdsPolicy.shouldShowAds(
      session: AdsSessionKind.admin,
      user: u,
      now: now,
    );

void main() {
  group('اللاعب — إعلانات دائماً', () {
    test('ON بصرف النظر عن أي شيء آخر', () {
      expect(AdsPolicy.shouldShowAds(session: AdsSessionKind.player), isTrue);
    });
  });

  group('لا جلسة', () {
    test('OFF على شاشات الدخول/الترحيب', () {
      expect(AdsPolicy.shouldShowAds(session: AdsSessionKind.none), isFalse);
    });

    test('OFF عندما تكون الجلسة إدارية والمستخدم لم يُحمَّل بعد', () {
      expect(
        AdsPolicy.shouldShowAds(session: AdsSessionKind.admin, user: null),
        isFalse,
      );
    });
  });

  group('academy_admin — يتبع اشتراك الأكاديمية', () {
    test('active → OFF', () {
      expect(
        _adminAds(_user(UserRole.academyAdmin, AcademySubscriptionStatus.active)),
        isFalse,
      );
    });

    test('trial → ON', () {
      expect(
        _adminAds(_user(UserRole.academyAdmin, AcademySubscriptionStatus.trial)),
        isTrue,
      );
    });

    test('expired → ON', () {
      expect(
        _adminAds(_user(UserRole.academyAdmin, AcademySubscriptionStatus.expired)),
        isTrue,
      );
    });

    test('suspended → ON', () {
      expect(
        _adminAds(
            _user(UserRole.academyAdmin, AcademySubscriptionStatus.suspended)),
        isTrue,
      );
    });

    test('none (أكاديمية بلا وثيقة اشتراك) → ON', () {
      expect(
        _adminAds(_user(UserRole.academyAdmin, AcademySubscriptionStatus.none)),
        isTrue,
      );
    });

    test('unknown (لم تصل البيانات / فشل API) → OFF — fail-closed', () {
      expect(
        _adminAds(_user(UserRole.academyAdmin, AcademySubscriptionStatus.unknown)),
        isFalse,
      );
    });
  });

  group('admin (إداري) — نفس اشتراك الأكاديمية تماماً', () {
    test('active → OFF', () {
      expect(
        _adminAds(_user(UserRole.admin, AcademySubscriptionStatus.active)),
        isFalse,
      );
    });

    test('expired → ON', () {
      expect(
        _adminAds(_user(UserRole.admin, AcademySubscriptionStatus.expired)),
        isTrue,
      );
    });

    test('none → ON', () {
      expect(
        _adminAds(_user(UserRole.admin, AcademySubscriptionStatus.none)),
        isTrue,
      );
    });

    test('unknown → OFF', () {
      expect(
        _adminAds(_user(UserRole.admin, AcademySubscriptionStatus.unknown)),
        isFalse,
      );
    });
  });

  group('super_admin — مالك المنصة بلا أكاديمية', () {
    test('OFF رغم أن حالته none (لا يُعامَل كغير مشترك)', () {
      expect(
        _adminAds(_user(UserRole.superAdmin, AcademySubscriptionStatus.none)),
        isFalse,
      );
    });

    test('OFF أيضاً عند unknown', () {
      expect(
        _adminAds(_user(UserRole.superAdmin, AcademySubscriptionStatus.unknown)),
        isFalse,
      );
    });
  });

  group('انتهاء الاشتراك أثناء الجلسة (endDate)', () {
    final past = DateTime(2026, 1, 1);
    final future = DateTime(2027, 1, 1);
    final now = DateTime(2026, 6, 1);

    test('active لكن endDate مضى → ON', () {
      expect(
        _adminAds(
          _user(UserRole.academyAdmin, AcademySubscriptionStatus.active,
              endDate: past),
          now: now,
        ),
        isTrue,
      );
    });

    test('active و endDate لم يحن → OFF', () {
      expect(
        _adminAds(
          _user(UserRole.academyAdmin, AcademySubscriptionStatus.active,
              endDate: future),
          now: now,
        ),
        isFalse,
      );
    });

    test('active بلا endDate → OFF (لا نخترع انتهاءً)', () {
      expect(
        _adminAds(
          _user(UserRole.academyAdmin, AcademySubscriptionStatus.active),
          now: now,
        ),
        isFalse,
      );
    });

    test('endDate المستقبلي لا يُحيي اشتراكاً expired', () {
      expect(
        _adminAds(
          _user(UserRole.admin, AcademySubscriptionStatus.expired,
              endDate: future),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('تحويل حالة الخادم', () {
    test('القيم المعروفة', () {
      expect(AcademySubscriptionStatus.fromApi('active'),
          AcademySubscriptionStatus.active);
      expect(AcademySubscriptionStatus.fromApi('trial'),
          AcademySubscriptionStatus.trial);
      expect(AcademySubscriptionStatus.fromApi('expired'),
          AcademySubscriptionStatus.expired);
      expect(AcademySubscriptionStatus.fromApi('suspended'),
          AcademySubscriptionStatus.suspended);
    });

    test('قيمة غير معروفة أو null → unknown وليس تخميناً', () {
      expect(AcademySubscriptionStatus.fromApi(null),
          AcademySubscriptionStatus.unknown);
      expect(AcademySubscriptionStatus.fromApi('whatever'),
          AcademySubscriptionStatus.unknown);
    });
  });

  group('حماية إعلانات الأطفال (COPPA) — من عمر اللاعب الحقيقي', () {
    final now = DateTime(2026, 8, 31);

    test('المدير لا تُفعَّل له الحماية إطلاقاً', () {
      expect(
        AdsPolicy.isChildDirected(session: AdsSessionKind.admin, now: now),
        isFalse,
      );
    });

    test('لاعب عمره 10 سنوات → حماية مفعّلة', () {
      expect(
        AdsPolicy.isChildDirected(
          session: AdsSessionKind.player,
          birthDate: DateTime(2016, 5, 1),
          now: now,
        ),
        isTrue,
      );
    });

    test('لاعب عمره 15 سنة → بلا حماية', () {
      expect(
        AdsPolicy.isChildDirected(
          session: AdsSessionKind.player,
          birthDate: DateTime(2011, 5, 1),
          now: now,
        ),
        isFalse,
      );
    });

    test('أتم 13 اليوم بالضبط → بلا حماية', () {
      expect(
        AdsPolicy.isChildDirected(
          session: AdsSessionKind.player,
          birthDate: DateTime(2013, 8, 31),
          now: now,
        ),
        isFalse,
      );
    });

    test('يتم 13 غداً → ما زال محمياً', () {
      expect(
        AdsPolicy.isChildDirected(
          session: AdsSessionKind.player,
          birthDate: DateTime(2013, 9, 1),
          now: now,
        ),
        isTrue,
      );
    });

    test('تاريخ ميلاد مفقود → حماية (fail-safe)', () {
      expect(
        AdsPolicy.isChildDirected(session: AdsSessionKind.player, now: now),
        isTrue,
      );
    });

    test('تاريخ مستقبلي (بيانات تالفة) → حماية', () {
      expect(
        AdsPolicy.isChildDirected(
          session: AdsSessionKind.player,
          birthDate: DateTime(2030, 1, 1),
          now: now,
        ),
        isTrue,
      );
    });
  });
}
