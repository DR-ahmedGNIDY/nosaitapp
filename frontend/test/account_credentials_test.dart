import 'package:basketball_academy/features/player/presentation/widgets/account_credentials_dialog.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('credentials message has no link and names player + academy', () {
    final msg = AccountCredentialsDialog.buildMessage(
      username: 'Y-0001',
      password: 'a1b2c3',
      playerName: 'أحمد',
      academyName: 'أكاديمية هولندا',
    );
    expect(msg.contains('http'), isFalse);
    expect(msg, contains('أحمد'));
    expect(msg, contains('أكاديمية هولندا'));
    expect(msg, contains('اسم المستخدم: Y-0001'));
    expect(msg, contains('كلمة المرور: a1b2c3'));
  });

  test('falls back when academy name is unknown', () {
    final msg = AccountCredentialsDialog.buildMessage(
        username: 'Y-2', password: 'p');
    expect(msg, contains('الأكاديمية'));
  });

  test('whatsapp url normalizes Egyptian numbers and encodes the message', () {
    final url = WhatsAppUtils.buildUrl('0100 123 4567', message: 'كلمة المرور: p');
    expect(url, startsWith('https://wa.me/201001234567?text='));
    expect(WhatsAppUtils.buildUrl('+201001234567'), 'https://wa.me/201001234567');
  });
}
