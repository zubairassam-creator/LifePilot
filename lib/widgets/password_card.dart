import 'package:flutter/material.dart';

import '../models/password_entry.dart';

class PasswordCard extends StatelessWidget {
  const PasswordCard({
    super.key,
    required this.entry,
    required this.revealedPassword,
    required this.revealed,
    required this.onToggle,
    required this.onCopyUsername,
    required this.onCopyPassword,
    required this.onEdit,
    required this.onDelete,
  });

  final PasswordEntry entry;
  final String? revealedPassword;
  final bool revealed;
  final VoidCallback onToggle;
  final VoidCallback onCopyUsername;
  final VoidCallback onCopyPassword;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(entry.serviceName.isEmpty ? '?' : entry.serviceName[0].toUpperCase())),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.serviceName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(entry.category.label, style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                    ],
                  ),
                ),
                if (entry.favourite) const Icon(Icons.star, color: Colors.amber),
                PopupMenuButton<String>(
                  onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(label: 'Username', value: entry.username.isEmpty ? '—' : entry.username, onCopy: onCopyUsername),
            _InfoRow(label: 'Password', value: revealed ? (revealedPassword ?? '') : '••••••••••••', onCopy: onCopyPassword),
            if (entry.website.isNotEmpty) _InfoRow(label: 'Website', value: entry.website),
            if (entry.notes.isNotEmpty) _InfoRow(label: 'Notes', value: entry.notes),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onToggle,
                icon: Icon(revealed ? Icons.visibility_off : Icons.visibility),
                label: Text(revealed ? 'Hide password' : 'Reveal password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onCopy});

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 86, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Expanded(child: SelectableText(value)),
          if (onCopy != null) IconButton(onPressed: onCopy, icon: const Icon(Icons.copy), tooltip: 'Copy $label'),
        ],
      ),
    );
  }
}
