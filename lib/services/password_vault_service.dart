import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/password_entry.dart';
import 'encryption_service.dart';

class PasswordVaultService {
  PasswordVaultService._();

  static final PasswordVaultService instance = PasswordVaultService._();
  static const String _boxName = 'lifepilot_password_vault_records_v2';
  static const String _legacyBoxName = 'lifepilot_password_vault_records_v1';
  static const MethodChannel _secureWindow = MethodChannel('lifepilot/secure_window');

  final Uuid _uuid = const Uuid();
  final StreamController<List<PasswordEntry>> _entriesController =
      StreamController<List<PasswordEntry>>.broadcast();
  Box<Map>? _box;

  Stream<List<PasswordEntry>> get entriesStream => _entriesController.stream;

  Future<void> initialize() async {
    _box ??= await Hive.openBox<Map>(_boxName);
    await _migrateLegacyEntries();
    _publishEntries();
  }

  List<PasswordEntry> getAll() {
    final entries = (_box?.values ?? const Iterable<Map>.empty())
        .map(PasswordEntry.fromMap)
        .where((entry) => entry.id.isNotEmpty)
        .toList();
    entries.sort((a, b) {
      if (a.favourite != b.favourite) return a.favourite ? -1 : 1;
      return a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase());
    });
    return List.unmodifiable(entries);
  }

  List<PasswordEntry> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();
    return getAll()
        .where(
          (entry) =>
              entry.serviceName.toLowerCase().contains(normalized) ||
              entry.username.toLowerCase().contains(normalized) ||
              entry.website.toLowerCase().contains(normalized) ||
              entry.category.label.toLowerCase().contains(normalized) ||
              entry.notes.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Future<PasswordEntry> add({
    required String serviceName,
    required String username,
    required String password,
    required String website,
    required PasswordCategory category,
    required String notes,
    required bool favourite,
  }) async {
    final now = DateTime.now();
    final entry = PasswordEntry(
      id: _uuid.v4(),
      serviceName: serviceName.trim(),
      username: username.trim(),
      encryptedPassword: await EncryptionService.instance.encryptString(password),
      website: website.trim(),
      category: category,
      notes: notes.trim(),
      dateCreated: now,
      lastModified: now,
      favourite: favourite,
    );
    await _box!.put(entry.id, entry.toMap());
    _publishEntries();
    return entry;
  }

  Future<void> update(
    PasswordEntry entry, {
    required String serviceName,
    required String username,
    String? password,
    required String website,
    required PasswordCategory category,
    required String notes,
    required bool favourite,
  }) async {
    final updated = entry.copyWith(
      serviceName: serviceName.trim(),
      username: username.trim(),
      website: website.trim(),
      category: category,
      notes: notes.trim(),
      favourite: favourite,
      lastModified: DateTime.now(),
      encryptedPassword: password == null || password.isEmpty
          ? null
          : await EncryptionService.instance.encryptString(password),
    );
    await _box!.put(updated.id, updated.toMap());
    _publishEntries();
  }

  Future<void> delete(String id) async {
    await _box!.delete(id);
    _publishEntries();
  }

  Future<String> decryptPassword(PasswordEntry entry) {
    return EncryptionService.instance.decryptString(entry.encryptedPassword);
  }

  Future<void> _migrateLegacyEntries() async {
    if (_box == null || _box!.isNotEmpty) return;
    final legacyBox = await Hive.openBox<Map>(_legacyBoxName);
    for (final legacyEntry in legacyBox.values) {
      final entry = PasswordEntry.fromMap(legacyEntry);
      if (entry.id.isNotEmpty) await _box!.put(entry.id, entry.toMap());
    }
  }

  Future<void> setScreenshotProtection(bool enabled) async {
    try {
      await _secureWindow.invokeMethod<void>(enabled ? 'enable' : 'disable');
    } on PlatformException {
      // Desktop/web builds do not expose the Android secure-window channel.
    } on MissingPluginException {
      // Screenshot protection is best-effort outside supported platforms.
    }
  }

  Future<void> copyUsername(String username) {
    return Clipboard.setData(ClipboardData(text: username));
  }

  Future<void> copyPassword(String password) async {
    await Clipboard.setData(ClipboardData(text: password));
    unawaited(
      Future<void>.delayed(const Duration(seconds: 30), () async {
        final clipboard = await Clipboard.getData('text/plain');
        if (clipboard?.text == password) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      }),
    );
  }

  void _publishEntries() {
    if (!_entriesController.isClosed) _entriesController.add(getAll());
  }
}
