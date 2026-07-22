import 'dart:async';

import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../services/password_vault_service.dart';
import '../widgets/password_form.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key, required this.entry});

  final PasswordEntry entry;

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(PasswordVaultService.instance.retainScreenshotProtection());
  }

  @override
  void dispose() {
    unawaited(PasswordVaultService.instance.releaseScreenshotProtection());
    super.dispose();
  }

  Future<void> _save(PasswordFormValue value) async {
    setState(() => _saving = true);
    await PasswordVaultService.instance.update(
      widget.entry,
      serviceName: value.serviceName,
      username: value.username,
      password: value.password.isEmpty ? null : value.password,
      website: value.website,
      category: value.category,
      notes: value.notes,
      favourite: value.favourite,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit password')),
      body: PasswordForm(entry: widget.entry, saving: _saving, onSave: _save),
    );
  }
}
