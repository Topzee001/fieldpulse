import '../../../data/remote/endpoints/jobs_api.dart';
import '../models/checklist_response.dart';

class ChecklistRepository {
  final JobsApi _api;

  ChecklistRepository(this._api);

  Future<ChecklistResponse> getChecklistResponse(int jobId) async {
    try {
      final response = await _api.getChecklistResponse(jobId);
      return ChecklistResponse.fromJson(response);
    } catch (e) {
      // Return empty response if not found
      return ChecklistResponse(
        data: {},
        isDraft: true,
        lastModified: DateTime.now(),
      );
    }
  }

  Future<void> saveChecklist(int jobId, Map<String, dynamic> data, {bool isDraft = true}) async {
    await _api.saveChecklist(jobId, data, isDraft: isDraft);
  }
}