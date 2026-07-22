import 'dart:io';
import 'package:flutter/material.dart';
import '../models/lifepilot_document.dart';

class PendingAttachmentPreview extends StatelessWidget {
  final PendingDocumentAttachment attachment;
  final VoidCallback onRemove;
  const PendingAttachmentPreview({
    super.key,
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: ListTile(
      leading: attachment.isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(attachment.path),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          : Icon(_icon, size: 42),
      title: Text(
        attachment.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_size(attachment.fileSizeBytes)),
      trailing: IconButton(
        tooltip: 'Remove attachment',
        icon: const Icon(Icons.close),
        onPressed: onRemove,
      ),
    ),
  );
  IconData get _icon => attachment.extension == 'pdf'
      ? Icons.picture_as_pdf_outlined
      : Icons.description_outlined;
  String _size(int b) => b < 1024 * 1024
      ? '${(b / 1024).toStringAsFixed(1)} KB'
      : '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}
