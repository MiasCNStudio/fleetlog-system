import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class OfflineLocationQueue {
  static const _dbName = 'fleetlog_tracking.db';
  static const _table = 'location_queue';

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final dbPath = p.join(dir, _dbName);
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            device_uuid TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_queue_session ON $_table (session_id, id)',
        );
      },
    );
    return _db!;
  }

  Future<void> enqueue({
    required int sessionId,
    required String deviceUuid,
    required Map<String, dynamic> pointPayload,
  }) async {
    final db = await _database();
    await db.insert(_table, {
      'session_id': sessionId,
      'device_uuid': deviceUuid,
      'payload_json': jsonEncode(pointPayload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<({int id, Map<String, dynamic> payload})>> peekBatch({
    required int sessionId,
    int limit = 100,
  }) async {
    final db = await _database();
    final rows = await db.query(
      _table,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
      limit: limit,
    );

    return rows.map((row) {
      final raw = row['payload_json'] as String;
      return (
        id: (row['id'] as num).toInt(),
        payload: jsonDecode(raw) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _database();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      _table,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> countForSession(int sessionId) async {
    final db = await _database();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $_table WHERE session_id = ?',
      [sessionId],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> clearSession(int sessionId) async {
    final db = await _database();
    await db.delete(_table, where: 'session_id = ?', whereArgs: [sessionId]);
  }
}
