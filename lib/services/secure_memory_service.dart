import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/secure_memory_note.dart';

class SecureMemoryService {
  SecureMemoryService._();

  static final SecureMemoryService instance = SecureMemoryService._();
  static const _boxName = 'secure_memory_notes_v1';
  static const _keyName = 'secure_memory_aes_gcm_key_v1';
  static const _secureStorage = FlutterSecureStorage();
  static const _uuid = Uuid();

  final AesGcm _cipher = AesGcm.with256bits();
  Box<String>? _box;

  Future<void> initialize() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  Box<String> get _notesBox {
    final box = _box;
    if (box == null) {
      throw StateError('SecureMemoryService has not been initialized.');
    }
    return box;
  }

  Future<SecretKey> _key() async {
    final saved = await _secureStorage.read(key: _keyName);
    if (saved != null) return SecretKey(base64Decode(saved));
    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(key: _keyName, value: base64Encode(bytes));
    return key;
  }

  Future<String> _encryptText(String clearText) async {
    final box = await _cipher.encrypt(
      utf8.encode(clearText),
      secretKey: await _key(),
    );
    return jsonEncode({
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'cipherText': base64Encode(box.cipherText),
    });
  }

  Future<String> _decryptText(String payload) async {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final clear = await _cipher.decrypt(
      SecretBox(
        base64Decode(map['cipherText'] as String),
        nonce: base64Decode(map['nonce'] as String),
        mac: Mac(base64Decode(map['mac'] as String)),
      ),
      secretKey: await _key(),
    );
    return utf8.decode(clear);
  }

  Future<Directory> _vaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory('${base.path}/secure_memory_vault');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<List<SecureMemoryNote>> getAll() async {
    await initialize();
    final notes = <SecureMemoryNote>[];
    for (final payload in _notesBox.values) {
      try {
        notes.add(SecureMemoryNote.decode(await _decryptText(payload)));
      } catch (_) {
        // Ignore damaged records so one bad note cannot block the vault.
      }
    }
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<void> save(SecureMemoryNote note) async {
    await initialize();
    await _notesBox.put(note.id, await _encryptText(note.encode()));
  }

  Future<SecureMemoryAttachment> encryptAttachment({
    required String sourcePath,
    required String fileName,
    required String mimeType,
  }) async {
    final source = File(sourcePath);
    final clearBytes = await source.readAsBytes();
    final encrypted = await _cipher.encrypt(
      clearBytes,
      secretKey: await _key(),
    );
    final payload = <int>[
      encrypted.nonce.length,
      ...encrypted.nonce,
      encrypted.mac.bytes.length,
      ...encrypted.mac.bytes,
      ...encrypted.cipherText,
    ];
    final id = _uuid.v4();
    final directory = await _vaultDirectory();
    final output = File('${directory.path}/$id.memory');
    await output.writeAsBytes(payload, flush: true);
    return SecureMemoryAttachment(
      id: id,
      fileName: fileName,
      encryptedPath: output.path,
      mimeType: mimeType,
      fileSizeBytes: clearBytes.length,
    );
  }

  Future<Uint8List> decryptAttachment(
    SecureMemoryAttachment attachment,
  ) async {
    final payload = await File(attachment.encryptedPath).readAsBytes();
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

  Future<File> createTemporaryDecryptedFile(
    SecureMemoryAttachment attachment,
  ) async {
    final temp = await getTemporaryDirectory();
    final safeName = attachment.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${temp.path}/secure_memory_${attachment.id}_$safeName');
    await file.writeAsBytes(await decryptAttachment(attachment), flush: true);
    return file;
  }

  Future<void> delete(SecureMemoryNote note) async {
    for (final attachment in note.attachments) {
      final file = File(attachment.encryptedPath);
      if (await file.exists()) await file.delete();
    }
    await _notesBox.delete(note.id);
  }

  Future<void> deleteAttachment(SecureMemoryAttachment attachment) async {
    final file = File(attachment.encryptedPath);
    if (await file.exists()) await file.delete();
  }
}
