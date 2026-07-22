import 'package:flutter/material.dart';
import '../models/lifepilot_document.dart';
import '../services/document_auth_service.dart';
import '../services/document_share_service.dart';
import '../services/document_storage_service.dart';
import 'document_viewer_screen.dart';

class DocumentDetailsScreen extends StatefulWidget {
  final LifePilotDocument document;
  const DocumentDetailsScreen({super.key, required this.document});
  @override
  State<DocumentDetailsScreen> createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends State<DocumentDetailsScreen> {
  late LifePilotDocument _doc = widget.document;
  Future<bool> _auth(String reason) async {
    if (!_doc.isSensitive) return true;
    final r = await DocumentAuthService.instance.authenticate(reason);
    if (!r.success && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message ?? 'Authentication failed.')),
      );
    return r.success;
  }

  Future<void> _open() async {
    if (!await _auth('Authenticate to open this document')) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: _doc)),
    );
  }

  Future<void> _share() async {
    if (!await _auth('Authenticate to share this document')) return;
    try {
      await DocumentShareService.instance.share(_doc);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share this document.')),
        );
    }
  }

  Future<void> _edit() async {
    if (!await _auth('Authenticate to change this document')) return;
    final name = TextEditingController(text: _doc.displayName);
    var cat = _doc.category;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rename or change category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Document name'),
            ),
            DropdownButtonFormField(
              value: cat,
              items: DocumentCategory.values
                  .map((x) => DropdownMenuItem(value: x, child: Text(x.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) cat = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _doc = _doc.copyWith(displayName: name.text.trim(), category: cat);
      await DocumentStorageService.instance.update(_doc);
      if (mounted) setState(() {});
    }
  }

  Future<void> _delete() async {
    final warn = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete “${_doc.displayName}”?'),
        content: const Text(
          'This will permanently remove the document from LifePilot.\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (warn != true) return;
    final r = await DocumentAuthService.instance.authenticate(
      'Authenticate to delete this document',
    );
    if (!r.success) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.message ?? 'Authentication failed.')),
        );
      return;
    }
    final finalOk = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Final confirmation'),
        content: const Text('Delete permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (finalOk == true) {
      try {
        await DocumentStorageService.instance.delete(_doc);
        if (mounted) Navigator.pop(context, true);
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete this document.')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_doc.displayName)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(
          _doc.mimeType.startsWith('image/')
              ? Icons.image_outlined
              : Icons.description_outlined,
          size: 80,
        ),
        Text(
          _doc.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text('Category: ${_doc.category.label}'),
        if (_doc.description != null) Text('Description: ${_doc.description}'),
        Text('Original filename: ${_doc.originalFileName}'),
        Text('File type: ${_doc.extension.toUpperCase()}'),
        Text('File size: ${(_doc.fileSizeBytes / 1024).toStringAsFixed(1)} KB'),
        Text('Date added: ${_doc.createdAt}'),
        Text('Last modified: ${_doc.updatedAt}'),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _open,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open'),
        ),
        OutlinedButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
        OutlinedButton.icon(
          onPressed: _edit,
          icon: const Icon(Icons.edit),
          label: const Text('Rename / Change category'),
        ),
        OutlinedButton.icon(
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
      ],
    ),
  );
}
