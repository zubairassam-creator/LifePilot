import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/password_entry.dart';
import '../services/password_vault_service.dart';
import '../services/vault_authentication_service.dart';

class PasswordVaultScreen extends StatefulWidget {
  const PasswordVaultScreen({super.key});

  @override
  State<PasswordVaultScreen> createState() => _PasswordVaultScreenState();
}

class _PasswordVaultScreenState extends State<PasswordVaultScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  List<PasswordEntry> _entries = const [];
  bool _loading = true;
  bool _unlocked = false;
  final Set<String> _revealed = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlockAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      setState(() {
        _unlocked = false;
        _revealed.clear();
      });
    } else if (state == AppLifecycleState.resumed && !_unlocked) {
      _unlockAndLoad();
    }
  }

  Future<void> _unlockAndLoad() async {
    if (mounted) setState(() => _loading = true);
    final ok = await VaultAuthenticationService.instance.authenticate();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _unlocked = false;
      });
      return;
    }
    await PasswordVaultService.instance.initialize();
    final entries = await PasswordVaultService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
      _unlocked = true;
    });
  }

  Future<bool> _reauthenticate(String reason) {
    return VaultAuthenticationService.instance.authenticate(reason: reason);
  }

  Future<void> _reload() async {
    final entries = await PasswordVaultService.instance.getAll();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _addOrEdit([PasswordEntry? existing]) async {
    final result = await showDialog<PasswordEntry>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordEntryDialog(existing: existing),
    );
    if (result == null) return;
    await PasswordVaultService.instance.save(result);
    await _reload();
  }

  Future<void> _delete(PasswordEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete password?'),
        content: Text('Delete the saved entry for ${entry.serviceName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PasswordVaultService.instance.delete(entry.id);
    await _reload();
  }

  Future<void> _toggleReveal(PasswordEntry entry) async {
    if (_revealed.contains(entry.id)) {
      setState(() => _revealed.remove(entry.id));
      return;
    }
    final ok = await _reauthenticate('Authenticate to reveal this password');
    if (ok && mounted) setState(() => _revealed.add(entry.id));
  }

  Future<void> _copyUsername(PasswordEntry entry) async {
    await Clipboard.setData(ClipboardData(text: entry.username));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Username copied')),
    );
  }

  Future<void> _copyPassword(PasswordEntry entry) async {
    final ok = await _reauthenticate('Authenticate to copy this password');
    if (!ok) return;
    await Clipboard.setData(ClipboardData(text: entry.password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied. Clipboard clears in 30 seconds.')),
    );
    Timer(const Duration(seconds: 30), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == entry.password) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  List<PasswordEntry> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _entries;
    return _entries.where((e) {
      return e.serviceName.toLowerCase().contains(q) ||
          e.username.toLowerCase().contains(q) ||
          e.website.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Vault'),
        actions: [
          if (_unlocked)
            IconButton(
              tooltip: 'Add password',
              onPressed: _addOrEdit,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_unlocked
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Password Vault is locked',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _unlockAndLoad,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Unlock'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search service, username or category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(
                                _entries.isEmpty
                                    ? 'No passwords saved yet.'
                                    : 'No matching passwords.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final entry = _filtered[index];
                                final revealed = _revealed.contains(entry.id);
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(child: Icon(Icons.lock)),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    entry.serviceName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(entry.category),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: entry.favourite
                                                  ? 'Remove favourite'
                                                  : 'Mark favourite',
                                              onPressed: () async {
                                                await PasswordVaultService.instance.save(
                                                  entry.copyWith(
                                                    favourite: !entry.favourite,
                                                    updatedAt: DateTime.now(),
                                                  ),
                                                );
                                                await _reload();
                                              },
                                              icon: Icon(
                                                entry.favourite
                                                    ? Icons.star
                                                    : Icons.star_border,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text('Username: ${entry.username.isEmpty ? '—' : entry.username}'),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Password: ${revealed ? entry.password : '••••••••••••'}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: revealed ? 'Hide' : 'Reveal',
                                              onPressed: () => _toggleReveal(entry),
                                              icon: Icon(
                                                revealed
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Wrap(
                                          spacing: 4,
                                          children: [
                                            TextButton.icon(
                                              onPressed: entry.username.isEmpty
                                                  ? null
                                                  : () => _copyUsername(entry),
                                              icon: const Icon(Icons.copy),
                                              label: const Text('Username'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _copyPassword(entry),
                                              icon: const Icon(Icons.password),
                                              label: const Text('Password'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _addOrEdit(entry),
                                              icon: const Icon(Icons.edit),
                                              label: const Text('Edit'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _delete(entry),
                                              icon: const Icon(Icons.delete_outline),
                                              label: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _unlocked
          ? FloatingActionButton.extended(
              onPressed: _addOrEdit,
              icon: const Icon(Icons.add),
              label: const Text('Add Password'),
            )
          : null,
    );
  }
}

class _PasswordEntryDialog extends StatefulWidget {
  final PasswordEntry? existing;

  const _PasswordEntryDialog({this.existing});

  @override
  State<_PasswordEntryDialog> createState() => _PasswordEntryDialogState();
}

class _PasswordEntryDialogState extends State<_PasswordEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _service;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _website;
  late final TextEditingController _notes;
  String _category = 'Other';
  bool _obscure = true;

  static const _categories = [
    'Social',
    'Banking',
    'Government',
    'Education',
    'Shopping',
    'Office',
    'Personal',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _service = TextEditingController(text: e?.serviceName ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    _password = TextEditingController(text: e?.password ?? '');
    _website = TextEditingController(text: e?.website ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? 'Other';
  }

  @override
  void dispose() {
    _service.dispose();
    _username.dispose();
    _password.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _generatePassword(int length) {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const symbols = '!@#\$%^&*()-_=+[]{}';
    final chars = upper + lower + digits + symbols;
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final old = widget.existing;
    Navigator.pop(
      context,
      PasswordEntry(
        id: old?.id ?? '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(999999)}',
        serviceName: _service.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        website: _website.text.trim(),
        category: _category,
        notes: _notes.text.trim(),
        favourite: old?.favourite ?? false,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Password' : 'Edit Password'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _service,
                  decoration: const InputDecoration(labelText: 'Service name *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Service name is required' : null,
                ),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username / Email'),
                ),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Generate:'),
                    const SizedBox(width: 8),
                    for (final length in const [12, 16, 20, 24, 32])
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ActionChip(
                          label: Text('$length'),
                          onPressed: () {
                            _password.text = _generatePassword(length);
                            setState(() => _obscure = false);
                          },
                        ),
                      ),
                  ],
                ),
                TextFormField(
                  controller: _website,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value ?? 'Other'),
                ),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
