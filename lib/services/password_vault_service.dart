import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../models/password_entry.dart';

class PasswordVaultService {
  PasswordVaultService._();

  static final PasswordVaultService instance = PasswordVaultService._();

  static const _boxName = 'lifepilot_password_vault';
  static const _keyName = 'lifepilot_password_vault_aes_key_v1';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final AesGcm _algorithm = AesGcm.with256bits();

  Box<String>? _box;
  SecretKey? _secretKey;

  Future<void> initialize() async {
    _box ??= await Hive.openBox<String>(_boxName);
    _secretKey ??= await _loadOrCreateKey();
  }

  Future<SecretKey> _loadOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) {
      return SecretKey(base64Decode(existing));
    }

    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _secureStorage.write(key: _keyName, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  Future<List<PasswordEntry>> getAll() async {
    await initialize();
    final result = <PasswordEntry>[];
    for (final encrypted in _box!.values) {
      try {
        result.add(await _decryptEntry(encrypted));
      } catch (_) {
        // Corrupt or undecryptable entries are ignored without exposing secrets.
      }
    }
    result.sort((a, b) {
      if (a.favourite != b.favourite) return a.favourite ? -1 : 1;
      return a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase());
    });
    return result;
  }

  Future<void> save(PasswordEntry entry) async {
    await initialize();
    final encrypted = await _encryptEntry(entry);
    await _box!.put(entry.id, encrypted);
  }

  Future<void> delete(String id) async {
    await initialize();
    await _box!.delete(id);
  }

  Future<String> _encryptEntry(PasswordEntry entry) async {
    final secretBox = await _algorithm.encrypt(
      utf8.encode(jsonEncode(entry.toJson())),
      secretKey: _secretKey!,
    );
    return jsonEncode({
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });
  }

  Future<PasswordEntry> _decryptEntry(String payload) async {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final box = SecretBox(
      base64Decode(map['cipherText'] as String),
      nonce: base64Decode(map['nonce'] as String),
      mac: Mac(base64Decode(map['mac'] as String)),
    );
    final clear = await _algorithm.decrypt(box, secretKey: _secretKey!);
    return PasswordEntry.fromJson(
      jsonDecode(utf8.decode(clear)) as Map<String, dynamic>,
    );
  }
}
