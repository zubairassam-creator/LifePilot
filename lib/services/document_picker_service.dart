import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../models/lifepilot_document.dart';

enum AttachmentSource { camera, gallery, files }

class DocumentPickResult {
  final PendingDocumentAttachment? attachment;
  final String? error;
  const DocumentPickResult({this.attachment, this.error});
}

class DocumentPickerService {
  DocumentPickerService._();
  static final instance = DocumentPickerService._();
  static const maxFileSizeBytes = 25 * 1024 * 1024;
  static const supportedExtensions = {
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
    'heif',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt',
  };
  final ImagePicker _imagePicker = ImagePicker();

  Future<DocumentPickResult> pick(AttachmentSource source) async {
    try {
      switch (source) {
        case AttachmentSource.camera:
          final x = await _imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 95,
          );
          return x == null
              ? const DocumentPickResult()
              : _validate(x.path, x.name);
        case AttachmentSource.gallery:
          final x = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 100,
          );
          return x == null
              ? const DocumentPickResult()
              : _validate(x.path, x.name);
        case AttachmentSource.files:
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: supportedExtensions.toList(),
          );
          if (result == null || result.files.single.path == null)
            return const DocumentPickResult();
          final f = result.files.single;
          return _validate(f.path!, f.name);
      }
    } catch (_) {
      return const DocumentPickResult(
        error: 'Could not access the selected document.',
      );
    }
  }

  Future<DocumentPickResult> _validate(String path, String name) async {
    final file = File(path);
    if (!await file.exists())
      return const DocumentPickResult(
        error: 'The selected file is no longer accessible.',
      );
    final size = await file.length();
    if (size > maxFileSizeBytes)
      return const DocumentPickResult(
        error: 'This file is larger than the 25 MB limit.',
      );
    final ext = name.split('.').last.toLowerCase();
    if (!supportedExtensions.contains(ext))
      return const DocumentPickResult(
        error: 'This file type is not supported yet.',
      );
    final mime = lookupMimeType(path) ?? _fallbackMime(ext);
    return DocumentPickResult(
      attachment: PendingDocumentAttachment(
        path: path,
        fileName: name,
        mimeType: mime,
        extension: ext,
        fileSizeBytes: size,
      ),
    );
  }

  String _fallbackMime(String ext) => switch (ext) {
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt' => 'text/plain',
    'heic' || 'heif' => 'image/heif',
    _ => 'application/octet-stream',
  };
}
