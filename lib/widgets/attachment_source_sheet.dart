import 'package:flutter/material.dart';
import '../services/document_picker_service.dart';

class AttachmentSourceSheet extends StatelessWidget {
  const AttachmentSourceSheet({super.key});

  static Future<AttachmentSource?> show(BuildContext context) =>
      showModalBottomSheet<AttachmentSource>(
        context: context,
        showDragHandle: true,
        builder: (context) => const AttachmentSourceSheet(),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Add document', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, AttachmentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, AttachmentSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Files'),
              onTap: () => Navigator.pop(context, AttachmentSource.files),
            ),
          ]),
        ),
      );
}
