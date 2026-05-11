import 'package:fieldpulse/src/features/jobs/providers/job_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../repositories/job_repository.dart';

final jobListProvider = StateNotifierProvider<JobListNotifier, JobListState>((
  ref,
) {
  final repoAsync = ref.watch(jobRepositoryProvider);
  return repoAsync.when(
    data: (repo) => JobListNotifier(repo)..loadJobs(refresh: true),
    loading: () => JobListNotifier(null),
    error: (e, _) => JobListNotifier(null)..setError('Failed to initialize: $e'),
  );
});

class JobListState {
  static const Object _unset = Object();

  final List<Job> jobs;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? filterStatus;
  final String? searchQuery;
  final String? nextCursor;

  JobListState({
    this.jobs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filterStatus,
    this.searchQuery,
    this.nextCursor,
  });

  JobListState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _unset,
    Object? filterStatus = _unset,
    Object? searchQuery = _unset,
    Object? nextCursor = _unset,
  }) {
    return JobListState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error == _unset ? this.error : error as String?,
      filterStatus: filterStatus == _unset ? this.filterStatus : filterStatus as String?,
      searchQuery: searchQuery == _unset ? this.searchQuery : searchQuery as String?,
      nextCursor: nextCursor == _unset ? this.nextCursor : nextCursor as String?,
    );
  }
}

class JobListNotifier extends StateNotifier<JobListState> {
  final JobRepository? _repository;

  JobListNotifier(this._repository) : super(JobListState());

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  Future<void> loadJobs({bool refresh = false}) async {
    if (_repository == null) {
      state = state.copyWith(error: 'Repository not available');
      return;
    }
    if (refresh) {
      state = state.copyWith(isLoading: true, jobs: [], nextCursor: null);
    } else if (state.isLoadingMore || state.isLoading) {
      return;
    }

    try {
      final newJobs = await _repository.getJobs(
        status: state.filterStatus,
        search: state.searchQuery,
        forceRefresh: refresh,
      );
      final nextCursor = newJobs.isNotEmpty ? newJobs.last.id.toString() : null;
      state = state.copyWith(
        jobs: refresh ? newJobs : [...state.jobs, ...newJobs],
        isLoading: false,
        isLoadingMore: false,
        error: null,
        nextCursor: nextCursor,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.nextCursor == null || state.isLoadingMore || state.isLoading) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final newJobs = await _repository!.getJobs(
        cursor: state.nextCursor,
        status: state.filterStatus,
        search: state.searchQuery,
        forceRefresh: false,
      );
      final nextCursor = newJobs.isNotEmpty ? newJobs.last.id.toString() : null;
      state = state.copyWith(
        jobs: [...state.jobs, ...newJobs],
        isLoadingMore: false,
        nextCursor: nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setFilter(String? status) {
    state = state.copyWith(filterStatus: status, jobs: [], nextCursor: null);
    loadJobs(refresh: true);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, jobs: [], nextCursor: null);
    loadJobs(refresh: true);
  }

  Future<void> refresh() => loadJobs(refresh: true);
}
