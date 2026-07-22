import 'package:flutter/material.dart';

import '../services/password_vault_service.dart';
import '../widgets/password_form.dart';

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  bool _saving = false;

  Future<void> _save(PasswordFormValue value) async {
    setState(() => _saving = true);
    await PasswordVaultService.instance.add(
      serviceName: value.serviceName,
      username: value.username,
      password: value.password,
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
      appBar: AppBar(title: const Text('Add password')),
      body: PasswordForm(saving: _saving, onSave: _save),
    );
  }
}
