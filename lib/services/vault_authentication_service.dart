import 'package:local_auth/local_auth.dart';

class VaultAuthenticationService {
  VaultAuthenticationService._();

  static final VaultAuthenticationService instance =
      VaultAuthenticationService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate({
    String reason = 'Authenticate to access Password Vault',
  }) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return true;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
