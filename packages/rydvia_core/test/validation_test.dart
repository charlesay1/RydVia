import 'package:test/test.dart';
import 'package:rydvia_core/rydvia_core.dart';

void main() {
  test('Ghana phone formats normalize without accepting malformed numbers', () {
    for (final phone in [
      '0244163371',
      '024 416 3371',
      '24 416 3371',
      '+233244163371',
      '+233 24 416 3371',
      '233244163371',
      ' (024) 416-3371 ',
      '\t+233 (24) 416-3371\n',
    ]) {
      final canonical = normalizeGhanaPhone(phone);
      expect(canonical, '+233244163371');
      expect(normalizeGhanaPhone(canonical), canonical);
    }
    expect(normalizeGhanaPhone('0544163371'), '+233544163371');
    // A nine-digit national subscriber may itself begin with 233. Only a
    // twelve-digit unprefixed value is a country-code input.
    for (final phone in ['0233123456', '233123456', '+233233123456']) {
      expect(normalizeGhanaPhone(phone), '+233233123456');
    }
    for (final phone in [
      '',
      '02412',
      '+1241234567',
      '024123456789',
      'abc',
      '0412345678',
      '   ',
      '+2330244163371',
      '2330244163371',
      '+233 (024) 416-3371',
      '00233244163371',
      '00244163371',
      '++233244163371',
      '+233+244163371',
      '+233233244163371',
      '233233244163371',
      '+234244163371',
      '0244163371ext2',
      '0244.163371',
      '0244/163371',
      '0244163371\u200b',
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
