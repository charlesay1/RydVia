import 'package:test/test.dart';
import 'package:rydvia_core/rydvia_core.dart';

void main() {
  test('Ghana phone formats normalize without accepting malformed numbers', () {
    for (final phone in [
      '024 123 4567',
      '241234567',
      '+233241234567',
      '233241234567',
    ]) {
      expect(normalizeGhanaPhone(phone), '+233241234567');
    }
    for (final phone in [
      '',
      '02412',
      '+1241234567',
      '024123456789',
      'abc',
      '0412345678',
    ]) {
      expect(() => normalizeGhanaPhone(phone), throwsA(isA<AppFailure>()));
    }
  });
  test('OTP length and numeric validation', () {
    expect(validOtp('123456', 6), isTrue);
    for (final code in ['12345', '1234567', '12a456', ' 123456']) {
      expect(validOtp(code, 6), isFalse);
    }
  });
  test(
    'configuration fails closed and does not expose credentials in errors',
    () {
      expect(
        () => const AppConfig(supabaseUrl: '', publishableKey: '').validate(),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => const AppConfig(
          supabaseUrl: 'https://example.supabase.co',
          publishableKey: 'sb_secret_test',
        ).validate(),
        throwsA(isA<AppFailure>()),
      );
      expect(
        const AppFailure('network', 'safe message').toString(),
        'AppFailure(network)',
      );
    },
  );
}
