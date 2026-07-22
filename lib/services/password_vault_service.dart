import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/password_entry.dart';
import 'encryption_service.dart';

class PasswordVaultService {
  PasswordVaultService._();
  static final instance = PasswordVaultService._();
  static const String _boxName = 'lifepilot_password_vault_records_v1';
  static const _secureWindow = MethodChannel('lifepilot/secure_window');
  final _uuid = const Uuid();
  Box<Map>? _box;

  Future<void> initialize() async {
    _box ??= await Hive.openBox<Map>(_boxName);
  }

  List<PasswordEntry> getAll() {
    final entries = (_box?.values ?? const Iterable<Map>.empty())
        .map(PasswordEntry.fromMap)
        .toList(growable: false);
    return entries..sort((a, b) => b.favourite == a.favourite ? a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()) : (b.favourite ? 1 : -1));
  }

  List<PasswordEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return getAll().where((entry) =>
      entry.serviceName.toLowerCase().contains(q) ||
      entry.username.toLowerCase().contains(q) ||
      entry.website.toLowerCase().contains(q) ||
      entry.category.label.toLowerCase().contains(q)
    ).toList(growable: false);
  }

  Future<PasswordEntry> add({required String serviceName, required String username, required String password, required String website, required PasswordCategory category, required String notes, required bool favourite}) async {
    final now = DateTime.now();
    final entry = PasswordEntry(
      id: _uuid.v4(), serviceName: serviceName.trim(), username: username.trim(),
      encryptedPassword: await EncryptionService.instance.encryptString(password), website: website.trim(),
      category: category, notes: notes.trim(), dateCreated: now, lastModified: now, favourite: favourite,
    );
    await _box!.put(entry.id, entry.toMap());
    return entry;
  }

  Future<void> update(PasswordEntry entry, {required String serviceName, required String username, String? password, required String website, required PasswordCategory category, required String notes, required bool favourite}) async {
    final updated = entry.copyWith(
      serviceName: serviceName.trim(), username: username.trim(), website: website.trim(), category: category,
      notes: notes.trim(), favourite: favourite, lastModified: DateTime.now(),
      encryptedPassword: password == null ? null : await EncryptionService.instance.encryptString(password),
    );
    await _box!.put(updated.id, updated.toMap());
  }

  Future<void> delete(String id) => _box!.delete(id);
  Future<String> decryptPassword(PasswordEntry entry) => EncryptionService.instance.decryptString(entry.encryptedPassword);

  Future<void> setScreenshotProtection(bool enabled) async {
    try { await _secureWindow.invokeMethod<void>(enabled ? 'enable' : 'disable'); } catch (_) {}
  }

  Future<void> copyUsername(String username) => Clipboard.setData(ClipboardData(text: username));
  Future<void> copyPassword(String password) async {
    await Clipboard.setData(ClipboardData(text: password));
    Future<void>.delayed(const Duration(seconds: 30), () => Clipboard.setData(const ClipboardData(text: '')));
  }
}
