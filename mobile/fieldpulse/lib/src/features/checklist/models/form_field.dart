import 'package:equatable/equatable.dart';

enum FormFieldType {
  text,
  textArea,
  number,
  select,
  multiSelect,
  dateTime,
  photo,
  signature,
  checkbox,
}

class FormField extends Equatable {
  final String id;
  final String label;
  final FormFieldType type;
  final bool required;
  final String? validation; // email, phone, number
  final num? min;
  final num? max;
  final int? maxLength;
  final List<String>? options; // for select/multi-select
  final int? maxPhotos; // for photo field

  const FormField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.validation,
    this.min,
    this.max,
    this.maxLength,
    this.options,
    this.maxPhotos,
  });

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory FormField.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    FormFieldType type;
    switch (typeStr) {
      case 'text':
        type = FormFieldType.text;
        break;
      case 'text_area':
        type = FormFieldType.textArea;
        break;
      case 'number':
        type = FormFieldType.number;
        break;
      case 'select':
        type = FormFieldType.select;
        break;
      case 'multi_select':
        type = FormFieldType.multiSelect;
        break;
      case 'date_time':
        type = FormFieldType.dateTime;
        break;
      case 'photo':
        type = FormFieldType.photo;
        break;
      case 'signature':
        type = FormFieldType.signature;
        break;
      case 'checkbox':
        type = FormFieldType.checkbox;
        break;
      default:
        type = FormFieldType.text;
    }
    return FormField(
      id: json['id'],
      label: json['label'],
      type: type,
      required: json['required'] ?? false,
      validation: json['validation'],
      min: _parseNum(json['min']),
      max: _parseNum(json['max']),
      maxLength: _parseInt(json['max_length']),
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      maxPhotos: _parseInt(json['max_photos']),
    );
  }

  @override
  List<Object?> get props => [id, label, type, required];
}
