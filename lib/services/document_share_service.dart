import 'dart:async';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/lifepilot_document.dart';
import 'document_encryption_service.dart';

class DocumentShareService {
  DocumentShareService._();
  static final instance = DocumentShareService._();

  Future<File> _tempClearFile(LifePilotDocument doc) async {
    final dir = await getTemporaryDirectory();
    final safeName = doc.originalFileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._ -]'),
      '_',
    );
    final file = File('${dir.path}/${doc.id}_$safeName');
    await file.writeAsBytes(
      await DocumentEncryptionService.instance.decryptFile(
        doc.encryptedFilePath,
      ),
      flush: true,
    );
    Timer(const Duration(minutes: 5), () async {
      if (await file.exists()) await file.delete();
    });
    return file;
  }

  Future<void> share(LifePilotDocument doc) async {
    final file = await _tempClearFile(doc);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: doc.mimeType, name: doc.originalFileName),
        ],
        text: doc.displayName,
      ),
    );
  }

  Future<void> openWith(LifePilotDocument doc) async {
    final file = await _tempClearFile(doc);
    await OpenFilex.open(file.path, type: doc.mimeType);
  }
}
