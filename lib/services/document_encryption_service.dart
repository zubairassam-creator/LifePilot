import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class DocumentEncryptionService {
  DocumentEncryptionService._();
  static final instance = DocumentEncryptionService._();

  static const _keyName = 'lifepilot_documents_aes_gcm_key_v1';
  static const _secureStorage = FlutterSecureStorage();
  final AesGcm _cipher = AesGcm.with256bits();

  Future<SecretKey> _key() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null) return SecretKey(base64Decode(existing));
    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(key: _keyName, value: base64Encode(bytes));
    return key;
  }

  Future<Directory> vaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/important_documents_vault');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> encryptFile({
    required File source,
    required String documentId,
  }) async {
    final clearBytes = await source.readAsBytes();
    final secretBox = await _cipher.encrypt(
      clearBytes,
      secretKey: await _key(),
    );
    final payload = <int>[
      secretBox.nonce.length,
      ...secretBox.nonce,
      secretBox.mac.bytes.length,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ];
    final dir = await vaultDirectory();
    final out = File('${dir.path}/$documentId.vault');
    await out.writeAsBytes(payload, flush: true);
    return out.path;
  }

  Future<Uint8List> decryptFile(String encryptedPath) async {
    final payload = await File(encryptedPath).readAsBytes();
    final nonceLength = payload[0];
    final nonce = payload.sublist(1, 1 + nonceLength);
    final macLengthIndex = 1 + nonceLength;
    final macLength = payload[macLengthIndex];
    final macStart = macLengthIndex + 1;
    final mac = payload.sublist(macStart, macStart + macLength);
    final cipherText = payload.sublist(macStart + macLength);
    final clear = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: await _key(),
    );
    return Uint8List.fromList(clear);
  }
}
