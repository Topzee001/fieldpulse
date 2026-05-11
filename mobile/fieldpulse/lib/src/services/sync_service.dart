import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fieldpulse/src/app/providers/jobs_api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/queue/sync_queue_dao.dart';
import '../data/local/dao/conflict_dao.dart';
import '../data/remote/endpoints/jobs_api.dart';
import '../features/sync/models/sync_queue.dart';

class SyncService {
  final JobsApi _jobsApi;
  final SyncQueueDao _queueDao;
  Timer? _timer;
  bool _isSyncing = false;

  SyncService(this._jobsApi, this._queueDao);

  void start() {
    // Attempt to sync every 30 seconds instead of relying on connectivity_plus
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sync();
    });
    // Initial sync
    _sync();
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> _sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _processQueue();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processQueue() async {
    final items = await _queueDao.getPendingItems();
    for (final item in items) {
      final success = await _syncItem(item);
      if (success) {
        await _queueDao.deleteItem(item.id);
      } else {
        // Retry later: incremental backoff
        if (item.retryCount < 5) {
          await _queueDao.incrementRetry(item.id);
        } else {
          // Mark as failed permanently (or keep for manual retry)
          await _queueDao.markCompleted(item.id); // or delete
        }
      }
    }
  }

  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      switch (item.action) {
        case 'photo_upload':
          final fieldId = item.payload['field_id'];
          final localPath = item.payload['local_path'];
          await _jobsApi.uploadPhoto(item.jobId, fieldId, localPath);
          return true;
        case 'signature_upload':
          final localPath = item.payload['local_path'];
          await _jobsApi.uploadSignature(item.jobId, localPath);
          return true;
        case 'checklist_update':
          final data = item.payload['data'];
          final isDraft = item.payload['isDraft'] ?? false;
          await _jobsApi.saveChecklist(item.jobId, data, isDraft: isDraft);
          return true;
        case 'status_update':
          final status = item.payload['status'];
          await _jobsApi.updateJobStatus(item.jobId, status);
          return true;
        default:
          return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Conflict detected – create Conflict record and notify UI
        await _handleConflict(item, e.response?.data);
        return false; // don't delete the queue item yet; we'll keep it until resolved
      }
      // Other errors: will retry later
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleConflict(SyncQueueItem item, dynamic responseData) async {
    // Store conflict in a separate table
    final conflictDao = ConflictDao(); // we'll create this
    await conflictDao.insertConflict({
      'job_id': item.jobId,
      'local_data': item.payload,
      'server_data': responseData?['server_data'] ?? {},
      'conflicting_fields': responseData?['conflicting_fields'] ?? [],
      'created_at': DateTime.now().toIso8601String(),
      'resolved': 0,
    });
    // Optionally trigger a UI refresh (using a provider)
  }
}

final syncServiceProvider = Provider((ref) {
  final api = ref.read(jobsApiProvider);
  final dao = SyncQueueDao();
  return SyncService(api, dao);
});