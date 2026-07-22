import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/lifepilot_document.dart';
import '../services/document_encryption_service.dart';
import '../services/document_share_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  final LifePilotDocument document;
  const DocumentViewerScreen({super.key, required this.document});
  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  File? _file;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File(
        '${dir.path}/view_${widget.document.id}.${widget.document.extension}',
      );
      await f.writeAsBytes(
        await DocumentEncryptionService.instance.decryptFile(
          widget.document.encryptedFilePath,
        ),
      );
      if (mounted) setState(() => _file = f);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open this document.');
    }
  }

  @override
  void dispose() {
    final f = _file;
    if (f != null) {
      Future.microtask(() async {
        if (await f.exists()) await f.delete();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.document.displayName)),
    body: Center(
      child: _error != null
          ? Text(_error!)
          : _file == null
          ? const CircularProgressIndicator()
          : widget.document.mimeType.startsWith('image/')
          ? InteractiveViewer(child: Image.file(_file!))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.document.extension == 'pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  size: 72,
                ),
                const SizedBox(height: 12),
                Text(widget.document.originalFileName),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      DocumentShareService.instance.openWith(widget.document),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open with…'),
                ),
              ],
            ),
    ),
  );
}
