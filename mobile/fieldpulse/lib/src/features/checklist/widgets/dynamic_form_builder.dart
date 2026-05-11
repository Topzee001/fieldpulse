import 'package:flutter/material.dart' hide FormField;
import '../models/form_field.dart';
import 'text_form_field.dart';
import 'checkbox_field.dart';
import 'select_field.dart';
import 'photo_field.dart';
import 'signature_field.dart';

class DynamicFormBuilder extends StatelessWidget {
  final List<FormField> fields;
  final int jobId;

  const DynamicFormBuilder({
    super.key,
    required this.fields,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: fields.map((field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildField(field),
        );
      }).toList(),
    );
  }

  Widget _buildField(FormField field) {
    switch (field.type) {
      case FormFieldType.text:
        return ChecklistTextField(
          jobId: jobId,
          fieldId: field.id,
          label: field.label,
          required: field.required,
          validationType: field.validation,
          maxLength: field.maxLength,
          keyboardType: TextInputType.text,
        );
      case FormFieldType.textArea:
        return ChecklistTextField(
          jobId: jobId,
          fieldId: field.id,
          label: field.label,
          required: field.required,
          validationType: field.validation,
          maxLength: field.maxLength,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
        );
      case FormFieldType.number:
        return ChecklistTextField(
          jobId: jobId,
          fieldId: field.id,
          label: field.label,
          required: field.required,
          validationType: 'number',
          keyboardType: TextInputType.number,
        );
      case FormFieldType.checkbox:
        return ChecklistCheckboxField(
          jobId: jobId,
          fieldId: field.id,
          label: field.label,
        );
      case FormFieldType.select:
        return ChecklistSelectField(
          jobId: jobId,
          fieldId: field.id,
          label: field.label,
          options: field.options ?? [],
          required: field.required,
        );
      case FormFieldType.photo:
        return ChecklistPhotoField(
          jobId: jobId,
          fieldId: field.id,
          label: field.label,
          maxPhotos: field.maxPhotos ?? 1,
        );
      case FormFieldType.signature:
        return ChecklistSignatureField(
          jobId: jobId,
          fieldId: field.id,
          label: field.label,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
