import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rydvia_auth/rydvia_auth.dart';
import 'package:rydvia_core/rydvia_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Synthetic transport fixtures only. No SMS, external HTTP, or real credentials.
const userId = '55555555-5555-4555-8555-555555555555';
const phone = '+233241234567';
http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
Map<String, Object?> sessionFixture() {
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  return {
    'access_token':
        '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({'sub': userId, 'role': 'authenticated', 'exp': expiry})}.fixture',
    'refresh_token': 'fixture-refresh-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'created_at': '2026-10-19T00:00:00Z',
    },
  };
}

SupabaseClient clientFor(
  Future<http.Response> Function(http.Request) handler,
) => SupabaseClient(
  'https://example.supabase.co',
  'sb_publishable_fixture',
  httpClient: MockClient((request) async {
    final response = await handler(request);
    return http.Response.bytes(
      response.bodyBytes,
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }),
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

void main() {
  test(
    'requests SMS with normalized Ghana phone, public key, and no role metadata',
    () async {
      final requests = <http.Request>[];
      final client = clientFor((request) async {
        requests.add(request);
        return jsonResponse({});
      });
      addTearDown(client.dispose);
      final repo = SupabaseAuthRepository(client);
      await repo.requestCode('024 123 4567');
      final body = jsonDecode(requests.single.body) as Map;
      expect(requests.single.url.path, '/auth/v1/otp');
      expect(requests.single.headers['apikey'], 'sb_publishable_fixture');
      expect(body['phone'], phone);
      expect(body['create_user'], true);
      expect((body['data'] as Map?)?.containsKey('role') ?? false, false);
      expect(repo.hasSession, false);
    },
  );
  test(
    'verifies SMS, restores an SDK session, checks profile identity, and logs out locally',
    () async {
      final requests = <http.Request>[];
      final client = clientFor((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/verify'))
          return jsonResponse(sessionFixture());
        if (request.url.path.endsWith('/access_profile'))
          return jsonResponse({
            'user_id': userId,
            'roles': ['customer'],
            'onboarded': true,
          });
        if (request.url.path.endsWith('/logout')) return jsonResponse({});
        throw StateError('Unexpected fixture request');
      });
      addTearDown(client.dispose);
      final repo = SupabaseAuthRepository(client);
      await repo.verifyCode('233241234567', '123456');
      final body = jsonDecode(requests.first.body) as Map;
      expect(body['phone'], phone);
      expect(body['type'], 'sms');
      expect(repo.hasSession, true);
      expect((await repo.accessProfile()).roles, ['customer']);
      final restored = clientFor(
        (_) async => throw StateError('Recovery must not request a new OTP'),
      );
      addTearDown(restored.dispose);
      await restored.auth.recoverSession(
        jsonEncode(client.auth.currentSession!.toJson()),
      );
      expect(SupabaseAuthRepository(restored).hasSession, true);
      expect(restored.auth.currentUser!.id, userId);
      await repo.signOut();
      expect(repo.hasSession, false);
      expect(requests.last.url.path, '/auth/v1/logout');
      expect(requests.last.url.queryParameters['scope'], 'local');
    },
  );
  for (final code in [
    'otp_expired',
    'over_sms_send_rate_limit',
    'sms_send_failed',
  ]) {
    test('handles $code without disclosing the provider response', () async {
      final client = clientFor(
        (_) async => jsonResponse({
          'error_code': code,
          'msg': 'sensitive-provider-detail',
        }, code == 'over_sms_send_rate_limit' ? 429 : 400),
      );
      addTearDown(client.dispose);
      final repo = SupabaseAuthRepository(client);
      try {
        if (code == 'otp_expired') {
          await repo.verifyCode(phone, '000000');
        } else {
          await repo.requestCode(phone);
        }
        fail('Expected a rejected fixture request');
      } on AuthException catch (error) {
        final failure = authFailure(error);
        expect(failure.message, isNot(contains('sensitive-provider-detail')));
        expect(
          failure.code,
          code == 'otp_expired'
              ? 'otp_expired'
              : code == 'sms_send_failed'
              ? 'sms'
              : 'rate_limit',
        );
        expect(repo.hasSession, false);
      }
    });
  }
  test(
    'fails closed when bootstrap profile is missing or belongs to another user',
    () async {
      Object? profile;
      final client = clientFor(
        (request) async => request.url.path.endsWith('/verify')
            ? jsonResponse(sessionFixture())
            : jsonResponse(profile),
      );
      addTearDown(client.dispose);
      final repo = SupabaseAuthRepository(client);
      await repo.verifyCode(phone, '123456');
      await expectLater(
        repo.accessProfile(),
        throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'profile')),
      );
      profile = {
        'user_id': 'other-user',
        'roles': ['admin'],
        'onboarded': true,
      };
      await expectLater(
        repo.accessProfile(),
        throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'session')),
      );
    },
  );
}
