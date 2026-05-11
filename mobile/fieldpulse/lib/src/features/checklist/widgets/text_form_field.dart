import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/form_provider.dart';
import '../../../core/utils/validators.dart';

class ChecklistTextField extends ConsumerStatefulWidget {
  final int jobId;
  final String fieldId;
  final String label;
  final bool required;
  final String? validationType;
  final int? maxLength;
  final TextInputType keyboardType;
  final int maxLines;

  const ChecklistTextField({
    super.key,
    required this.jobId,
    required this.fieldId,
    required this.label,
    this.required = false,
    this.validationType,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  ConsumerState<ChecklistTextField> createState() => _ChecklistTextFieldState();
}

class _ChecklistTextFieldState extends ConsumerState<ChecklistTextField> {
  late final TextEditingController _controller;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(checklistFormProvider(widget.jobId));
    final initial = state.values[widget.fieldId]?.toString() ?? '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    if (!_hasInteracted) return null;
    return Validators.validateField(
      value,
      required: widget.required,
      type: widget.validationType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checklistFormProvider(widget.jobId));
    final error = state.errors[widget.fieldId];
    // Only show error if it's a non-empty string
    final displayError = (error != null && error.isNotEmpty) ? error : null;

    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: _hasInteracted ? displayError : null,
        counterText: widget.maxLength != null ? null : '',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      onChanged: (newValue) {
        _hasInteracted = true;
        final notifier = ref.read(checklistFormProvider(widget.jobId).notifier);
        notifier.updateField(widget.fieldId, newValue);
        final validationError = _validate(newValue);
        if (validationError != null) {
          notifier.setFieldError(widget.fieldId, validationError);
        }
        // updateField already clears the error via newErrors.remove — no need to set empty string
      },
    );
  }
}
