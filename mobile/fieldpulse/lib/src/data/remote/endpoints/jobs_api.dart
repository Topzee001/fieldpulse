import 'package:dio/dio.dart';
import '../../../features/jobs/models/job.dart';

class JobsApi {
  final Dio _dio;

  JobsApi(this._dio);

  Future<List<Job>> getJobs({
    String? cursor,
    String? status,
    String? search,
    DateTime? from,
    DateTime? to,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{};
    if (cursor != null) query['cursor'] = cursor;
    if (status != null) query['status'] = status;
    if (search != null) query['search'] = search;
    if (from != null) query['scheduled_from'] = from.toIso8601String();
    if (to != null) query['scheduled_to'] = to.toIso8601String();
    query['page_size'] = pageSize;

    final response = await _dio.get('jobs/', queryParameters: query);
    final List<dynamic> data = response.data['results'];
    return data.map((json) => Job.fromJson(json)).toList();
  }

  Future<Job> getJobDetail(int id) async {
    final response = await _dio.get('jobs/$id/');
    return Job.fromJson(response.data);
  }

  Future<void> updateJobStatus(int id, String status) async {
    await _dio.patch('jobs/$id/status/', data: {'status': status});
  }

  Future<Map<String, dynamic>> getChecklistResponse(int jobId) async {
    final response = await _dio.get('jobs/$jobId/checklist/');
    return response.data;
  }

  Future<void> saveChecklist(
    int id,
    Map<String, dynamic> data, {
    bool isDraft = true,
  }) async {
    await _dio.patch(
      'jobs/$id/checklist/',
      data: {'data': data, 'is_draft': isDraft},
    );
  }

  Future<void> uploadPhoto(int id, String fieldId, String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
      'field_id': fieldId,
    });
    await _dio.post('jobs/$id/photos/', data: formData);
  }

  Future<void> uploadSignature(int id, String filePath) async {
    final formData = FormData.fromMap({
      'signature': await MultipartFile.fromFile(filePath),
    });
    await _dio.post('jobs/$id/signature/', data: formData);
  }

  Future<Map<String, dynamic>> syncJob(
    int id,
    int version,
    Map<String, dynamic>? checklistData,
    String? status,
  ) async {
    final payload = <String, dynamic>{'version': version};
    if (checklistData != null) payload['checklist_data'] = checklistData;
    if (status != null) payload['status'] = status;
    final response = await _dio.post('jobs/$id/sync/', data: payload);
    return response.data;
  }

  Future<void> resolveConflict(int conflictId, String resolution) async {
    await _dio.post(
      '/sync/conflicts/$conflictId/',
      data: {'resolution': resolution},
    );
  }
}
