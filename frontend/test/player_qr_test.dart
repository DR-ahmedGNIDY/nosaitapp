import 'package:basketball_academy/features/attendance/utils/player_qr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extractCode accepts digits-only manual input', () {
    expect(PlayerQr.extractCode('1'), 'Y-0001');
    expect(PlayerQr.extractCode(' 0145 '), 'Y-0145');
    expect(PlayerQr.extractCode('12345'), 'Y-12345');
    expect(PlayerQr.extractCode('y-0007'), 'Y-0007');
    expect(PlayerQr.extractCode('PLAYER:Y-0145'), 'Y-0145');
    expect(PlayerQr.extractCode('ABC'), 'ABC');
  });
}
