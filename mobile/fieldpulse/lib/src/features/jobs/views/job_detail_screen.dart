import 'dart:io' show Platform;
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/job_detail_provider.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../../checklist/models/form_field.dart';
import '../../checklist/widgets/dynamic_form_builder.dart';
import '../../checklist/providers/form_provider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  late final int jobId;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    jobId = widget.jobId;
  }


  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(Job job) async {
    final destination = job.latitude != null && job.longitude != null
        ? '${job.latitude},${job.longitude}'
        : Uri.encodeComponent(job.customerAddress);

    Uri uri;
    if (Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?daddr=$destination&dirflg=d');
    } else {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInMaps(Job job) async {
    final query = job.latitude != null && job.longitude != null
        ? '${job.latitude},${job.longitude}'
        : Uri.encodeComponent(job.customerAddress);

    Uri uri;
    if (Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?q=$query');
    } else {
      uri = Uri.parse('geo:0,0?q=$query');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Status update

  Future<void> _updateStatus(Job job, JobStatus newStatus) async {
    final statusStr = _statusToApiString(newStatus);
    setState(() => _isUpdatingStatus = true);
    try {
      await ref.read(
        updateJobStatusProvider((jobId: job.id, status: statusStr)).future,
      );
      ref.invalidate(jobDetailProvider(job.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_statusLabel(newStatus)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  String _statusToApiString(JobStatus s) {
    switch (s) {
      case JobStatus.pending:
        return 'pending';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.cancelled:
        return 'cancelled';
    }
  }

  String _statusLabel(JobStatus s) {
    switch (s) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.cancelled:
        return Colors.grey;
    }
  }

  JobStatus? _nextStatus(JobStatus current) {
    switch (current) {
      case JobStatus.pending:
        return JobStatus.inProgress;
      case JobStatus.inProgress:
        return JobStatus.completed;
      default:
        return null;
    }
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        elevation: 0,
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading job', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(jobDetailProvider(jobId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (job) => _buildContent(job),
      ),
    );
  }

  Widget _buildContent(Job job) {
    final fields = _parseChecklistSchema(job.checklistSchema);
    final formState = ref.watch(checklistFormProvider(jobId));
    final formNotifier = ref.read(checklistFormProvider(jobId).notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _buildStatusBanner(job),
          const SizedBox(height: 16),

          // Customer info
          _buildSection(
            title: 'Customer',
            icon: Icons.person_outline,
            child: _buildCustomerInfo(job),
          ),
          const SizedBox(height: 12),

          // Job info
          _buildSection(
            title: 'Job Details',
            icon: Icons.work_outline,
            child: _buildJobInfo(job),
          ),
          const SizedBox(height: 12),

          // Navigation
          _buildNavigationButtons(job),
          const SizedBox(height: 12),

          // Status action
          _buildStatusAction(job),

          // Checklist
          if (fields.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              title: 'Checklist',
              icon: Icons.checklist,
              child: Column(
                children: [
                  if (formState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    DynamicFormBuilder(fields: fields, jobId: jobId),
                  const SizedBox(height: 16),
                  _buildFormActions(formState, formNotifier),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // UI Components

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(Job job) {
    final color = _statusColor(job.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            _statusLabel(job.status),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            job.jobId,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.customerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        // Tappable phone
        if (job.customerPhone != null && job.customerPhone!.isNotEmpty)
          InkWell(
            onTap: () => _launchPhone(job.customerPhone!),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    job.customerPhone!,
                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        // Tappable address
        InkWell(
          onTap: () => _openInMaps(job),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.customerAddress,
                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobInfo(Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.schedule, 'Scheduled', job.formattedTime),
        if (job.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          _infoRow(Icons.description_outlined, 'Description', job.description!),
        ],
        if (job.notes?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          _infoRow(Icons.note_outlined, 'Notes', job.notes!),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(Job job) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openInMaps(job),
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('View on Map'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _launchMaps(job),
            icon: const Icon(Icons.navigation_outlined, size: 20),
            label: const Text('Navigate'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusAction(Job job) {
    final next = _nextStatus(job.status);
    if (next == null) {
      // Completed or Cancelled — no action
      return const SizedBox.shrink();
    }

    final label = job.status == JobStatus.pending
        ? 'Start Job'
        : 'Complete Job';
    final color = job.status == JobStatus.pending
        ? Colors.blue
        : Colors.green;
    final icon = job.status == JobStatus.pending
        ? Icons.play_arrow_rounded
        : Icons.check_circle_outline;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdatingStatus ? null : () => _updateStatus(job, next),
        icon: _isUpdatingStatus
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildFormActions(
      ChecklistFormState formState, ChecklistFormNotifier formNotifier) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: formState.isSaving
                ? null
                : () async {
                    final success = await formNotifier.saveDraft();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              success ? 'Draft saved' : 'Failed to save draft'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            icon: formState.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Draft'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: formState.isSaving
                ? null
                : () async {
                    final success = await formNotifier.submit();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Checklist submitted'
                              : 'Failed to submit'),
                          backgroundColor:
                              success ? Colors.green : Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            icon: formState.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 18),
            label: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  List<FormField> _parseChecklistSchema(Map<String, dynamic>? schema) {
    if (schema == null) return [];
    final fieldsJson = schema['fields'] as List? ?? [];
    return fieldsJson.map((json) => FormField.fromJson(json)).toList();
  }
}