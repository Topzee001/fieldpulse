import 'package:fieldpulse/src/app/providers/jobs_api_provider.dart';
import 'package:fieldpulse/src/data/local/dao/job_dao.dart';
import 'package:fieldpulse/src/features/jobs/repositories/job_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobRepositoryProvider = FutureProvider((ref) async {
  final api = ref.read(jobsApiProvider);
  final dao = await JobDao.create();
  return JobRepository(api, dao);
});
