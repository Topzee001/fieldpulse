import 'dart:convert';
import 'package:fieldpulse/src/features/sync/models/sync_queue.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class SyncQueueDao {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<void> addSyncItem({
    required int jobId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _db;
    await db.insert('sync_queue', {
      'job_id': jobId,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
      'completed': 0,
    });
  }

  Future<List<SyncQueueItem>> getPendingItems() async {
    final db = await _db;
    final results = await db.query(
      'sync_queue',
      where: 'completed = 0',
      orderBy: 'created_at ASC',
    );
    return results.map((map) {
      return SyncQueueItem(
        id: map['id'] as int,
        jobId: map['job_id'] as int,
        action: map['action'] as String,
        payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: map['retry_count'] as int? ?? 0,
      );
    }).toList();
  }

  Future<void> incrementRetry(int id) async {
    final db = await _db;
    await db.update(
      'sync_queue',
      {'retry_count': db.rawUpdate('retry_count + 1')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markCompleted(int id) async {
    final db = await _db;
    await db.update('sync_queue', {'completed': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteItem(int id) async {
    final db = await _db;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }
}