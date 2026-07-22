import 'package:flutter/material.dart';
import '../models/lifepilot_document.dart';

class DocumentCard extends StatelessWidget {
  final LifePilotDocument document;
  final VoidCallback onTap;
  const DocumentCard({super.key, required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(_icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        document.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${document.category.label} • ${_date(document.createdAt)}',
      ),
      trailing: document.isSensitive
          ? const Icon(Icons.lock_outline, size: 20)
          : null,
      onTap: onTap,
    ),
  );
  IconData get _icon => document.mimeType.startsWith('image/')
      ? Icons.image_outlined
      : (document.extension == 'pdf'
            ? Icons.picture_as_pdf_outlined
            : Icons.description_outlined);
  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
