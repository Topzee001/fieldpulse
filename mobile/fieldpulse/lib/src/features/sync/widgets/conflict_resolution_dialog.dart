import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';

class ConflictResolutionDialog extends ConsumerWidget {
  final int conflictId;
  final int jobId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final List<String> conflictingFields;

  const ConflictResolutionDialog({
    super.key,
    required this.conflictId,
    required this.jobId,
    required this.localData,
    required this.serverData,
    required this.conflictingFields,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Sync Conflict'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This job was modified on the server while you were offline.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Conflicting fields:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...conflictingFields.map((field) => Text('• $field')),
          const SizedBox(height: 16),
          const Text('What would you like to do?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(
              resolveConflictProvider((
                conflictId: conflictId,
                resolution: 'keep_local',
              )).future,
            );
            // Refresh UI after resolution
          },
          child: const Text('Keep My Changes'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(
              resolveConflictProvider((
                conflictId: conflictId,
                resolution: 'keep_server',
              )).future,
            );
          },
          child: const Text('Use Server Version'),
        ),
      ],
    );
  }
}
