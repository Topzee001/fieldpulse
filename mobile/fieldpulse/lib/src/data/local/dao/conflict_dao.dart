import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ConflictDao {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<void> insertConflict(Map<String, dynamic> conflict) async {
    final db = await _db;
    await db.insert('conflicts', {
      'job_id': conflict['job_id'],
      'local_data': jsonEncode(conflict['local_data']),
      'server_data': jsonEncode(conflict['server_data']),
      'conflicting_fields': jsonEncode(conflict['conflicting_fields']),
      'created_at': conflict['created_at'],
      'resolved': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnresolvedConflicts() async {
    final db = await _db;
    return await db.query('conflicts', where: 'resolved = 0');
  }

  Future<void> resolveConflict(int id, String resolution) async {
    final db = await _db;
    await db.update('conflicts', {
      'resolved': 1,
      'resolution': resolution,
      'resolved_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }
}