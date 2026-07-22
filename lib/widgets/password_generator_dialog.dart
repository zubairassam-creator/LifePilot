import 'dart:math';
import 'package:flutter/material.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});
  @override State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}
class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  int length = 16; bool upper = true, lower = true, numbers = true, symbols = true;
  String preview = '';
  static const _u='ABCDEFGHIJKLMNOPQRSTUVWXYZ', _l='abcdefghijklmnopqrstuvwxyz', _n='0123456789', _s='!@#\$%^&*()-_=+[]{};:,.?';
  @override void initState(){super.initState(); _generate();}
  void _generate(){
    var chars = '${upper ? _u : ''}${lower ? _l : ''}${numbers ? _n : ''}${symbols ? _s : ''}';
    if (chars.isEmpty) chars = _l;
    final r = Random.secure();
    setState(()=> preview = List.generate(length, (_) => chars[r.nextInt(chars.length)]).join());
  }
  @override Widget build(BuildContext context)=>AlertDialog(
    title: const Text('Generate Password'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<int>(value:length, decoration: const InputDecoration(labelText:'Length'), items:[12,16,20,24,32].map((e)=>DropdownMenuItem(value:e, child:Text('$e'))).toList(), onChanged:(v){length=v??16; _generate();}),
      CheckboxListTile(value: upper, onChanged:(v){upper=v??false; _generate();}, title: const Text('Uppercase')),
      CheckboxListTile(value: lower, onChanged:(v){lower=v??false; _generate();}, title: const Text('Lowercase')),
      CheckboxListTile(value: numbers, onChanged:(v){numbers=v??false; _generate();}, title: const Text('Numbers')),
      CheckboxListTile(value: symbols, onChanged:(v){symbols=v??false; _generate();}, title: const Text('Symbols')),
      SelectableText(preview, style: Theme.of(context).textTheme.titleMedium),
    ])),
    actions:[TextButton(onPressed:_generate, child: const Text('Regenerate')), FilledButton(onPressed:()=>Navigator.pop(context, preview), child: const Text('Use Password'))],
  );
}
