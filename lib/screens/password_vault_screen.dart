import 'dart:async';

import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../services/biometric_service.dart';
import '../services/password_vault_service.dart';
import '../widgets/password_card.dart';
import '../widgets/vault_lock_overlay.dart';
import 'add_password_screen.dart';
import 'edit_password_screen.dart';

class PasswordVaultScreen extends StatefulWidget {
  const PasswordVaultScreen({super.key});

  @override
  State<PasswordVaultScreen> createState() => _PasswordVaultScreenState();
}

class _PasswordVaultScreenState extends State<PasswordVaultScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _revealedPasswords = <String, String>{};
  bool _locked = true;
  bool _searching = false;
  String? _lockMessage;
  Duration _autoLockAfter = const Duration(minutes: 1);
  Timer? _autoLockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(PasswordVaultService.instance.setScreenshotProtection(true));
    unawaited(_unlock());
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(PasswordVaultService.instance.setScreenshotProtection(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) _lock();
  }

  List<PasswordEntry> get _entries => PasswordVaultService.instance.search(_searchController.text);

  void _touch() {
    _autoLockTimer?.cancel();
    if (!_locked) _autoLockTimer = Timer(_autoLockAfter, _lock);
  }

  void _lock() {
    if (!mounted) return;
    setState(() {
      _locked = true;
      _revealedPasswords.clear();
    });
  }

  Future<void> _unlock() async {
    final result = await BiometricService.instance.authenticate('Unlock your LifePilot Password Vault');
    if (!mounted) return;
    setState(() => _lockMessage = result.message);
    if (result.success) {
      setState(() => _locked = false);
      _touch();
    }
  }

  Future<bool> _reauthenticate(String reason) async {
    _touch();
    final result = await BiometricService.instance.authenticate(reason);
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Authentication failed.')));
    }
    return result.success;
  }

  Future<void> _togglePassword(PasswordEntry entry) async {
    if (_revealedPasswords.containsKey(entry.id)) {
      setState(() => _revealedPasswords.remove(entry.id));
      return;
    }
    if (!await _reauthenticate('Reveal password for ${entry.serviceName}')) return;
    final password = await PasswordVaultService.instance.decryptPassword(entry);
    if (mounted) setState(() => _revealedPasswords[entry.id] = password);
  }

  Future<void> _copyPassword(PasswordEntry entry) async {
    if (!await _reauthenticate('Copy password for ${entry.serviceName}')) return;
    final password = await PasswordVaultService.instance.decryptPassword(entry);
    await PasswordVaultService.instance.copyPassword(password);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied. Clipboard clears in 30 seconds.')));
    }
  }

  Future<void> _delete(PasswordEntry entry) async {
    _touch();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete password?'),
        content: Text('Delete the saved password for ${entry.serviceName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await PasswordVaultService.instance.delete(entry.id);
    if (mounted) setState(() => _revealedPasswords.remove(entry.id));
  }

  Future<void> _openAdd() async {
    _touch();
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddPasswordScreen()));
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _openEdit(PasswordEntry entry) async {
    _touch();
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditPasswordScreen(entry: entry)));
    if (changed == true && mounted) setState(() => _revealedPasswords.remove(entry.id));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _touch,
      onPanDown: (_) => _touch(),
      child: Scaffold(
        appBar: AppBar(
          title: _searching ? TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(hintText: 'Search passwords'), onChanged: (_) => setState(() {})) : const Text('Password Vault'),
          actions: [
            PopupMenuButton<Duration>(
              icon: const Icon(Icons.lock_clock),
              tooltip: 'Auto-lock timeout',
              onSelected: (value) => setState(() => _autoLockAfter = value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: Duration(seconds: 30), child: Text('Auto-lock: 30 seconds')),
                PopupMenuItem(value: Duration(minutes: 1), child: Text('Auto-lock: 1 minute')),
                PopupMenuItem(value: Duration(minutes: 5), child: Text('Auto-lock: 5 minutes')),
              ],
            ),
            IconButton(icon: Icon(_searching ? Icons.close : Icons.search), onPressed: () => setState(() { _searching = !_searching; if (!_searching) _searchController.clear(); })),
            IconButton(icon: const Icon(Icons.add), onPressed: _locked ? null : _openAdd),
          ],
        ),
        body: _locked ? VaultLockOverlay(onUnlock: _unlock, message: _lockMessage) : _VaultList(entries: _entries, revealedPasswords: _revealedPasswords, onToggle: _togglePassword, onCopyPassword: _copyPassword, onEdit: _openEdit, onDelete: _delete, onCopyUsername: (entry) async { _touch(); await PasswordVaultService.instance.copyUsername(entry.username); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username copied.'))); }),
      ),
    );
  }
}

class _VaultList extends StatelessWidget {
  const _VaultList({required this.entries, required this.revealedPasswords, required this.onToggle, required this.onCopyPassword, required this.onEdit, required this.onDelete, required this.onCopyUsername});

  final List<PasswordEntry> entries;
  final Map<String, String> revealedPasswords;
  final ValueChanged<PasswordEntry> onToggle;
  final ValueChanged<PasswordEntry> onCopyPassword;
  final ValueChanged<PasswordEntry> onEdit;
  final ValueChanged<PasswordEntry> onDelete;
  final ValueChanged<PasswordEntry> onCopyUsername;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No passwords found. Tap + to save your first login.')));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return PasswordCard(entry: entry, revealedPassword: revealedPasswords[entry.id], revealed: revealedPasswords.containsKey(entry.id), onToggle: () => onToggle(entry), onCopyUsername: () => onCopyUsername(entry), onCopyPassword: () => onCopyPassword(entry), onEdit: () => onEdit(entry), onDelete: () => onDelete(entry));
      },
    );
  }
}
