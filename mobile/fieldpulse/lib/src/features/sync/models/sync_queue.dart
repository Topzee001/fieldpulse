class SyncQueueItem {
  final int id;
  final int jobId;
  final String action;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.jobId,
    required this.action,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
  });

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      jobId: map['job_id'],
      action: map['action'],
      payload: Map<String, dynamic>.from(map['payload']), 
      createdAt: DateTime.parse(map['created_at']),
      retryCount: map['retry_count'] ?? 0,
    );
  }
}