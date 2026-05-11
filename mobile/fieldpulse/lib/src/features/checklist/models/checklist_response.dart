class ChecklistResponse {
  final Map<String, dynamic> data;
  final bool isDraft;
  final DateTime? syncedAt;
  final DateTime lastModified;

  ChecklistResponse({
    required this.data,
    required this.isDraft,
    this.syncedAt,
    required this.lastModified,
  });

  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistResponse(
      data: json['data'] ?? {},
      isDraft: json['is_draft'] ?? true,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'])
          : null,
      lastModified: DateTime.parse(json['last_modified']),
    );
  }
}
