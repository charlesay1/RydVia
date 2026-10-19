import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rydvia_core/rydvia_core.dart';
import 'package:rydvia_models/rydvia_models.dart';
import 'package:rydvia_logging/rydvia_logging.dart';
import 'auth_repository.dart';

enum AuthStage { welcome, code, checking, onboarding, pendingApproval, ready }

class AuthController extends ChangeNotifier {
  AuthController({
    required this.repository,
    required this.role,
    required this.config,
    required this.logger,
  });
  final AuthRepository repository;
  final ProductRole role;
  final AppConfig config;
  final SafeLogger logger;
  AuthStage stage = AuthStage.checking;
  bool busy = false;
  String? message;
  String? phone;
  DateTime? resendAt;
  AccessProfile? profile;
  bool _disposed = false;
  StreamSubscription<bool>? _subscription;
  int _generation = 0;

  Future<void> initialize() async {
    _subscription = repository.sessionChanges.listen(
      (active) {
        if (!active) {
          _generation++;
          profile = null;
          phone = null;
          stage = AuthStage.welcome;
          busy = false;
          _emit();
        } else if (!busy) {
          unawaited(refreshAccess());
        }
      },
      onError: (Object error, StackTrace stack) {
        _generation++;
        profile = null;
        busy = false;
        stage = AuthStage.checking;
        message =
            'Your session could not be refreshed. Check your connection and try again.';
        logger.record(OperationalEvent.sessionExpired);
        _emit();
      },
    );
    await refreshAccess();
  }

  Future<void> refreshAccess() async {
    if (busy || _disposed) return;
    if (!repository.hasSession) {
      stage = AuthStage.welcome;
      _emit();
      return;
    }
    final generation = ++_generation;
    busy = true;
    message = null;
    stage = AuthStage.checking;
    _emit();
    try {
      final access = await repository.accessProfile();
      if (generation != _generation || _disposed) return;
      profile = access;
      stage = !access.onboarded
          ? AuthStage.onboarding
          : access.permits(role)
          ? AuthStage.ready
          : AuthStage.pendingApproval;
    } catch (error) {
      if (generation != _generation || _disposed) return;
      final failure = authFailure(error);
      message = failure.message;
      if (failure.code == 'session') {
        stage = AuthStage.welcome;
        try {
          await repository.signOut();
        } catch (_) {
          /* no raw error logging */
        }
      }
      logger.record(OperationalEvent.authRequestFailed);
    } finally {
      if (generation == _generation && !_disposed) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> sendCode(String input, {DateTime? now}) async {
    if (busy || _disposed) return;
    final time = now ?? DateTime.now();
    if (resendAt != null && time.isBefore(resendAt!)) return;
    await _run(() async {
      final normalized = normalizeGhanaPhone(input);
      await repository.requestCode(normalized);
      if (_disposed) return;
      phone = normalized;
      resendAt = time.add(Duration(seconds: config.resendSeconds));
      stage = AuthStage.code;
    });
  }

  Future<void> verify(String code) async {
    if (busy || phone == null || _disposed) return;
    await _run(() async {
      if (!validOtp(code, config.otpLength)) {
        throw AppFailure('otp', 'Enter the ${config.otpLength}-digit code.');
      }
      await repository.verifyCode(phone!, code);
    });
    if (message == null && repository.hasSession && !_disposed)
      await refreshAccess();
  }

  Future<void> onboard(String name) async {
    if (busy || _disposed) return;
    if (name.trim().length < 2 || name.trim().length > 80) {
      message = 'Enter a name between 2 and 80 characters.';
      _emit();
      return;
    }
    await _run(() => repository.completeOnboarding(name.trim(), role));
    if (message == null && !_disposed) await refreshAccess();
  }

  void editPhone() {
    if (busy) return;
    stage = AuthStage.welcome;
    message = null;
    _emit();
  }

  void editProfile() {
    if (busy || _disposed) return;
    stage = AuthStage.onboarding;
    message = null;
    _emit();
  }

  Future<void> signOut() async {
    if (busy || _disposed) return;
    await _run(repository.signOut);
    if (message == null) {
      profile = null;
      phone = null;
      stage = AuthStage.welcome;
      _emit();
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (busy || _disposed) return;
    busy = true;
    message = null;
    _emit();
    try {
      await operation();
    } catch (error) {
      message = authFailure(error).message;
      logger.record(OperationalEvent.authRequestFailed);
    } finally {
      if (!_disposed) {
        busy = false;
        _emit();
      }
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
