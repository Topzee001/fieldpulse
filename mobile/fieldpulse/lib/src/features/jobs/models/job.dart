import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'job_status.dart';

part 'job.g.dart';

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

Map<String, dynamic>? _parseChecklistSchema(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  // If it's a list (e.g. []), return an empty map or null to avoid crash
  return null;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Job extends Equatable {
  final int id;
  final String jobId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String customerAddress;
  
  @JsonKey(fromJson: _parseDouble)
  final double? latitude;
  
  @JsonKey(fromJson: _parseDouble)
  final double? longitude;
  final String? description;
  final String? notes;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final JobStatus status;
  
  @JsonKey(fromJson: _parseChecklistSchema)
  final Map<String, dynamic>? checklistSchema;
  final int version;
  final DateTime? actualStart;
  final DateTime? actualCompletion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Custom properties returned by the list endpoint
  final String? scheduledTime;
  final String? statusDisplay;
  final bool? isOverdue;

  const Job({
    required this.id,
    required this.jobId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.customerAddress,
    this.latitude,
    this.longitude,
    this.description,
    this.notes,
    required this.scheduledStart,
    this.scheduledEnd,
    required this.status,
    this.checklistSchema,
    required this.version,
    this.actualStart,
    this.actualCompletion,
    this.createdAt,
    this.updatedAt,
    this.scheduledTime,
    this.statusDisplay,
    this.isOverdue,
  });

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
  Map<String, dynamic> toJson() => _$JobToJson(this);

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      scheduledStart.year,
      scheduledStart.month,
      scheduledStart.day,
    );
    if (startDate == today) return 'Today ${_formatTime(scheduledStart)}';
    if (startDate == today.add(const Duration(days: 1)))
      return 'Tomorrow ${_formatTime(scheduledStart)}';
    return '${_formatDate(scheduledStart)} ${_formatTime(scheduledStart)}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  List<Object?> get props => [id, jobId, status, version];
}
