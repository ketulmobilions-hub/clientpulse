// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MilestoneImpl _$$MilestoneImplFromJson(Map<String, dynamic> json) =>
    _$MilestoneImpl(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      dueDate: json['due_date'] as String?,
      completed: json['completed'] as bool,
      completedAt: json['completed_at'] as String?,
      position: (json['position'] as num).toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$MilestoneImplToJson(_$MilestoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'title': instance.title,
      'due_date': instance.dueDate,
      'completed': instance.completed,
      'completed_at': instance.completedAt,
      'position': instance.position,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
