import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/lifepilot_document.dart';
import '../core/input_normalizer.dart';
import 'document_encryption_service.dart';

class DocumentStorageService {
  DocumentStorageService._();
  static final instance = DocumentStorageService._();
  static const _boxName = 'lifepilot_documents';
  static const _uuid = Uuid();
  late Box<String> _box;

  Future<void> initialize() async => _box = await Hive.openBox<String>(_boxName);

  List<LifePilotDocument> getAllDocuments() => _box.values.map(LifePilotDocument.decode).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<LifePilotDocument> search(String query) => findMatches(query);

  List<LifePilotDocument> findMatches(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return getAllDocuments();
    final docs = getAllDocuments();
    final exact = docs.where((d) => _normalize(d.displayName) == q).toList();
    if (exact.isNotEmpty) return exact;
    final displayContains = docs.where((d) {
      final name = _normalize(d.displayName);
      return name.contains(q) || q.contains(name);
    }).toList();
    if (displayContains.isNotEmpty) return displayContains;
    final allFieldContains = docs.where((d) => _documentText(d).contains(q)).toList();
    if (allFieldContains.isNotEmpty) return allFieldContains;
    final qTokens = q.split(' ').where((t) => t.length > 2).toSet();
    return docs.where((d) {
      final tokens = _documentText(d).split(' ').where((t) => t.length > 2).toSet();
      return qTokens.intersection(tokens).length >= (qTokens.length == 1 ? 1 : 2);
    }).toList();
  }

  LifePilotDocument? findBest(String query) {
    final matches = findMatches(query);
    return matches.length == 1 ? matches.single : null;
  }

  Future<LifePilotDocument> save({required PendingDocumentAttachment attachment, required String displayName, required DocumentCategory category, required bool isSensitive, String? description}) async {
    final id = _uuid.v4();
    final encryptedPath = await DocumentEncryptionService.instance.encryptFile(source: File(attachment.path), documentId: id);
    final now = DateTime.now();
    final doc = LifePilotDocument(id: id, displayName: displayName, originalFileName: attachment.fileName, encryptedFilePath: encryptedPath, mimeType: attachment.mimeType, extension: attachment.extension, fileSizeBytes: attachment.fileSizeBytes, category: category, isSensitive: isSensitive, description: description, createdAt: now, updatedAt: now);
    await _box.put(id, doc.encode());
    return doc;
  }

  Future<void> update(LifePilotDocument document) async => _box.put(document.id, document.copyWith(updatedAt: DateTime.now()).encode());

  Future<void> delete(LifePilotDocument document) async {
    final file = File(document.encryptedFilePath);
    if (await file.exists()) await file.delete();
    await _box.delete(document.id);
  }

  String _documentText(LifePilotDocument d) => _normalize(
        '${d.displayName} ${d.originalFileName} ${d.description ?? ''} ${d.category.label}',
      );

  String _normalize(String value) => const InputNormalizer().normalize(value).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
