import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rydvia_core/rydvia_core.dart';
import 'package:rydvia_models/rydvia_models.dart';

abstract interface class AuthRepository {
  Stream<bool> get sessionChanges;
  bool get hasSession;
  Future<void> requestCode(String phone);
  Future<void> verifyCode(String phone, String code);
  Future<AccessProfile> accessProfile();
  Future<void> completeOnboarding(String name, ProductRole role);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  @override
  bool get hasSession => client.auth.currentSession != null;
  @override
  Stream<bool> get sessionChanges =>
      client.auth.onAuthStateChange.map((event) => event.session != null);
  @override
  Future<void> requestCode(String phone) =>
      client.auth.signInWithOtp(phone: phone);
  @override
  Future<void> verifyCode(String phone, String code) async {
    final response = await client.auth.verifyOTP(
      phone: phone,
      token: code,
      type: OtpType.sms,
    );
    if (response.session == null) {
      throw const AppFailure(
        'session',
        'Verification did not create a session. Please sign in again.',
      );
    }
  }

  @override
  Future<AccessProfile> accessProfile() async {
    final data = Map<String, dynamic>.from(
      await client.rpc('access_profile') as Map,
    );
    final userId = client.auth.currentUser?.id;
    if (userId == null || data['user_id'] != userId) {
      throw const AppFailure('session', 'Please sign in again.');
    }
    return AccessProfile(
      userId: userId,
      roles: List<String>.from(data['roles'] as List),
      onboarded: data['onboarded'] == true,
    );
  }

  @override
  Future<void> completeOnboarding(String name, ProductRole role) async {
    await client.rpc(
      'complete_onboarding',
      params: {'display_name_input': name, 'requested_role': role.name},
    );
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}

AppFailure authFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is AuthException) {
    return switch (error.code) {
      'otp_expired' => const AppFailure(
        'otp_expired',
        'This code is invalid or expired. Request a new code.',
      ),
      'over_sms_send_rate_limit' ||
      'over_request_rate_limit' => const AppFailure(
        'rate_limit',
        'Too many requests. Wait a moment before trying again.',
      ),
      'session_not_found' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' => const AppFailure(
        'session',
        'Your session has expired. Please sign in again.',
      ),
      _ => const AppFailure(
        'auth',
        'We could not verify your request. Check the code or try again.',
      ),
    };
  }
  return const AppFailure(
    'network',
    'Unable to connect. Check your connection and try again.',
  );
}
