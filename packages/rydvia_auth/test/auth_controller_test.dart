import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydvia_auth/rydvia_auth.dart';
import 'package:rydvia_core/rydvia_core.dart';
import 'package:rydvia_models/rydvia_models.dart';
import 'package:rydvia_logging/rydvia_logging.dart';

class FakeAuth implements AuthRepository {
  final events = StreamController<bool>.broadcast(sync: true);
  bool active = false;
  bool fail = false;
  int sends = 0;
  int verifies = 0;
  int requests = 0;
  String? requestedPhone;
  AccessProfile profile = AccessProfile(
    userId: 'test-user',
    roles: ['customer'],
    onboarded: false,
  );
  Completer<AccessProfile>? delayedAccess;
  @override
  bool get hasSession => active;
  @override
  Stream<bool> get sessionChanges => events.stream;
  @override
  Future<void> requestCode(String phone) async {
    requestedPhone = phone;
    sends++;
    if (fail) throw Exception('private detail');
  }

  @override
  Future<void> verifyCode(String phone, String code) async {
    verifies++;
    if (fail) throw const AppFailure('otp_expired', 'The code has expired.');
    active = true;
    events.add(true);
  }

  @override
  Future<AccessProfile> accessProfile() async =>
      delayedAccess == null ? profile : await delayedAccess!.future;
  @override
  Future<void> completeOnboarding(String name, ProductRole role) async {
    requests++;
    profile = AccessProfile(
      userId: profile.userId,
      roles: profile.roles,
      onboarded: true,
    );
  }

  @override
  Future<void> signOut() async {
    active = false;
    events.add(false);
  }
}

AuthController controller(
  FakeAuth repo, {
  ProductRole role = ProductRole.customer,
}) => AuthController(
  repository: repo,
  role: role,
  config: const AppConfig(
    supabaseUrl: 'https://example.supabase.co',
    publishableKey: 'sb_publishable_fixture',
  ),
  logger: SafeLogger((_) {}),
);

void main() {
  late FakeAuth repo;
  late AuthController auth;
  setUp(() {
    repo = FakeAuth();
    auth = controller(repo);
  });
  tearDown(() async {
    auth.dispose();
    await repo.events.close();
  });

  test('welcome, validation, code, onboarding, ready, logout', () async {
    await auth.initialize();
    expect(auth.stage, AuthStage.welcome);
    await auth.sendCode('bad');
    expect(repo.sends, 0);
    expect(auth.message, isNotNull);
    await auth.sendCode('0241234567');
    expect(auth.stage, AuthStage.code);
    await auth.verify('123');
    expect(repo.verifies, 0);
    await auth.verify('123456');
    expect(auth.stage, AuthStage.onboarding);
    await auth.onboard('Alex');
    expect(auth.stage, AuthStage.ready);
    await auth.signOut();
    expect(auth.stage, AuthStage.welcome);
    expect(auth.profile, isNull);
  });
  test('resend countdown prevents duplicate requests', () async {
    await auth.initialize();
    final now = DateTime.utc(2026, 10, 19);
    await auth.sendCode('0241234567', now: now);
    await auth.sendCode(
      '0241234567',
      now: now.add(const Duration(seconds: 30)),
    );
    expect(repo.sends, 1);
    await auth.sendCode(
      '0241234567',
      now: now.add(const Duration(seconds: 61)),
    );
    expect(repo.sends, 2);
  });
  test('errors are retryable and raw network details never reach UI', () async {
    await auth.initialize();
    repo.fail = true;
    await auth.sendCode('0241234567');
    expect(auth.busy, isFalse);
    expect(auth.message, isNot(contains('private detail')));
    repo.fail = false;
    await auth.sendCode('0241234567');
    repo.fail = true;
    await auth.verify('123456');
    expect(auth.stage, AuthStage.code);
    expect(auth.message, contains('expired'));
    repo.fail = false;
    await auth.verify('123456');
    expect(auth.stage, AuthStage.onboarding);
  });
  test('driver request cannot grant itself a server-backed role', () async {
    auth.dispose();
    auth = controller(repo, role: ProductRole.driver);
    repo.active = true;
    await auth.initialize();
    await auth.onboard('Driver applicant');
    expect(repo.requests, 1);
    expect(auth.stage, AuthStage.pendingApproval);
    repo.profile = AccessProfile(
      userId: 'test-user',
      roles: ['customer', 'driver'],
      onboarded: true,
    );
    await auth.refreshAccess();
    expect(auth.stage, AuthStage.ready);
  });
  test(
    'session expiry cannot be overwritten by an old profile response',
    () async {
      await auth.initialize();
      repo.active = true;
      repo.delayedAccess = Completer<AccessProfile>();
      final request = auth.refreshAccess();
      await repo.signOut();
      repo.delayedAccess!.complete(
        AccessProfile(
          userId: 'test-user',
          roles: ['customer'],
          onboarded: true,
        ),
      );
      await request;
      expect(auth.stage, AuthStage.welcome);
      expect(auth.profile, isNull);
    },
  );
  for (final role in ProductRole.values) {
    test(
      '$role restores only server-backed product access and honors revocation',
      () async {
        auth.dispose();
        auth = controller(repo, role: role);
        repo.active = true;
        repo.profile = AccessProfile(
          userId: 'test-user',
          roles: [],
          onboarded: true,
        );
        await auth.initialize();
        expect(auth.stage, AuthStage.pendingApproval);
        repo.profile = AccessProfile(
          userId: 'test-user',
          roles: [role.name],
          onboarded: true,
        );
        await auth.refreshAccess();
        expect(auth.stage, AuthStage.ready);
        repo.profile = AccessProfile(
          userId: 'test-user',
          roles: [],
          onboarded: true,
        );
        await auth.refreshAccess();
        expect(auth.stage, AuthStage.pendingApproval);
        await auth.signOut();
        expect(auth.stage, AuthStage.welcome);
      },
    );
  }
}
