import 'package:fieldpulse/src/app/providers/jobs_api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../data/local/queue/sync_queue_dao.dart';
import '../repositories/checklist_repository.dart';

final checklistRepositoryProvider = Provider((ref) {
  final api = ref.read(jobsApiProvider);
  return ChecklistRepository(api);
});

final syncQueueDaoProvider = Provider((ref) => SyncQueueDao());

final checklistFormProvider =
    StateNotifierProvider.family<
      ChecklistFormNotifier,
      ChecklistFormState,
      int
    >((ref, jobId) {
      final repo = ref.read(checklistRepositoryProvider);
      final queueDao = ref.read(syncQueueDaoProvider);
      return ChecklistFormNotifier(jobId, repo, queueDao);
    });

class ChecklistFormState {
  final Map<String, dynamic> values;
  final Map<String, String?> errors;
  final bool isDraft;
  final bool isSaving;
  final bool isLoading;

  ChecklistFormState({
    required this.values,
    required this.errors,
    required this.isDraft,
    required this.isSaving,
    required this.isLoading,
  });

  factory ChecklistFormState.initial() {
    return ChecklistFormState(
      values: {},
      errors: {},
      isDraft: true,
      isSaving: false,
      isLoading: true,
    );
  }

  ChecklistFormState copyWith({
    Map<String, dynamic>? values,
    Map<String, String?>? errors,
    bool? isDraft,
    bool? isSaving,
    bool? isLoading,
  }) {
    return ChecklistFormState(
      values: values ?? this.values,
      errors: errors ?? this.errors,
      isDraft: isDraft ?? this.isDraft,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChecklistFormNotifier extends StateNotifier<ChecklistFormState> {
  final int jobId;
  final ChecklistRepository _repository;
  final SyncQueueDao _queueDao;

  ChecklistFormNotifier(this.jobId, this._repository, this._queueDao)
    : super(ChecklistFormState.initial()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final response = await _repository.getChecklistResponse(jobId);
      state = state.copyWith(
        values: response.data,
        isDraft: response.isDraft,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateField(String fieldId, dynamic value) {
    final newValues = Map<String, dynamic>.from(state.values);
    newValues[fieldId] = value;
    // Clear error for this field
    final newErrors = Map<String, String?>.from(state.errors);
    newErrors.remove(fieldId);
    state = state.copyWith(values: newValues, errors: newErrors, isDraft: true);
  }

  void setFieldError(String fieldId, String error) {
    final newErrors = Map<String, String?>.from(state.errors);
    newErrors[fieldId] = error;
    state = state.copyWith(errors: newErrors);
  }

  Future<bool> saveDraft() async {
    state = state.copyWith(isSaving: true);
    try {
      await _repository.saveChecklist(jobId, state.values, isDraft: true);
      state = state.copyWith(isSaving: false, isDraft: true);
      return true;
    } on DioException catch (e) {
      if (_shouldQueue(e)) {
        await _queueChecklistUpdate(isDraft: true);
        state = state.copyWith(isSaving: false, isDraft: true);
        return true;
      }
      state = state.copyWith(isSaving: false);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  Future<bool> submit() async {
    state = state.copyWith(isSaving: true);
    try {
      await _repository.saveChecklist(jobId, state.values, isDraft: false);
      state = state.copyWith(isSaving: false, isDraft: false);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('validation_errors')) {
          final backendErrors = data['validation_errors'] as Map<String, dynamic>;
          final newErrors = Map<String, String?>.from(state.errors);
          
          backendErrors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              newErrors[key] = value.first.toString();
            } else {
              newErrors[key] = value.toString();
            }
          });
          
          state = state.copyWith(isSaving: false, errors: newErrors);
          return false;
        }
      }

      if (_shouldQueue(e)) {
        await _queueChecklistUpdate(isDraft: false);
        state = state.copyWith(isSaving: false, isDraft: false);
        return true;
      }

      state = state.copyWith(isSaving: false);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  bool _shouldQueue(DioException e) {
    if (e.type == DioExceptionType.cancel) return false;

    final statusCode = e.response?.statusCode;
    if (statusCode != null && [400, 401, 403, 409].contains(statusCode)) {
      return false;
    }

    return true;
  }

  Future<void> _queueChecklistUpdate({required bool isDraft}) async {
    await _queueDao.addSyncItem(
      jobId: jobId,
      action: 'checklist_update',
      payload: {
        'data': state.values,
        'isDraft': isDraft,
      },
    );
  }
}
