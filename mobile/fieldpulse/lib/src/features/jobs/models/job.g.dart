// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Job _$JobFromJson(Map<String, dynamic> json) => Job(
  id: (json['id'] as num).toInt(),
  jobId: json['job_id'] as String,
  customerName: json['customer_name'] as String,
  customerPhone: json['customer_phone'] as String?,
  customerEmail: json['customer_email'] as String?,
  customerAddress: json['customer_address'] as String,
  latitude: _parseDouble(json['latitude']),
  longitude: _parseDouble(json['longitude']),
  description: json['description'] as String?,
  notes: json['notes'] as String?,
  scheduledStart: DateTime.parse(json['scheduled_start'] as String),
  scheduledEnd: json['scheduled_end'] == null
      ? null
      : DateTime.parse(json['scheduled_end'] as String),
  status: $enumDecode(_$JobStatusEnumMap, json['status']),
  checklistSchema: _parseChecklistSchema(json['checklist_schema']),
  version: (json['version'] as num).toInt(),
  actualStart: json['actual_start'] == null
      ? null
      : DateTime.parse(json['actual_start'] as String),
  actualCompletion: json['actual_completion'] == null
      ? null
      : DateTime.parse(json['actual_completion'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  scheduledTime: json['scheduled_time'] as String?,
  statusDisplay: json['status_display'] as String?,
  isOverdue: json['is_overdue'] as bool?,
);

Map<String, dynamic> _$JobToJson(Job instance) => <String, dynamic>{
  'id': instance.id,
  'job_id': instance.jobId,
  'customer_name': instance.customerName,
  'customer_phone': instance.customerPhone,
  'customer_email': instance.customerEmail,
  'customer_address': instance.customerAddress,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'description': instance.description,
  'notes': instance.notes,
  'scheduled_start': instance.scheduledStart.toIso8601String(),
  'scheduled_end': instance.scheduledEnd?.toIso8601String(),
  'status': _$JobStatusEnumMap[instance.status]!,
  'checklist_schema': instance.checklistSchema,
  'version': instance.version,
  'actual_start': instance.actualStart?.toIso8601String(),
  'actual_completion': instance.actualCompletion?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'scheduled_time': instance.scheduledTime,
  'status_display': instance.statusDisplay,
  'is_overdue': instance.isOverdue,
};

const _$JobStatusEnumMap = {
  JobStatus.pending: 'pending',
  JobStatus.inProgress: 'in_progress',
  JobStatus.completed: 'completed',
  JobStatus.cancelled: 'cancelled',
};
