import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/form_provider.dart';

class ChecklistSelectField extends StatelessWidget {
  final int jobId;
  final String fieldId;
  final String label;
  final List<String> options;
  final bool required;

  const ChecklistSelectField({
    super.key,
    required this.jobId,
    required this.fieldId,
    required this.label,
    required this.options,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(checklistFormProvider(jobId));
        final value = state.values[fieldId] as String?;
        final notifier = ref.read(checklistFormProvider(jobId).notifier);
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: label),
          value: value,
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (newValue) => notifier.updateField(fieldId, newValue),
          validator: required && (value == null || value.isEmpty)
              ? (_) => 'Required'
              : null,
        );
      },
    );
  }
}
