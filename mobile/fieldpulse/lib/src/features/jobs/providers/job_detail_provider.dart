import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import 'job_repository_provider.dart';

final jobDetailProvider = FutureProvider.family<Job, int>((ref, jobId) async {
  final repo = await ref.watch(jobRepositoryProvider.future);
  return await repo.getJobDetail(jobId, forceRefresh: true);
});

final updateJobStatusProvider =
    FutureProvider.family<void, ({int jobId, String status})>((
      ref,
      params,
    ) async {
      final repo = await ref.read(jobRepositoryProvider.future);
      await repo.updateJobStatus(params.jobId, params.status);
    });

// Provider to access checklist response (will be expanded later)
final checklistResponseProvider = StateProvider<Map<String, dynamic>>(
  (ref) => {},
);
