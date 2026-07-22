import 'package:flutter/material.dart';
class VaultLockOverlay extends StatelessWidget {
  final VoidCallback onUnlock; final String? message;
  const VaultLockOverlay({super.key, required this.onUnlock, this.message});
  @override Widget build(BuildContext context)=>Center(child: Card(margin: const EdgeInsets.all(24), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.lock, size: 56, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12),
    Text('Password Vault is locked', style: Theme.of(context).textTheme.titleLarge),
    if (message != null) Padding(padding: const EdgeInsets.only(top:8), child: Text(message!, textAlign: TextAlign.center)),
    const SizedBox(height:16), FilledButton.icon(onPressed:onUnlock, icon: const Icon(Icons.fingerprint), label: const Text('Unlock')),
  ]))));
}
