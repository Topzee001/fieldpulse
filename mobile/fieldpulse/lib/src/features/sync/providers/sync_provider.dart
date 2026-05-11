import 'dart:convert';

import 'package:fieldpulse/src/app/providers/jobs_api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conflict.dart';
import '../../../data/local/dao/conflict_dao.dart';
import '../../../data/remote/endpoints/jobs_api.dart';

final conflictDaoProvider = Provider((ref) => ConflictDao());
final unresolvedConflictsProvider = FutureProvider<List<Conflict>>((ref) async {
  final dao = ref.read(conflictDaoProvider);
  final maps = await dao.getUnresolvedConflicts();
  return maps.map((map) => Conflict(
    id: map['id'],
    jobId: map['job_id'],
    localData: jsonDecode(map['local_data']),
    serverData: jsonDecode(map['server_data']),
    conflictingFields: jsonDecode(map['conflicting_fields']),
    createdAt: DateTime.parse(map['created_at']),
    resolved: map['resolved'] == 1,
  )).toList();
});

final resolveConflictProvider = FutureProvider.family<void, ({int conflictId, String resolution})>((ref, params) async {
  final dao = ref.read(conflictDaoProvider);
  final api = ref.read(jobsApiProvider);
  // Send resolution to backend
  await api.resolveConflict(params.conflictId, params.resolution);
  // Mark as resolved locally
  await dao.resolveConflict(params.conflictId, params.resolution);
});