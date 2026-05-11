import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/form_provider.dart';

class ChecklistCheckboxField extends StatelessWidget {
  final int jobId;
  final String fieldId;
  final String label;

  const ChecklistCheckboxField({
    super.key,
    required this.jobId,
    required this.fieldId,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(checklistFormProvider(jobId));
        final value = state.values[fieldId] ?? false;
        final notifier = ref.read(checklistFormProvider(jobId).notifier);
        return CheckboxListTile(
          title: Text(label),
          value: value,
          onChanged: (newValue) => notifier.updateField(fieldId, newValue),
        );
      },
    );
  }
}
