import 'package:flutter/material.dart';
import '../models/password_entry.dart';

class PasswordCard extends StatelessWidget {
  final PasswordEntry entry; final String? revealedPassword; final bool revealed; final VoidCallback onToggle; final VoidCallback onCopyUsername; final VoidCallback onCopyPassword; final VoidCallback onEdit; final VoidCallback onDelete;
  const PasswordCard({super.key, required this.entry, required this.revealedPassword, required this.revealed, required this.onToggle, required this.onCopyUsername, required this.onCopyPassword, required this.onEdit, required this.onDelete});
  @override Widget build(BuildContext context)=>Card(margin: const EdgeInsets.symmetric(horizontal:16, vertical:8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Row(children:[Text('🔐 ${entry.serviceName}', style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700)), const Spacer(), if(entry.favourite) const Icon(Icons.star, color:Colors.amber)]),
    const SizedBox(height:10), Text('Username:', style:Theme.of(context).textTheme.labelLarge), SelectableText(entry.username.isEmpty?'—':entry.username), const SizedBox(height:8), Text('Password:', style:Theme.of(context).textTheme.labelLarge), Text(revealed ? (revealedPassword ?? '') : '•••••••••••'), const SizedBox(height:8), Text('Category:', style:Theme.of(context).textTheme.labelLarge), Text(entry.category.label),
    Wrap(spacing:4, children:[TextButton.icon(onPressed:onToggle, icon:Icon(revealed?Icons.visibility_off:Icons.visibility), label:Text(revealed?'Hide':'View')), TextButton.icon(onPressed:onCopyUsername, icon:const Icon(Icons.person), label:const Text('Copy Username')), TextButton.icon(onPressed:onCopyPassword, icon:const Icon(Icons.password), label:const Text('Copy Password')), IconButton(onPressed:onEdit, icon:const Icon(Icons.edit), tooltip:'Edit'), IconButton(onPressed:onDelete, icon:const Icon(Icons.delete_outline), tooltip:'Delete')]),
  ])));
}
