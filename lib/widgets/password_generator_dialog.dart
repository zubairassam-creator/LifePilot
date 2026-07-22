import 'dart:math';

import 'package:flutter/material.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+[]{};:,.?';

  final Random _random = Random.secure();
  int _length = 20;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _numberCharacters = true;
  bool _symbolCharacters = true;
  late String _preview;

  @override
  void initState() {
    super.initState();
    _preview = _generatePassword();
  }

  String _generatePassword() {
    final requiredPools = <String>[
      if (_uppercase) _upper,
      if (_lowercase) _lower,
      if (_numberCharacters) _numbers,
      if (_symbolCharacters) _symbols,
    ];
    final pools = requiredPools.isEmpty ? <String>[_lower] : requiredPools;
    final allCharacters = pools.join();
    final characters = <String>[
      for (final pool in pools) pool[_random.nextInt(pool.length)],
      ...List.generate(
        _length - pools.length,
        (_) => allCharacters[_random.nextInt(allCharacters.length)],
      ),
    ];
    characters.shuffle(_random);
    return characters.join();
  }

  void _regenerate() => setState(() => _preview = _generatePassword());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate secure password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _length,
              decoration: const InputDecoration(labelText: 'Length'),
              items: const [16, 20, 24, 28, 32]
                  .map((length) => DropdownMenuItem(value: length, child: Text('$length characters')))
                  .toList(),
              onChanged: (value) {
                _length = value ?? 20;
                _regenerate();
              },
            ),
            CheckboxListTile(value: _uppercase, onChanged: (value) => setState(() { _uppercase = value ?? false; _preview = _generatePassword(); }), title: const Text('Uppercase letters')),
            CheckboxListTile(value: _lowercase, onChanged: (value) => setState(() { _lowercase = value ?? false; _preview = _generatePassword(); }), title: const Text('Lowercase letters')),
            CheckboxListTile(value: _numberCharacters, onChanged: (value) => setState(() { _numberCharacters = value ?? false; _preview = _generatePassword(); }), title: const Text('Numbers')),
            CheckboxListTile(value: _symbolCharacters, onChanged: (value) => setState(() { _symbolCharacters = value ?? false; _preview = _generatePassword(); }), title: const Text('Symbols')),
            const SizedBox(height: 12),
            SelectableText(_preview, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _regenerate, child: const Text('Regenerate')),
        FilledButton(onPressed: () => Navigator.pop(context, _preview), child: const Text('Use password')),
      ],
    );
  }
}
