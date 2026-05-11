import 'package:flutter_test/flutter_test.dart';
import 'package:fieldpulse/src/features/jobs/models/job.dart';
import 'package:fieldpulse/src/features/jobs/models/job_status.dart';

void main() {
  group('Job.fromJson', () {
    final baseJson = {
      'id': 1,
      'job_id': 'JOB-2026-0001',
      'customer_name': 'John Smith',
      'customer_phone': '(555) 123-4567',
      'customer_email': 'john@example.com',
      'customer_address': '123 Main St, Springfield, NY 10001',
      'latitude': 40.7128,
      'longitude': -74.006,
      'description': 'HVAC Repair',
      'notes': 'Call before arriving',
      'scheduled_start': '2026-05-15T09:00:00Z',
      'scheduled_end': '2026-05-15T11:00:00Z',
      'status': 'pending',
      'checklist_schema': {
        'fields': [
          {'id': 'work', 'type': 'text', 'label': 'Work', 'required': true}
        ]
      },
      'version': 1,
      'actual_start': null,
      'actual_completion': null,
      'created_at': '2026-05-10T10:00:00Z',
      'updated_at': '2026-05-10T10:00:00Z',
    };

    test('parses a complete job JSON correctly', () {
      final job = Job.fromJson(baseJson);

      expect(job.id, 1);
      expect(job.jobId, 'JOB-2026-0001');
      expect(job.customerName, 'John Smith');
      expect(job.customerPhone, '(555) 123-4567');
      expect(job.customerEmail, 'john@example.com');
      expect(job.customerAddress, '123 Main St, Springfield, NY 10001');
      expect(job.latitude, 40.7128);
      expect(job.longitude, -74.006);
      expect(job.description, 'HVAC Repair');
      expect(job.notes, 'Call before arriving');
      expect(job.status, JobStatus.pending);
      expect(job.version, 1);
      expect(job.checklistSchema, isNotNull);
      expect(job.checklistSchema!['fields'], hasLength(1));
    });

    test('parses all status values correctly', () {
      for (final entry in {
        'pending': JobStatus.pending,
        'in_progress': JobStatus.inProgress,
        'completed': JobStatus.completed,
        'cancelled': JobStatus.cancelled,
      }.entries) {
        final json = Map<String, dynamic>.from(baseJson);
        json['status'] = entry.key;
        final job = Job.fromJson(json);
        expect(job.status, entry.value);
      }
    });

    test('handles null checklist_schema', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['checklist_schema'] = null;
      final job = Job.fromJson(json);
      expect(job.checklistSchema, isNull);
    });

    test('handles empty list checklist_schema gracefully', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['checklist_schema'] = [];
      final job = Job.fromJson(json);
      // _parseChecklistSchema returns null for non-Map types
      expect(job.checklistSchema, isNull);
    });

    test('handles empty map checklist_schema', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['checklist_schema'] = {};
      final job = Job.fromJson(json);
      expect(job.checklistSchema, isNotNull);
      expect(job.checklistSchema, isEmpty);
    });

    test('handles latitude/longitude as strings', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['latitude'] = '40.7128';
      json['longitude'] = '-74.006';
      final job = Job.fromJson(json);
      expect(job.latitude, 40.7128);
      expect(job.longitude, -74.006);
    });

    test('handles latitude/longitude as null', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['latitude'] = null;
      json['longitude'] = null;
      final job = Job.fromJson(json);
      expect(job.latitude, isNull);
      expect(job.longitude, isNull);
    });

    test('handles null optional fields', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['customer_phone'] = null;
      json['customer_email'] = null;
      json['description'] = null;
      json['notes'] = null;
      json['scheduled_end'] = null;
      final job = Job.fromJson(json);
      expect(job.customerPhone, isNull);
      expect(job.customerEmail, isNull);
      expect(job.description, isNull);
      expect(job.notes, isNull);
      expect(job.scheduledEnd, isNull);
    });

    test('parses list endpoint fields (scheduled_time, status_display, is_overdue)', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['scheduled_time'] = 'Today 09:00 AM';
      json['status_display'] = 'Pending';
      json['is_overdue'] = true;
      final job = Job.fromJson(json);
      expect(job.scheduledTime, 'Today 09:00 AM');
      expect(job.statusDisplay, 'Pending');
      expect(job.isOverdue, true);
    });
  });

  group('Job.toJson', () {
    test('round-trips correctly', () {
      final job = Job(
        id: 1,
        jobId: 'JOB-2026-0001',
        customerName: 'John Smith',
        customerAddress: '123 Main St',
        scheduledStart: DateTime(2026, 5, 15, 9, 0),
        status: JobStatus.pending,
        version: 1,
      );
      final json = job.toJson();
      expect(json['id'], 1);
      expect(json['job_id'], 'JOB-2026-0001');
      expect(json['customer_name'], 'John Smith');
      expect(json['status'], 'pending');
    });

    test('serializes in_progress status correctly', () {
      final job = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'Test',
        customerAddress: '123 St',
        scheduledStart: DateTime(2026, 1, 1),
        status: JobStatus.inProgress,
        version: 2,
      );
      expect(job.toJson()['status'], 'in_progress');
    });
  });

  group('Job.formattedTime', () {
    test('shows "Today" for today\'s job', () {
      final now = DateTime.now();
      final job = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'Test',
        customerAddress: '123 St',
        scheduledStart: DateTime(now.year, now.month, now.day, 14, 30),
        status: JobStatus.pending,
        version: 1,
      );
      expect(job.formattedTime, startsWith('Today'));
      expect(job.formattedTime, contains('14:30'));
    });

    test('shows "Tomorrow" for tomorrow\'s job', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final job = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'Test',
        customerAddress: '123 St',
        scheduledStart: DateTime(
            tomorrow.year, tomorrow.month, tomorrow.day, 9, 0),
        status: JobStatus.pending,
        version: 1,
      );
      expect(job.formattedTime, startsWith('Tomorrow'));
    });

    test('shows date for future job beyond tomorrow', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final job = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'Test',
        customerAddress: '123 St',
        scheduledStart: DateTime(
            future.year, future.month, future.day, 10, 0),
        status: JobStatus.pending,
        version: 1,
      );
      expect(job.formattedTime, isNot(startsWith('Today')));
      expect(job.formattedTime, isNot(startsWith('Tomorrow')));
    });
  });

  group('Job equality (Equatable)', () {
    test('two jobs with same id/jobId/status/version are equal', () {
      final a = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'A',
        customerAddress: '1 St',
        scheduledStart: DateTime(2026, 1, 1),
        status: JobStatus.pending,
        version: 1,
      );
      final b = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'B', // different name, but not in props
        customerAddress: '2 St',
        scheduledStart: DateTime(2026, 6, 1),
        status: JobStatus.pending,
        version: 1,
      );
      expect(a, equals(b));
    });

    test('two jobs with different version are not equal', () {
      final a = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'A',
        customerAddress: '1 St',
        scheduledStart: DateTime(2026, 1, 1),
        status: JobStatus.pending,
        version: 1,
      );
      final b = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'A',
        customerAddress: '1 St',
        scheduledStart: DateTime(2026, 1, 1),
        status: JobStatus.pending,
        version: 2,
      );
      expect(a, isNot(equals(b)));
    });

    test('two jobs with different status are not equal', () {
      final a = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'A',
        customerAddress: '1 St',
        scheduledStart: DateTime(2026, 1, 1),
        status: JobStatus.pending,
        version: 1,
      );
      final b = Job(
        id: 1,
        jobId: 'JOB-1',
        customerName: 'A',
        customerAddress: '1 St',
        scheduledStart: DateTime(2026, 1, 1),
        status: JobStatus.inProgress,
        version: 1,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
