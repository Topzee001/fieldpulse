import 'dart:convert';
import 'package:fieldpulse/src/features/jobs/models/job.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class JobDao {
  final Database _db;
  JobDao._(this._db);
  static Future<JobDao> create() async {
    final db = await DatabaseHelper.instance.database;
    return JobDao._(db);
  }

  Map<String, dynamic> _toSqliteMap(Job job) {
    final json = job.toJson();
    // Keep 'id' so that local DB matches backend ID exactly.
    json.remove('scheduled_time');
    json.remove('status_display');
    json.remove('is_overdue');
    if (json['checklist_schema'] != null) {
      json['checklist_schema'] = jsonEncode(json['checklist_schema']);
    }
    return json;
  }

  Future<void> insertJobs(List<Job> jobs) async {
    final batch = _db.batch();
    for (final job in jobs) {
      batch.insert(
        'jobs',
        _toSqliteMap(job),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<void> insertOrUpdateJob(Job job) async {
    await _db.insert(
      'jobs',
      _toSqliteMap(job),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Job _fromSqliteMap(Map<String, Object?> map) {
    final json = Map<String, dynamic>.from(map);
    if (json['checklist_schema'] != null && json['checklist_schema'] is String) {
      json['checklist_schema'] = jsonDecode(json['checklist_schema'] as String);
    }
    return Job.fromJson(json);
  }

  Future<List<Job>> getJobs({
    String? status,
    String? search,
    int? limit,
    String? cursor,
  }) async {
    String sql = 'SELECT * FROM jobs WHERE is_deleted = 0';
    final List<Object?> args = [];
    if (status != null && status.isNotEmpty) {
      sql += ' AND status = ?';
      args.add(status);
    }
    if (search != null && search.isNotEmpty) {
      sql +=
          ' AND (customer_name LIKE ? OR job_id LIKE ? OR customer_address LIKE ?)';
      final like = '%$search%';
      args.addAll([like, like, like]);
    }
    sql += ' ORDER BY scheduled_start ASC, id ASC';
    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }
    if (cursor != null) {
      sql +=
          ' AND (scheduled_start, id) > (SELECT scheduled_start, id FROM jobs WHERE id = ?)';
      args.add(int.parse(cursor));
    }
    final results = await _db.rawQuery(sql, args);
    return results.map((map) => _fromSqliteMap(map)).toList();
  }

  Future<Job?> getJob(int id) async {
    final results = await _db.query('jobs', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) return _fromSqliteMap(results.first);
    return null;
  }

  Future<void> clearJobs() async {
    await _db.delete('jobs');
  }
}
