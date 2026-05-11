class Conflict {
  final int id;
  final int jobId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final List<String> conflictingFields;
  final DateTime createdAt;
  final bool resolved;

  Conflict({
    required this.id,
    required this.jobId,
    required this.localData,
    required this.serverData,
    required this.conflictingFields,
    required this.createdAt,
    required this.resolved,
  });
}