import 'package:flutter_test/flutter_test.dart';
import 'package:fieldpulse/src/features/checklist/models/form_field.dart';

void main() {
  group('FormField.fromJson', () {
    test('parses text field correctly', () {
      final json = {
        'id': 'name',
        'label': 'Customer Name',
        'type': 'text',
        'required': true,
        'validation': 'email',
      };
      final field = FormField.fromJson(json);

      expect(field.id, 'name');
      expect(field.label, 'Customer Name');
      expect(field.type, FormFieldType.text);
      expect(field.required, true);
      expect(field.validation, 'email');
    });

    test('parses text_area field with maxLength', () {
      final json = {
        'id': 'notes',
        'label': 'Notes',
        'type': 'text_area',
        'required': false,
        'max_length': 500,
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.textArea);
      expect(field.maxLength, 500);
      expect(field.required, false);
    });

    test('parses number field with min/max', () {
      final json = {
        'id': 'quantity',
        'label': 'Quantity',
        'type': 'number',
        'required': true,
        'min': 1,
        'max': 100,
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.number);
      expect(field.min, 1);
      expect(field.max, 100);
    });

    test('parses number field with string min/max', () {
      final json = {
        'id': 'temperature',
        'label': 'Temperature',
        'type': 'number',
        'min': '0',
        'max': '200',
      };
      final field = FormField.fromJson(json);

      expect(field.min, 0);
      expect(field.max, 200);
    });

    test('parses select field with options', () {
      final json = {
        'id': 'priority',
        'label': 'Priority',
        'type': 'select',
        'options': ['Low', 'Medium', 'High'],
        'required': true,
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.select);
      expect(field.options, ['Low', 'Medium', 'High']);
    });

    test('parses multi_select field', () {
      final json = {
        'id': 'tags',
        'label': 'Tags',
        'type': 'multi_select',
        'options': ['Urgent', 'VIP', 'Callback'],
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.multiSelect);
      expect(field.options, hasLength(3));
    });

    test('parses date_time field', () {
      final json = {
        'id': 'arrival',
        'label': 'Arrival Time',
        'type': 'date_time',
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.dateTime);
    });

    test('parses photo field with maxPhotos', () {
      final json = {
        'id': 'before_photo',
        'label': 'Before Photo',
        'type': 'photo',
        'max_photos': 3,
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.photo);
      expect(field.maxPhotos, 3);
    });

    test('parses signature field', () {
      final json = {
        'id': 'signature',
        'label': 'Customer Signature',
        'type': 'signature',
        'required': true,
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.signature);
      expect(field.required, true);
    });

    test('parses checkbox field', () {
      final json = {
        'id': 'customer_satisfied',
        'label': 'Customer Satisfied',
        'type': 'checkbox',
        'required': true,
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.checkbox);
      expect(field.required, true);
    });

    test('defaults unknown type to text', () {
      final json = {
        'id': 'unknown',
        'label': 'Unknown Field',
        'type': 'fancy_widget',
      };
      final field = FormField.fromJson(json);

      expect(field.type, FormFieldType.text);
    });

    test('defaults required to false when not provided', () {
      final json = {
        'id': 'optional',
        'label': 'Optional Field',
        'type': 'text',
      };
      final field = FormField.fromJson(json);

      expect(field.required, false);
    });

    test('handles null options gracefully', () {
      final json = {
        'id': 'field',
        'label': 'Field',
        'type': 'select',
      };
      final field = FormField.fromJson(json);

      expect(field.options, isNull);
    });

    test('handles null max_photos gracefully', () {
      final json = {
        'id': 'photo',
        'label': 'Photo',
        'type': 'photo',
      };
      final field = FormField.fromJson(json);

      expect(field.maxPhotos, isNull);
    });
  });

  group('FormField equality', () {
    test('two FormFields with same id/label/type/required are equal', () {
      const a = FormField(id: 'x', label: 'X', type: FormFieldType.text, required: true);
      const b = FormField(id: 'x', label: 'X', type: FormFieldType.text, required: true);
      expect(a, equals(b));
    });

    test('two FormFields with different ids are not equal', () {
      const a = FormField(id: 'x', label: 'X', type: FormFieldType.text);
      const b = FormField(id: 'y', label: 'X', type: FormFieldType.text);
      expect(a, isNot(equals(b)));
    });
  });

  group('full checklist schema parsing', () {
    test('parses a complete schema matching seed_jobs format', () {
      final schema = {
        'fields': [
          {'id': 'work_performed', 'type': 'text_area', 'label': 'Work Performed', 'required': true},
          {'id': 'parts_used', 'type': 'text', 'label': 'Parts Used', 'required': false},
          {'id': 'customer_satisfied', 'type': 'checkbox', 'label': 'Customer Satisfied', 'required': true},
          {'id': 'before_photo', 'type': 'photo', 'label': 'Before Photo', 'required': false},
          {'id': 'after_photo', 'type': 'photo', 'label': 'After Photo', 'required': false},
          {'id': 'signature', 'type': 'signature', 'label': 'Customer Signature', 'required': true},
        ],
      };

      final fields = (schema['fields'] as List)
          .map((json) => FormField.fromJson(json))
          .toList();

      expect(fields, hasLength(6));
      expect(fields[0].type, FormFieldType.textArea);
      expect(fields[0].required, true);
      expect(fields[1].type, FormFieldType.text);
      expect(fields[2].type, FormFieldType.checkbox);
      expect(fields[3].type, FormFieldType.photo);
      expect(fields[5].type, FormFieldType.signature);
    });

    test('returns empty list when schema has no fields key', () {
      final schema = <String, dynamic>{};
      final fieldsJson = schema['fields'] as List? ?? [];
      final fields = fieldsJson.map((json) => FormField.fromJson(json)).toList();
      expect(fields, isEmpty);
    });

    test('returns empty list when fields is empty', () {
      final schema = {'fields': []};
      final fieldsJson = schema['fields'] as List? ?? [];
      final fields = fieldsJson.map((json) => FormField.fromJson(json)).toList();
      expect(fields, isEmpty);
    });
  });
}
