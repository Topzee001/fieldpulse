// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  fullName: json['full_name'] as String,
  biometricEnabled: json['biometric_enabled'] as bool,
  deviceId: json['device_id'] as String?,
  lastActive: DateTime.parse(json['last_active'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'full_name': instance.fullName,
  'biometric_enabled': instance.biometricEnabled,
  'device_id': instance.deviceId,
  'last_active': instance.lastActive.toIso8601String(),
};
