import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/job_list_provider.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';
import '../../../services/sync_service.dart';
import '../../sync/providers/sync_provider.dart';
import '../../sync/widgets/conflict_resolution_dialog.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).start();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(jobListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    ref.read(syncServiceProvider).dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobListProvider);
    final notifier = ref.read(jobListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(notifier),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by customer, job ID, or address',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (value) => notifier.setSearch(value),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildConflictBanner(ref),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(JobListState state, JobListNotifier notifier) {
    if (state.isLoading && state.jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: notifier.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.jobs.isEmpty) {
      return const Center(child: Text('No jobs found'));
    }
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.jobs.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.jobs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final job = state.jobs[index];
          return JobCard(
            job: job,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog(JobListNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All'),
            onTap: () {
              notifier.setFilter(null);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Pending'),
            onTap: () {
              notifier.setFilter('pending');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('In Progress'),
            onTap: () {
              notifier.setFilter('in_progress');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Completed'),
            onTap: () {
              notifier.setFilter('completed');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(WidgetRef ref) {
    final conflictsAsync = ref.watch(unresolvedConflictsProvider);
    return conflictsAsync.maybeWhen(
      data: (conflicts) {
        if (conflicts.isEmpty) return const SizedBox.shrink();
        return Container(
          color: Colors.red.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${conflicts.length} Unresolved Conflict(s)',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  final conflict = conflicts.first; // Resolve one by one
                  showDialog(
                    context: context,
                    builder: (_) => ConflictResolutionDialog(
                      conflictId: conflict.id,
                      jobId: conflict.jobId,
                      localData: conflict.localData,
                      serverData: conflict.serverData,
                      conflictingFields: conflict.conflictingFields,
                    ),
                  ).then((_) {
                    ref.refresh(unresolvedConflictsProvider);
                  });
                },
                child: const Text('Review', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
