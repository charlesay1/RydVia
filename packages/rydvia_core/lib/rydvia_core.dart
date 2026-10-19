import 'dart:convert';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.publishableKey,
    this.otpLength = 6,
    this.resendSeconds = 60,
  });
  final String supabaseUrl;
  final String publishableKey;
  final int otpLength;
  final int resendSeconds;
  factory AppConfig.fromEnvironment() => const AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    otpLength: int.fromEnvironment('AUTH_OTP_LENGTH', defaultValue: 6),
    resendSeconds: int.fromEnvironment('AUTH_RESEND_SECONDS', defaultValue: 60),
  );
  void validate() {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        publishableKey.isEmpty) {
      throw const AppFailure(
        'configuration',
        'Secure service configuration is missing.',
      );
    }
    if (publishableKey.startsWith('sb_secret_')) {
      throw const AppFailure(
        'configuration',
        'A public client key is required.',
      );
    }
    if (publishableKey.startsWith('eyJ')) {
      try {
        final claims =
            jsonDecode(
                  utf8.decode(
                    base64Url.decode(
                      base64Url.normalize(publishableKey.split('.')[1]),
                    ),
                  ),
                )
                as Map;
        if (claims['role'] != 'anon') throw const FormatException();
      } catch (_) {
        throw const AppFailure(
          'configuration',
          'A public client key is required.',
        );
      }
    } else if (!publishableKey.startsWith('sb_publishable_')) {
      throw const AppFailure(
        'configuration',
        'A public client key is required.',
      );
    }
    if (otpLength < 6 ||
        otpLength > 10 ||
        resendSeconds < 30 ||
        resendSeconds > 3600) {
      throw const AppFailure(
        'configuration',
        'Authentication settings are invalid.',
      );
    }
  }
}

class AppFailure implements Exception {
  const AppFailure(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'AppFailure($code)';
}

String normalizeGhanaPhone(String input) {
  var digits = input.replaceAll(RegExp(r'[\s()-]'), '');
  if (digits.startsWith('+233'))
    digits = digits.substring(4);
  else if (digits.startsWith('233') && digits.length == 12)
    digits = digits.substring(3);
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (!RegExp(r'^[25][0-9]{8}$').hasMatch(digits)) {
    throw const AppFailure('phone', 'Enter a valid Ghana mobile number.');
  }
  return '+233$digits';
}

bool validOtp(String code, int length) =>
    RegExp('^[0-9]{$length}\$').hasMatch(code);
