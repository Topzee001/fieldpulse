import 'package:flutter_test/flutter_test.dart';
import 'package:fieldpulse/src/features/checklist/providers/form_provider.dart';
import 'package:fieldpulse/src/features/checklist/models/checklist_response.dart';

void main() {
  group('ChecklistFormState', () {
    test('initial state has correct defaults', () {
      final state = ChecklistFormState.initial();
      expect(state.values, isEmpty);
      expect(state.errors, isEmpty);
      expect(state.isDraft, true);
      expect(state.isSaving, false);
      expect(state.isLoading, true);
    });

    test('copyWith preserves unchanged fields', () {
      final state = ChecklistFormState(
        values: {'key': 'value'},
        errors: {'key': 'error'},
        isDraft: false,
        isSaving: true,
        isLoading: false,
      );
      final updated = state.copyWith(isDraft: true);
      expect(updated.values, {'key': 'value'});
      expect(updated.errors, {'key': 'error'});
      expect(updated.isDraft, true);
      expect(updated.isSaving, true);
      expect(updated.isLoading, false);
    });

    test('copyWith can update values', () {
      final state = ChecklistFormState.initial();
      final updated = state.copyWith(values: {'work': 'Fixed the unit'});
      expect(updated.values['work'], 'Fixed the unit');
    });

    test('copyWith can update errors', () {
      final state = ChecklistFormState.initial();
      final updated = state.copyWith(errors: {'work': 'Required'});
      expect(updated.errors['work'], 'Required');
    });

    test('copyWith can clear all errors', () {
      final state = ChecklistFormState(
        values: {},
        errors: {'a': 'err1', 'b': 'err2'},
        isDraft: true,
        isSaving: false,
        isLoading: false,
      );
      final updated = state.copyWith(errors: {});
      expect(updated.errors, isEmpty);
    });
  });

  group('ChecklistResponse.fromJson', () {
    test('parses a complete response', () {
      final json = {
        'data': {'work_performed': 'Fixed AC', 'customer_satisfied': true},
        'is_draft': false,
        'synced_at': '2026-05-10T10:00:00Z',
        'last_modified': '2026-05-10T09:00:00Z',
      };
      final response = ChecklistResponse.fromJson(json);
      expect(response.data['work_performed'], 'Fixed AC');
      expect(response.data['customer_satisfied'], true);
      expect(response.isDraft, false);
      expect(response.syncedAt, isNotNull);
      expect(response.lastModified, DateTime.utc(2026, 5, 10, 9, 0, 0));
    });

    test('defaults data to empty map when null', () {
      final json = {
        'data': null,
        'is_draft': true,
        'last_modified': '2026-05-10T09:00:00Z',
      };
      final response = ChecklistResponse.fromJson(json);
      expect(response.data, isEmpty);
    });

    test('defaults isDraft to true when missing', () {
      final json = <String, dynamic>{
        'data': <String, dynamic>{},
        'last_modified': '2026-05-10T09:00:00Z',
      };
      final response = ChecklistResponse.fromJson(json);
      expect(response.isDraft, true);
    });

    test('handles null synced_at', () {
      final json = <String, dynamic>{
        'data': <String, dynamic>{},
        'is_draft': true,
        'synced_at': null,
        'last_modified': '2026-05-10T09:00:00Z',
      };
      final response = ChecklistResponse.fromJson(json);
      expect(response.syncedAt, isNull);
    });
  });
}
