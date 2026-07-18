import 'package:hive/hive.dart';

class SyncService {
  static const String _boxName = 'sync_outbox';
  static Box<Map>? _box;

  static Future<void> initialize() async {
    _box ??= await Hive.openBox<Map>(_boxName);
  }

  static Box<Map> get _outbox {
    if (_box == null) throw Exception('SyncService is not initialized.');
    return _box!;
  }

  static Future<void> enqueue({
    required String localId,
    String? cloudId,
    required String collection,
    required String operation,
    Map<String, dynamic> payload = const {},
  }) async {
    final now = DateTime.now().toIso8601String();
    await _outbox.put('${collection}_${localId}_$operation', {
      'localId': localId,
      'cloudId': cloudId,
      'collection': collection,
      'operation': operation,
      'payload': payload,
      'createdAt': now,
      'updatedAt': now,
      'deleted': operation == 'delete',
      'syncStatus': 'pending',
      'retryCount': 0,
    });
  }

  static List<Map<dynamic, dynamic>> pendingChanges() => _outbox.values.toList();

  static Future<void> syncPendingChanges() async {
    // Existing cloud backend integration can drain this outbox here. Keeping the
    // queue local-first prevents temporary connectivity failures from losing data.
  }
}
