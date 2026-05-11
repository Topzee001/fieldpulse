import 'dart:async';
import 'package:fieldpulse/src/features/jobs/models/job_status.dart';
import '../../../data/local/dao/job_dao.dart';
import '../../../data/remote/endpoints/jobs_api.dart';
import '../models/job.dart';

class JobRepository {
  final JobsApi _api;
  final JobDao _dao;

  JobRepository(this._api, this._dao);

  /// Always try API first, fall back to local cache on any failure.
  Future<List<Job>> getJobs({
    String? cursor,
    String? status,
    String? search,
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) async {
    try {
      final remoteJobs = await _api.getJobs(
        cursor: cursor,
        status: status,
        search: search,
        from: from,
        to: to,
      );
      // Cache remotely fetched jobs locally
      try {
        await _dao.insertJobs(remoteJobs);
      } catch (dbError) {
        print('[JobRepository] Failed to cache jobs locally: $dbError');
      }
      return remoteJobs;
    } catch (apiError) {
      print('[JobRepository] API fetch failed: $apiError');
      // Fallback to local cache
      try {
        final localJobs = await _dao.getJobs(status: status, search: search);
        if (localJobs.isNotEmpty) return localJobs;
      } catch (dbError) {
        print('[JobRepository] Local DB fetch also failed: $dbError');
      }
      // Re-throw original API error so UI can display it
      throw Exception('Failed to load jobs: $apiError');
    }
  }

  Future<Job> getJobDetail(int id, {bool forceRefresh = false}) async {
    try {
      final job = await _api.getJobDetail(id);
      try {
        await _dao.insertOrUpdateJob(job);
      } catch (_) {}
      return job;
    } catch (apiError) {
      print('[JobRepository] API detail fetch failed: $apiError');
      try {
        final local = await _dao.getJob(id);
        if (local != null) return local;
      } catch (_) {}
      throw Exception('Failed to load job detail: $apiError');
    }
  }

  Future<void> updateJobStatus(int id, String status) async {
    try {
      await _api.updateJobStatus(id, status);
      final updated = await _api.getJobDetail(id);
      await _dao.insertOrUpdateJob(updated);
    } catch (apiError) {
      print('[JobRepository] Status update API failed: $apiError');
      // Update locally as fallback
      final job = await _dao.getJob(id);
      if (job != null) {
        // Map string status to enum safely
        JobStatus mappedStatus;
        if (status == 'in_progress') {
          mappedStatus = JobStatus.inProgress;
        } else {
          mappedStatus = JobStatus.values.firstWhere(
            (e) => e.name == status,
            orElse: () => JobStatus.pending,
          );
        }

        final updatedJob = Job(
          id: job.id,
          jobId: job.jobId,
          customerName: job.customerName,
          customerPhone: job.customerPhone,
          customerEmail: job.customerEmail,
          customerAddress: job.customerAddress,
          latitude: job.latitude,
          longitude: job.longitude,
          description: job.description,
          notes: job.notes,
          scheduledStart: job.scheduledStart,
          scheduledEnd: job.scheduledEnd,
          status: mappedStatus,
          checklistSchema: job.checklistSchema,
          version: job.version,
          actualStart: job.actualStart,
          actualCompletion: job.actualCompletion,
          createdAt: job.createdAt,
          updatedAt: DateTime.now(),
        );
        await _dao.insertOrUpdateJob(updatedJob);
      }
      
      // Still throw the API error so the UI knows it didn't sync immediately
      throw Exception('API failed, saved locally: $apiError');
    }
  }
}
