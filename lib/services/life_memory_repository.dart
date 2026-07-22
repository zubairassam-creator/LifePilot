import 'package:hive/hive.dart';

import '../models/life_memory.dart';
import 'sync_service.dart';

class LifeMemoryRepository {
  static const String _boxName = 'life_memories';
  static Box<Map>? _box;

  static Future<void> initialize() async {
    _box ??= await Hive.openBox<Map>(_boxName);
  }

  static Box<Map> get _memoryBox {
    if (_box == null) {
      throw Exception('LifeMemoryRepository is not initialized.');
    }
    return _box!;
  }

  static Future<void> save(LifeMemory memory) async {
    await _memoryBox.put(memory.id, memory.toJson());
    await SyncService.enqueue(
      localId: memory.id,
      cloudId: memory.cloudId,
      collection: 'life_memories',
      operation: memory.isDeleted ? 'delete' : 'upsert',
      payload: memory.toJson(),
    );
  }

  static Future<void> tombstone(String id) async {
    final existing = get(id);
    if (existing == null) return;
    final deleted = LifeMemory.fromJson({
      ...existing.toJson(),
      'isDeleted': true,
      'status': LifeMemoryStatus.deleted.name,
      'syncStatus': SyncStatus.pendingDelete.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await save(deleted);
  }

  static LifeMemory? get(String id) {
    final value = _memoryBox.get(id);
    return value == null ? null : LifeMemory.fromJson(value);
  }

  static List<LifeMemory> getAll({bool includeDeleted = false}) {
    final memories = _memoryBox.values
        .map(LifeMemory.fromJson)
        .where((m) => includeDeleted || !m.isDeleted)
        .toList();
    memories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return memories;
  }

  static List<LifeMemory> search(String query) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((t) => t.length > 2);
    return getAll().where((memory) {
      final haystack = [
        memory.title,
        memory.originalStatement,
        memory.person,
        memory.subject,
        memory.location,
        memory.description,
      ].whereType<String>().join(' ').toLowerCase();
      return tokens.every(haystack.contains);
    }).toList();
  }

  static List<LifeMemory> pendingSync() => getAll(
    includeDeleted: true,
  ).where((m) => m.syncStatus != SyncStatus.synced).toList();
}
