import 'package:flutter/services.dart';

/// Android-only screen protection used by Password Vault.
///
/// The native side applies FLAG_SECURE while the vault route is open, which
/// blocks screenshots and hides the vault from the recent-apps preview.
class VaultScreenSecurityService {
  VaultScreenSecurityService._();

  static const MethodChannel _channel = MethodChannel(
    'lifepilot/vault_security',
  );

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod<void>('enableSecureScreen');
    } on MissingPluginException {
      // Non-Android platforms do not currently provide this channel.
    } on PlatformException {
      // Keep the vault usable if the platform cannot apply the flag.
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('disableSecureScreen');
    } on MissingPluginException {
      // Non-Android platforms do not currently provide this channel.
    } on PlatformException {
      // Nothing else to clean up when the platform rejects the request.
    }
  }
}
