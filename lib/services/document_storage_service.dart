import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/lifepilot_document.dart';
import 'document_encryption_service.dart';

class DocumentStorageService {
  DocumentStorageService._();
  static final instance = DocumentStorageService._();
  static const _boxName = 'lifepilot_documents';
  static const _uuid = Uuid();
  late Box<String> _box;

  Future<void> initialize() async => _box = await Hive.openBox<String>(_boxName);

  List<LifePilotDocument> getAllDocuments() => _box.values.map(LifePilotDocument.decode).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<LifePilotDocument> search(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return getAllDocuments();
    return getAllDocuments().where((d) => _normalize('${d.displayName} ${d.originalFileName} ${d.description ?? ''} ${d.category.label}').contains(q)).toList();
  }

  LifePilotDocument? findBest(String query) {
    final q = _normalize(_expandSynonyms(query));
    final docs = getAllDocuments();
    final exact = docs.where((d) => _normalize(_expandSynonyms(d.displayName)) == q).toList();
    if (exact.length == 1) return exact.single;
    final contains = docs.where((d) => _normalize(_expandSynonyms(d.displayName)).contains(q) || q.contains(_normalize(_expandSynonyms(d.displayName)))).toList();
    if (contains.length == 1) return contains.single;
    final searched = search(q);
    return searched.length == 1 ? searched.single : null;
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

  String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  String _expandSynonyms(String value) => value.toLowerCase().replaceAll('aadhar', 'aadhaar').replaceAll('uid', 'aadhaar').replaceAll('pan card', 'pan').replaceAll('driving license', 'driving licence').replaceAll(RegExp(r'\bdl\b'), 'driving licence').replaceAll('voter card', 'voter id');
}
