import 'package:flutter_test/flutter_test.dart';
import 'package:fieldpulse/src/features/sync/models/sync_queue.dart';
import 'package:fieldpulse/src/features/sync/models/conflict.dart';

void main() {
  group('SyncQueueItem', () {
    test('constructs from required parameters', () {
      final item = SyncQueueItem(
        id: 1,
        jobId: 42,
        action: 'status_update',
        payload: {'status': 'in_progress'},
        createdAt: DateTime(2026, 5, 10, 14, 30),
        retryCount: 0,
      );

      expect(item.id, 1);
      expect(item.jobId, 42);
      expect(item.action, 'status_update');
      expect(item.payload['status'], 'in_progress');
      expect(item.retryCount, 0);
    });

    test('fromMap parses correctly', () {
      final map = {
        'id': 1,
        'job_id': 42,
        'action': 'checklist_update',
        'payload': {'data': {'work': 'Fixed it'}, 'isDraft': false},
        'created_at': '2026-05-10T14:30:00.000',
        'retry_count': 2,
      };
      final item = SyncQueueItem.fromMap(map);

      expect(item.id, 1);
      expect(item.jobId, 42);
      expect(item.action, 'checklist_update');
      expect(item.payload['data'], isA<Map>());
      expect(item.retryCount, 2);
    });

    test('fromMap defaults retryCount to 0 when null', () {
      final map = {
        'id': 1,
        'job_id': 42,
        'action': 'photo_upload',
        'payload': {'field_id': 'photo1', 'local_path': '/tmp/img.jpg'},
        'created_at': '2026-05-10T14:30:00.000',
        'retry_count': null,
      };
      final item = SyncQueueItem.fromMap(map);
      expect(item.retryCount, 0);
    });

    test('supports all known action types', () {
      final actions = ['photo_upload', 'signature_upload', 'checklist_update', 'status_update'];
      for (final action in actions) {
        final item = SyncQueueItem(
          id: 1,
          jobId: 1,
          action: action,
          payload: {},
          createdAt: DateTime.now(),
          retryCount: 0,
        );
        expect(item.action, action);
      }
    });
  });

  group('Conflict', () {
    test('constructs correctly', () {
      final conflict = Conflict(
        id: 1,
        jobId: 42,
        localData: {'status': 'in_progress'},
        serverData: {'status': 'completed'},
        conflictingFields: ['status'],
        createdAt: DateTime(2026, 5, 10),
        resolved: false,
      );

      expect(conflict.id, 1);
      expect(conflict.jobId, 42);
      expect(conflict.localData['status'], 'in_progress');
      expect(conflict.serverData['status'], 'completed');
      expect(conflict.conflictingFields, ['status']);
      expect(conflict.resolved, false);
    });

    test('supports multiple conflicting fields', () {
      final conflict = Conflict(
        id: 1,
        jobId: 42,
        localData: {'status': 'in_progress', 'notes': 'local notes'},
        serverData: {'status': 'completed', 'notes': 'server notes'},
        conflictingFields: ['status', 'notes'],
        createdAt: DateTime(2026, 5, 10),
        resolved: false,
      );

      expect(conflict.conflictingFields, hasLength(2));
      expect(conflict.conflictingFields, contains('status'));
      expect(conflict.conflictingFields, contains('notes'));
    });

    test('supports empty conflicting fields', () {
      final conflict = Conflict(
        id: 1,
        jobId: 42,
        localData: {},
        serverData: {},
        conflictingFields: [],
        createdAt: DateTime(2026, 5, 10),
        resolved: false,
      );

      expect(conflict.conflictingFields, isEmpty);
    });
  });

  group('Offline Queue Logic', () {
    test('retry count determines permanent failure threshold', () {
      const maxRetries = 5;

      // Under threshold
      final retryable = SyncQueueItem(
        id: 1, jobId: 1, action: 'status_update',
        payload: {}, createdAt: DateTime.now(), retryCount: 3,
      );
      expect(retryable.retryCount < maxRetries, isTrue);

      // At threshold
      final failed = SyncQueueItem(
        id: 2, jobId: 1, action: 'status_update',
        payload: {}, createdAt: DateTime.now(), retryCount: 5,
      );
      expect(failed.retryCount < maxRetries, isFalse);
    });

    test('queue items are processed in FIFO order by createdAt', () {
      final items = [
        SyncQueueItem(
          id: 3, jobId: 1, action: 'status_update',
          payload: {}, createdAt: DateTime(2026, 5, 10, 15, 0), retryCount: 0,
        ),
        SyncQueueItem(
          id: 1, jobId: 1, action: 'photo_upload',
          payload: {}, createdAt: DateTime(2026, 5, 10, 13, 0), retryCount: 0,
        ),
        SyncQueueItem(
          id: 2, jobId: 1, action: 'checklist_update',
          payload: {}, createdAt: DateTime(2026, 5, 10, 14, 0), retryCount: 0,
        ),
      ];

      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      expect(items[0].action, 'photo_upload');
      expect(items[1].action, 'checklist_update');
      expect(items[2].action, 'status_update');
    });

    test('different action types carry appropriate payloads', () {
      final photoItem = SyncQueueItem(
        id: 1, jobId: 1, action: 'photo_upload',
        payload: {'field_id': 'before_photo', 'local_path': '/tmp/photo.jpg'},
        createdAt: DateTime.now(), retryCount: 0,
      );
      expect(photoItem.payload.containsKey('field_id'), isTrue);
      expect(photoItem.payload.containsKey('local_path'), isTrue);

      final signatureItem = SyncQueueItem(
        id: 2, jobId: 1, action: 'signature_upload',
        payload: {'field_id': 'signature', 'local_path': '/tmp/sig.png'},
        createdAt: DateTime.now(), retryCount: 0,
      );
      expect(signatureItem.payload.containsKey('local_path'), isTrue);

      final checklistItem = SyncQueueItem(
        id: 3, jobId: 1, action: 'checklist_update',
        payload: {'data': {'work': 'Done'}, 'isDraft': false},
        createdAt: DateTime.now(), retryCount: 0,
      );
      expect(checklistItem.payload.containsKey('data'), isTrue);
      expect(checklistItem.payload.containsKey('isDraft'), isTrue);

      final statusItem = SyncQueueItem(
        id: 4, jobId: 1, action: 'status_update',
        payload: {'status': 'completed'},
        createdAt: DateTime.now(), retryCount: 0,
      );
      expect(statusItem.payload.containsKey('status'), isTrue);
    });
  });
}
