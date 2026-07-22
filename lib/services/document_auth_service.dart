import 'package:local_auth/local_auth.dart';

class DocumentAuthResult {
  final bool success;
  final String? message;
  const DocumentAuthResult(this.success, [this.message]);
}

class DocumentAuthService {
  DocumentAuthService._();
  static final instance = DocumentAuthService._();
  final LocalAuthentication _auth = LocalAuthentication();

  Future<DocumentAuthResult> authenticate(String reason) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported)
        return const DocumentAuthResult(
          false,
          'Device security is not available on this phone.',
        );
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return DocumentAuthResult(
        ok,
        ok ? null : 'Authentication was cancelled or failed.',
      );
    } catch (_) {
      return const DocumentAuthResult(
        false,
        'Could not verify your identity. Check your device security settings.',
      );
    }
  }
}
