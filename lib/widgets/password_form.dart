import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import 'password_generator_dialog.dart';

class PasswordFormValue {
  const PasswordFormValue({
    required this.serviceName,
    required this.username,
    required this.password,
    required this.website,
    required this.category,
    required this.notes,
    required this.favourite,
  });

  final String serviceName;
  final String username;
  final String password;
  final String website;
  final PasswordCategory category;
  final String notes;
  final bool favourite;
}

class PasswordForm extends StatefulWidget {
  const PasswordForm({super.key, this.entry, required this.onSave, required this.saving});

  final PasswordEntry? entry;
  final bool saving;
  final ValueChanged<PasswordFormValue> onSave;

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serviceController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _websiteController;
  late final TextEditingController _notesController;
  late PasswordCategory _category;
  late bool _favourite;
  bool _hidden = true;

  bool get _editing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _serviceController = TextEditingController(text: entry?.serviceName ?? '');
    _usernameController = TextEditingController(text: entry?.username ?? '');
    _passwordController = TextEditingController();
    _websiteController = TextEditingController(text: entry?.website ?? '');
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _category = entry?.category ?? PasswordCategory.personal;
    _favourite = entry?.favourite ?? false;
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final generated = await showDialog<String>(context: context, builder: (_) => const PasswordGeneratorDialog());
    if (generated != null) _passwordController.text = generated;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      PasswordFormValue(
        serviceName: _serviceController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        website: _websiteController.text,
        category: _category,
        notes: _notesController.text,
        favourite: _favourite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(controller: _serviceController, decoration: const InputDecoration(labelText: 'Service name', prefixIcon: Icon(Icons.business)), textInputAction: TextInputAction.next, validator: (value) => value == null || value.trim().isEmpty ? 'Service name is required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username or email', prefixIcon: Icon(Icons.person)), textInputAction: TextInputAction.next),
          const SizedBox(height: 12),
          TextFormField(controller: _passwordController, obscureText: _hidden, decoration: InputDecoration(labelText: _editing ? 'New password (leave blank to keep current)' : 'Password', prefixIcon: const Icon(Icons.key), suffixIcon: IconButton(icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hidden = !_hidden))), validator: (value) => !_editing && (value == null || value.isEmpty) ? 'Password is required' : null),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _generate, icon: const Icon(Icons.auto_fix_high), label: const Text('Generate strong password'))),
          TextFormField(controller: _websiteController, decoration: const InputDecoration(labelText: 'Website or app URL', prefixIcon: Icon(Icons.link)), keyboardType: TextInputType.url),
          const SizedBox(height: 12),
          DropdownButtonFormField<PasswordCategory>(value: _category, decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)), items: PasswordCategory.values.map((category) => DropdownMenuItem(value: category, child: Text(category.label))).toList(), onChanged: (value) => setState(() => _category = value ?? PasswordCategory.other)),
          const SizedBox(height: 12),
          TextFormField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Secure notes', prefixIcon: Icon(Icons.notes))),
          SwitchListTile(value: _favourite, onChanged: (value) => setState(() => _favourite = value), title: const Text('Mark as favourite'), secondary: const Icon(Icons.star)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: widget.saving ? null : _submit, icon: widget.saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save), label: Text(widget.saving ? 'Saving...' : 'Save password')),
        ],
      ),
    );
  }
}
