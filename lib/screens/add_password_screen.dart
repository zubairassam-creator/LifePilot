import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/password_vault_service.dart';
import '../widgets/password_generator_dialog.dart';

class AddPasswordScreen extends StatefulWidget { const AddPasswordScreen({super.key}); @override State<AddPasswordScreen> createState()=>_AddPasswordScreenState(); }
class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _form=GlobalKey<FormState>(); final service=TextEditingController(), username=TextEditingController(), password=TextEditingController(), website=TextEditingController(), notes=TextEditingController();
  PasswordCategory category=PasswordCategory.social; bool hidden=true, favourite=false, saving=false;
  @override void dispose(){service.dispose();username.dispose();password.dispose();website.dispose();notes.dispose();super.dispose();}
  Future<void> _generate() async { final value = await showDialog<String>(context: context, builder: (_) => const PasswordGeneratorDialog()); if(value!=null) password.text=value; }
  Future<void> _save() async { if(!_form.currentState!.validate()) return; setState(()=>saving=true); await PasswordVaultService.instance.add(serviceName: service.text, username: username.text, password: password.text, website: website.text, category: category, notes: notes.text, favourite: favourite); if(mounted) Navigator.pop(context, true); }
  @override Widget build(BuildContext context)=>Scaffold(appBar: AppBar(title: const Text('Add Password')), body: Form(key:_form, child: ListView(padding: const EdgeInsets.all(16), children:[
    TextFormField(controller:service, decoration: const InputDecoration(labelText:'Service Name'), validator:(v)=>v==null||v.trim().isEmpty?'Service Name is required':null),
    TextFormField(controller:username, decoration: const InputDecoration(labelText:'Username / Email')),
    TextFormField(controller:password, obscureText:hidden, decoration: InputDecoration(labelText:'Password', suffixIcon: IconButton(icon:Icon(hidden?Icons.visibility:Icons.visibility_off), onPressed:()=>setState(()=>hidden=!hidden))), validator:(v)=>v==null||v.isEmpty?'Password is required':null),
    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed:_generate, icon: const Icon(Icons.auto_fix_high), label: const Text('Generate Password'))),
    TextFormField(controller:website, decoration: const InputDecoration(labelText:'Website')),
    DropdownButtonFormField(value:category, decoration: const InputDecoration(labelText:'Category'), items:PasswordCategory.values.map((c)=>DropdownMenuItem(value:c, child:Text(c.label))).toList(), onChanged:(v)=>setState(()=>category=v??PasswordCategory.other)),
    TextFormField(controller:notes, maxLines:3, decoration: const InputDecoration(labelText:'Notes')),
    SwitchListTile(value:favourite, onChanged:(v)=>setState(()=>favourite=v), title: const Text('Favourite')),
    const SizedBox(height:16), FilledButton(onPressed:saving?null:_save, child: Text(saving?'Saving...':'Save')),
  ])));
}
