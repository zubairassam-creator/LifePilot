import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  EncryptionService._();
  static final instance = EncryptionService._();

  static const _keyName = 'lifepilot_password_vault_aes_256_key_v1';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final AesGcm _cipher = AesGcm.with256bits();

  Future<SecretKey> _key() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null) return SecretKey(base64Decode(existing));
    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(key: _keyName, value: base64Encode(bytes));
    return key;
  }

  Future<String> encryptString(String clearText) async {
    final box = await _cipher.encrypt(utf8.encode(clearText), secretKey: await _key());
    return jsonEncode({
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'cipherText': base64Encode(box.cipherText),
    });
  }

  Future<String> decryptString(String encryptedPayload) async {
    final payload = jsonDecode(encryptedPayload) as Map<String, dynamic>;
    final clear = await _cipher.decrypt(
      SecretBox(
        base64Decode(payload['cipherText'] as String),
        nonce: base64Decode(payload['nonce'] as String),
        mac: Mac(base64Decode(payload['mac'] as String)),
      ),
      secretKey: await _key(),
    );
    return utf8.decode(clear);
  }
}
