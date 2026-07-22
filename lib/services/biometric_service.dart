import 'package:local_auth/local_auth.dart';

class BiometricResult {
  final bool success;
  final String? message;
  const BiometricResult(this.success, [this.message]);
}

class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();
  final LocalAuthentication _auth = LocalAuthentication();
  int _failures = 0;
  DateTime? _delayUntil;

  Duration? get activeDelay {
    final until = _delayUntil;
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Future<BiometricResult> authenticate(String reason) async {
    final delay = activeDelay;
    if (delay != null) {
      return BiometricResult(false, 'Too many failed attempts. Try again in ${delay.inSeconds + 1} seconds.');
    }
    try {
      if (!await _auth.isDeviceSupported()) {
        return const BiometricResult(false, 'Device credential, fingerprint, or face unlock is required.');
      }
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok) {
        _failures = 0;
        _delayUntil = null;
        return const BiometricResult(true);
      }
      _recordFailure();
      return const BiometricResult(false, 'Authentication failed or was cancelled.');
    } catch (_) {
      _recordFailure();
      return const BiometricResult(false, 'Could not verify your identity.');
    }
  }

  void _recordFailure() {
    _failures += 1;
    if (_failures == 5) _delayUntil = DateTime.now().add(const Duration(seconds: 30));
    if (_failures > 5) _delayUntil = DateTime.now().add(const Duration(minutes: 1));
  }
}
